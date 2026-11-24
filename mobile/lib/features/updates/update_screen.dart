// ignore_for_file: deprecated_member_use
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateScreen extends StatefulWidget { const UpdateScreen({super.key}); @override State<UpdateScreen> createState() => _UpdateScreenState(); }
class _UpdateScreenState extends State<UpdateScreen> {
  bool _busy = false; String _status = 'Check GitHub for the latest stable release.'; String? _page; String? _apk; String? _notes;
  Future<void> _check() async {
    setState(() { _busy = true; _status = 'Checking GitHub Releases…'; });
    try {
      final r = await Dio().get('https://api.github.com/repos/Hemang67/PixelMitra/releases/latest', options: Options(headers: {'Accept': 'application/vnd.github+json'}));
      final d = r.data as Map<String, dynamic>; if (d['draft'] == true || d['prerelease'] == true) throw StateError('Not stable');
      final assets = (d['assets'] as List? ?? const []).cast<Map<String, dynamic>>(); final matches = assets.where((a) => (a['name'] as String? ?? '').toLowerCase().endsWith('.apk'));
      setState(() { _page = d['html_url'] as String?; _apk = matches.isEmpty ? null : matches.first['browser_download_url'] as String?; _notes = d['body'] as String? ?? ''; _status = 'Latest stable: ${d['tag_name'] ?? 'release'}'; });
    } on DioException catch (e) { setState(() => _status = e.response?.statusCode == 404 ? 'No stable release published yet.' : 'Unable to reach GitHub.'); }
    catch (_) { setState(() => _status = 'No stable release available.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _open() async { final value = _apk ?? _page; if (value != null) await launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('App updates')), body: ListView(padding: const EdgeInsets.all(20), children: [
    const Icon(Icons.system_update_alt, size: 56), Text(_status), FilledButton(onPressed: _busy ? null : _check, child: Text(_busy ? 'Checking…' : 'Check releases')),
    if (_notes != null) ...[const Text('Release notes', style: TextStyle(fontWeight: FontWeight.bold)), SelectableText(_notes!), OutlinedButton(onPressed: _open, child: Text(_apk == null ? 'Open release page' : 'Open APK download'))],
    const Text('This version opens the official GitHub page. Automatic installation and APK signature verification are not implemented yet.')
  ]));
}
