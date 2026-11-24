// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
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

  Future<void> _submit() async {
    if (_prompt.text.trim().isEmpty) return;
    final name = _provider == AiProviderId.openAi ? 'OpenAI' : 'Google Gemini';
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm external AI request'),
        content: Text('Your prompt will be sent directly to $name for processing. '
            'Your own provider account may incur charges. No automatic retries or '
            'fallback to another provider will occur. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send prompt')),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() { _busy = true; _result = 'Waiting for provider response…'; });
    try {
      final response = await _service.generateText(
        prompt: _prompt.text, provider: _provider, consentGiven: true);
      if (mounted) setState(() => _result = response.text.isEmpty
          ? 'Provider returned no text.' : response.text);
    } catch (_) {
      if (mounted) setState(() => _result =
          'Request failed. Check the provider key, billing, network and quota. '
          'The request was not retried because a timeout can still be billable.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() { _prompt.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI Studio')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Prompt assistant', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Generate creative ideas and editing prompts with your own API key. '
          'Image generation and image editing are not yet available in this screen.'),
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
      TextField(
        controller: _prompt,
        minLines: 3, maxLines: 7,
        decoration: const InputDecoration(
          labelText: 'Describe your creative idea',
          hintText: 'Suggest a cinematic portrait editing prompt…',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _busy ? null : _submit,
        icon: const Icon(Icons.auto_awesome),
        label: Text(_busy ? 'Generating…' : 'Generate with my API key'),
      ),
      const SizedBox(height: 20),
      if (_result.isNotEmpty) SelectableText(_result),
    ]),
  );
}
