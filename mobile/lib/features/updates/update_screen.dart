// ignore_for_file: deprecated_member_use
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Accept': 'application/vnd.github+json'},
  ));

  bool _busy = false;
  String _status = 'Check GitHub for the latest stable PixelMitra release.';
  String? _installedVersion;
  String? _latestVersion;
  String? _releasePage;
  String? _apkUrl;
  String? _releaseNotes;
  bool? _updateAvailable;

  List<int> _versionParts(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final core = normalized.split(RegExp(r'[-+]')).first;
    return core.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  }

  int _compareVersions(String left, String right) {
    final a = _versionParts(left);
    final b = _versionParts(right);
    final length = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }

  Future<void> _check() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Checking GitHub Releases…';
    });
    try {
      final info = await PackageInfo.fromPlatform();
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/Hemang67/PixelMitra/releases/latest',
      );
      final release = response.data;
      if (release == null ||
          release['draft'] == true ||
          release['prerelease'] == true) {
        throw StateError('No stable release is available.');
      }

      final tag = release['tag_name'] as String? ?? '';
      if (tag.isEmpty) throw const FormatException('Release tag is missing.');
      final assets = release['assets'];
      String? apk;
      if (assets is List) {
        for (final asset in assets) {
          if (asset is Map &&
              (asset['name'] as String? ?? '').toLowerCase().endsWith('.apk')) {
            apk = asset['browser_download_url'] as String?;
            if (apk != null) break;
          }
        }
      }

      final hasUpdate = _compareVersions(tag, info.version) > 0;
      if (!mounted) return;
      setState(() {
        _installedVersion = info.version;
        _latestVersion = tag;
        _releasePage = release['html_url'] as String?;
        _apkUrl = apk;
        _releaseNotes = release['body'] as String? ?? '';
        _updateAvailable = hasUpdate;
        _status = hasUpdate
            ? 'A newer version is available.'
            : _compareVersions(tag, info.version) == 0
                ? 'You are using the latest version.'
                : 'Your installed version is newer than the latest stable release.';
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final code = error.response?.statusCode;
      setState(() => _status = code == 404
          ? 'No stable release has been published yet.'
          : 'Could not contact GitHub. Check your internet connection and try again.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = error is FormatException
          ? 'GitHub returned release information in an unexpected format.'
          : 'No stable release is currently available.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRelease() async {
    final target = _updateAvailable == true ? (_apkUrl ?? _releasePage) : _releasePage;
    if (target == null) return;
    final uri = Uri.tryParse(target);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App updates')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.system_update_alt, size: 56),
          const SizedBox(height: 12),
          Text(_status, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (_installedVersion != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Installed version'),
              trailing: Text(_installedVersion!),
            ),
          if (_latestVersion != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Latest stable version'),
              trailing: Text(_latestVersion!),
            ),
          FilledButton(
            onPressed: _busy ? null : _check,
            child: Text(_busy ? 'Checking…' : 'Check for updates'),
          ),
          if (_updateAvailable == true) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openRelease,
              icon: const Icon(Icons.download),
              label: Text(_apkUrl == null
                  ? 'Open release page'
                  : 'Download update APK'),
            ),
            if (_apkUrl == null)
              const Text('This release does not contain an APK asset yet.'),
          ] else if (_releasePage != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _openRelease,
              child: const Text('View GitHub release'),
            ),
          ],
          if (_releaseNotes != null && _releaseNotes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Release notes',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(_releaseNotes!),
          ],
          const SizedBox(height: 20),
          const Text(
            'APK downloads open through GitHub in your browser. Android installation '
            'requires your approval. Automatic in-app installation and APK '
            'signature/checksum verification are not part of this checker yet.',
          ),
        ],
      ),
    );
  }
}
