import 'package:dio/dio.dart';
import '../../core/security/secure_key_store.dart';

enum AiProviderId { openAi, gemini }

class AiOperationResult {
  const AiOperationResult({required this.provider, required this.model, required this.text});
  final AiProviderId provider;
  final String model;
  final String text;
}

/// Direct-device, BYOK text prompting. No local AI models or proxy server.
class AiOperationService {
  AiOperationService({SecureKeyStore? keys, Dio? dio})
      : _keys = keys ?? SecureKeyStore(),
        _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
        ));

  final SecureKeyStore _keys;
  final Dio _dio;

  /// Caller must display provider, data-sharing and billing disclosure first.
  /// A potentially billable request is never retried automatically.
  Future<AiOperationResult> generateText({
    required String prompt,
    required AiProviderId provider,
    required bool consentGiven,
  }) async {
    if (!consentGiven) throw StateError('Explicit provider consent is required.');
    if (prompt.trim().isEmpty) throw ArgumentError('Prompt cannot be empty.');
    final key = provider == AiProviderId.openAi
        ? await _keys.readOpenAi()
        : await _keys.readGemini();
    if (key == null || key.isEmpty) {
      throw StateError('Connect the selected provider before using AI.');
    }
    if (provider == AiProviderId.openAi) {
      final response = await _dio.post(
        'https://api.openai.com/v1/responses',
        options: Options(headers: {'Authorization': 'Bearer $key'}),
        data: {'model': 'gpt-4.1-mini', 'input': prompt.trim()},
      );
      final data = response.data as Map<String, dynamic>;
      final output = data['output'] as List<dynamic>? ?? const [];
      final texts = <String>[];
      for (final item in output) {
        if (item is! Map) continue;
        final parts = item['content'];
        if (parts is! List) continue;
        for (final part in parts) {
          if (part is Map && part['type'] == 'output_text' && part['text'] is String) {
            texts.add(part['text'] as String);
          }
        }
      }
      return AiOperationResult(
        provider: provider,
        model: data['model'] as String? ?? 'gpt-4.1-mini',
        text: texts.join('\n'),
      );
    }
    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
      queryParameters: {'key': key},
      data: {
        'contents': [
          {'parts': [{'text': prompt.trim()}]}
        ]
      },
    );
    final data = response.data as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>? ?? const [];
    final texts = <String>[];
    for (final candidate in candidates) {
      if (candidate is! Map) continue;
      final content = candidate['content'];
      if (content is! Map) continue;
      final parts = content['parts'];
      if (parts is! List) continue;
      for (final part in parts) {
        if (part is Map && part['text'] is String) texts.add(part['text'] as String);
      }
    }
    return AiOperationResult(
      provider: provider,
      model: 'gemini-2.5-flash',
      text: texts.join('\n'),
    );
  }
}
