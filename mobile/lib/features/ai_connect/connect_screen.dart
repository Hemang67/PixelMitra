// ignore_for_file: deprecated_member_use
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/security/secure_key_store.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}
class _ConnectScreenState extends State<ConnectScreen> {
  final _store = SecureKeyStore();
  final _openAi = TextEditingController();
  final _gemini = TextEditingController();
  bool _busy = false;
  String _status = 'Your API usage is billed directly by each provider.';
  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 15)));
  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      if (_openAi.text.trim().isNotEmpty) await _store.saveOpenAi(_openAi.text);
      if (_gemini.text.trim().isNotEmpty) await _store.saveGemini(_gemini.text);
      _openAi.clear(); _gemini.clear();
      if (mounted) setState(() => _status = 'Keys saved in encrypted device storage.');
    } catch (_) { if (mounted) setState(() => _status = 'Could not save credentials.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _test(bool openAi) async {
    setState(() { _busy = true; _status = 'Testing provider…'; });
    try {
      final key = openAi ? (_openAi.text.trim().isNotEmpty ? _openAi.text.trim() : await _store.readOpenAi()) : (_gemini.text.trim().isNotEmpty ? _gemini.text.trim() : await _store.readGemini());
      if (key == null || key.isEmpty) throw StateError('Missing key');
      if (openAi) { await _dio.get('https://api.openai.com/v1/models', options: Options(headers: {'Authorization': 'Bearer $key'})); }
      else { await _dio.get('https://generativelanguage.googleapis.com/v1beta/models', queryParameters: {'key': key}); }
      if (mounted) setState(() => _status = 'Connection successful.');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (mounted) setState(() => _status = code == 401 || code == 403 ? 'Invalid key or permissions.' : code == 429 ? 'Provider quota or rate limit reached.' : 'Connection failed. Check network and provider billing.');
    } catch (_) { if (mounted) setState(() => _status = 'Enter an API key first.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _remove(bool openAi) async { if (openAi) { await _store.deleteOpenAi(); } else { await _store.deleteGemini(); } if (mounted) setState(() => _status = 'Saved key deleted from this device.'); }
  @override
  void dispose() { _openAi.dispose(); _gemini.dispose(); _dio.close(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Connect AI providers')), body: ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Bring your own key', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const Text('Requests go directly from your device to OpenAI or Google. PixelMitra has no API proxy or included credits.'),
    const SizedBox(height: 10),
    const Text('Before an AI media operation, review what image and prompt data will be sent. Provider charges may apply. Rooted or compromised devices can expose locally stored keys.'),
    const SizedBox(height: 22),
    TextField(controller: _openAi, obscureText: true, autocorrect: false, decoration: const InputDecoration(labelText: 'OpenAI API key', border: OutlineInputBorder())),
    Wrap(children: [TextButton(onPressed: _busy ? null : () => _test(true), child: const Text('Test OpenAI')), TextButton(onPressed: _busy ? null : () => _remove(true), child: const Text('Remove saved key'))]),
    const SizedBox(height: 18),
    TextField(controller: _gemini, obscureText: true, autocorrect: false, decoration: const InputDecoration(labelText: 'Gemini API key', border: OutlineInputBorder())),
    Wrap(children: [TextButton(onPressed: _busy ? null : () => _test(false), child: const Text('Test Gemini')), TextButton(onPressed: _busy ? null : () => _remove(false), child: const Text('Remove saved key'))]),
    const SizedBox(height: 20), FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'Please wait…' : 'Save keys securely')), const SizedBox(height: 12), Text(_status)
  ]));
}
