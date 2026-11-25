import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/security/secure_key_store.dart';

enum AiProviderId { openAi, gemini }

class AiOperationResult {
  const AiOperationResult({
    required this.provider,
    required this.model,
    required this.text,
  });

  final AiProviderId provider;
  final String model;
  final String text;
}

/// Direct-device BYOK AI operations. No PixelMitra proxy or local model is used.
class AiOperationService {
  AiOperationService({SecureKeyStore? keys, Dio? dio})
      : _keys = keys ?? SecureKeyStore(),
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 90),
              sendTimeout: const Duration(seconds: 60),
            ));

  final SecureKeyStore _keys;
  final Dio _dio;

  /// The caller must obtain explicit consent before sending the prompt.
  /// Requests are deliberately not retried: a timeout can occur after billing.
  Future<AiOperationResult> generateText({
    required String prompt,
    required AiProviderId provider,
    required bool consentGiven,
  }) async {
    _validateRequest(prompt, consentGiven);
    final key = await _readKey(provider);

    if (provider == AiProviderId.openAi) {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.openai.com/v1/responses',
        options: Options(headers: {'Authorization': 'Bearer $key'}),
        data: {'model': 'gpt-4.1-mini', 'input': prompt.trim()},
      );
      final data = response.data ?? const <String, dynamic>{};
      final output = data['output'];
      final texts = <String>[];
      if (output is List) {
        for (final item in output) {
          if (item is! Map || item['content'] is! List) continue;
          for (final part in item['content'] as List) {
            if (part is Map &&
                part['type'] == 'output_text' &&
                part['text'] is String) {
              texts.add(part['text'] as String);
            }
          }
        }
      }
      return AiOperationResult(
        provider: provider,
        model: data['model'] as String? ?? 'gpt-4.1-mini',
        text: texts.join('\n').trim(),
      );
    }

    final response = await _dio.post<Map<String, dynamic>>(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
      queryParameters: {'key': key},
      data: {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt.trim()}
            ]
          }
        ]
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final candidates = data['candidates'];
    final texts = <String>[];
    if (candidates is List) {
      for (final candidate in candidates) {
        if (candidate is! Map) continue;
        final content = candidate['content'];
        if (content is! Map || content['parts'] is! List) continue;
        for (final part in content['parts'] as List) {
          if (part is Map && part['text'] is String) {
            texts.add(part['text'] as String);
          }
        }
      }
    }
    return AiOperationResult(
      provider: provider,
      model: 'gemini-2.5-flash',
      text: texts.join('\n').trim(),
    );
  }

  /// Generates an image and writes its bytes to the app cache directory.
  /// The image and prompt are sent directly to the selected provider.
  Future<File> generateImage({
    required String prompt,
    required AiProviderId provider,
    required bool consentGiven,
  }) async {
    _validateRequest(prompt, consentGiven);
    final key = await _readKey(provider);
    final bytes = provider == AiProviderId.openAi
        ? await _generateOpenAiImage(key, prompt.trim())
        : await _generateGeminiImage(key, prompt.trim());

    if (bytes.isEmpty) {
      throw const FormatException('The provider returned an empty image.');
    }
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/pixelmitra-${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<List<int>> _generateOpenAiImage(String key, String prompt) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'https://api.openai.com/v1/images/generations',
      options: Options(headers: {'Authorization': 'Bearer $key'}),
      data: {
        'model': 'gpt-image-1',
        'prompt': prompt,
        'size': '1024x1024',
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final items = data['data'];
    if (items is! List || items.isEmpty || items.first is! Map) {
      throw const FormatException('OpenAI returned no image data.');
    }
    final encoded = (items.first as Map)['b64_json'];
    if (encoded is! String || encoded.isEmpty) {
      throw const FormatException('OpenAI image response did not contain base64 data.');
    }
    return base64Decode(encoded);
  }

  Future<List<int>> _generateGeminiImage(String key, String prompt) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent',
      queryParameters: {'key': key},
      data: {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE']
        }
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final candidates = data['candidates'];
    if (candidates is List) {
      for (final candidate in candidates) {
        if (candidate is! Map) continue;
        final content = candidate['content'];
        if (content is! Map || content['parts'] is! List) continue;
        for (final part in content['parts'] as List) {
          if (part is! Map) continue;
          final inlineData = part['inlineData'];
          if (inlineData is Map && inlineData['data'] is String) {
            return base64Decode(inlineData['data'] as String);
          }
        }
      }
    }
    throw const FormatException('Gemini returned no image data.');
  }

  Future<String> _readKey(AiProviderId provider) async {
    final key = provider == AiProviderId.openAi
        ? await _keys.readOpenAi()
        : await _keys.readGemini();
    if (key == null || key.trim().isEmpty) {
      throw StateError('Connect the selected provider before using AI.');
    }
    return key.trim();
  }

  void _validateRequest(String prompt, bool consentGiven) {
    if (!consentGiven) {
      throw StateError('Explicit provider consent is required.');
    }
    if (prompt.trim().isEmpty) {
      throw ArgumentError('Prompt cannot be empty.');
    }
  }
}
