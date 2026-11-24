// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'ai_operation_service.dart';

class AiStudioScreen extends StatefulWidget {
  const AiStudioScreen({super.key});
  @override
  State<AiStudioScreen> createState() => _AiStudioScreenState();
}

class _AiStudioScreenState extends State<AiStudioScreen> {
  final _prompt = TextEditingController();
  final _service = AiOperationService();
  AiProviderId _provider = AiProviderId.openAi;
  bool _busy = false;
  String _result = '';
  File? _image;

  Future<bool> _consent(String operation) async {
    final name = _provider == AiProviderId.openAi ? 'OpenAI' : 'Google Gemini';
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm external AI request'),
        content: Text('Your prompt will be sent directly to $name for $operation. '
            'Your provider account may incur charges. No automatic retry or provider fallback will occur. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    ) == true;
  }

  Future<void> _generateText() async {
    if (_prompt.text.trim().isEmpty) return;
    if (!await _consent('text generation') || !mounted) return;
    setState(() { _busy = true; _result = ''; _image = null; });
    try {
      final response = await _service.generateText(prompt: _prompt.text, provider: _provider, consentGiven: true);
      if (mounted) setState(() => _result = response.text.isEmpty ? 'Provider returned no text.' : response.text);
    } catch (_) {
      if (mounted) setState(() => _result = 'Request failed. Check the provider key, permissions, quota and network. The request was not retried.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _generateImage() async {
    if (_prompt.text.trim().isEmpty) return;
    if (!await _consent('image generation') || !mounted) return;
    setState(() { _busy = true; _result = ''; _image = null; });
    try {
      final file = await _service.generateImage(prompt: _prompt.text, provider: _provider, consentGiven: true);
      if (mounted) setState(() { _image = file; _result = 'Generated image saved temporarily on this device.'; });
    } catch (_) {
      if (mounted) setState(() => _result = 'Image generation failed. Check model availability, API access, billing and quota.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _shareImage() async {
    final image = _image;
    if (image != null) await Share.shareXFiles([XFile(image.path)], text: 'Created with PixelMitra');
  }

  @override
  void dispose() { _prompt.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI Studio')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Create with your own AI', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Requests are sent directly to your selected provider. Provider availability and charges depend on your account.'),
      const SizedBox(height: 16),
      DropdownButtonFormField<AiProviderId>(
        initialValue: _provider,
        decoration: const InputDecoration(labelText: 'AI provider', border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: AiProviderId.openAi, child: Text('OpenAI')),
          DropdownMenuItem(value: AiProviderId.gemini, child: Text('Google Gemini')),
        ],
        onChanged: _busy ? null : (value) { if (value != null) setState(() => _provider = value); },
      ),
      const SizedBox(height: 16),
      TextField(controller: _prompt, minLines: 3, maxLines: 7, decoration: const InputDecoration(labelText: 'Describe your idea', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _busy ? null : _generateText, icon: const Icon(Icons.text_fields), label: const Text('Generate text')),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: _busy ? null : _generateImage, icon: const Icon(Icons.image), label: const Text('Generate image')),
      if (_busy) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
      if (_image != null) ...[
        const SizedBox(height: 16), Image.file(_image!, fit: BoxFit.contain),
        OutlinedButton.icon(onPressed: _shareImage, icon: const Icon(Icons.share), label: const Text('Share image')),
      ],
      if (_result.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 16), child: SelectableText(_result)),
      const SizedBox(height: 16),
      const Text('Image editing, background removal, segmentation and upscaling are not enabled yet.'),
    ]),
  );
}
