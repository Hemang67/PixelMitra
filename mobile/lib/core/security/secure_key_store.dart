import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores BYOK credentials in platform-backed encrypted storage.
class SecureKeyStore {
  SecureKeyStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _openAi = 'pixelmitra.openai.key';
  static const _gemini = 'pixelmitra.gemini.key';
  Future<void> saveOpenAi(String key) => _save(_openAi, key);
  Future<void> saveGemini(String key) => _save(_gemini, key);
  Future<String?> readOpenAi() => _storage.read(key: _openAi);
  Future<String?> readGemini() => _storage.read(key: _gemini);
  Future<void> deleteOpenAi() => _storage.delete(key: _openAi);
  Future<void> deleteGemini() => _storage.delete(key: _gemini);
  Future<void> _save(String name, String key) async {
    if (key.trim().isEmpty) throw ArgumentError('API key cannot be empty');
    await _storage.write(key: name, value: key.trim());
  }
}
