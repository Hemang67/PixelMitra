// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_trimmer/video_trimmer.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  final Trimmer _trimmer = Trimmer();
  String? _videoPath;
  String? _exportedPath;
  String? _message;
  double _startValue = 0;
  double _endValue = 0;
  bool _loading = false;
  bool _saving = false;
  bool _isPlaying = false;

  Future<void> _choose() async {
    if (_loading || _saving) return;
    setState(() {
      _loading = true;
      _message = null;
      _exportedPath = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      final path = result?.files.single.path;
      if (path == null) return;

      await _trimmer.loadVideo(videoPath: path);
      if (!mounted) return;
      setState(() {
        _videoPath = path;
        _startValue = 0;
        _endValue = 0;
        _isPlaying = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _message =
            'Unable to open this video. Try a supported MP4 or MOV file.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_videoPath == null || _saving) return;
    final playing = await _trimmer.videoPlaybackControl(
      startValue: _startValue,
      endValue: _endValue,
    );
    if (mounted) setState(() => _isPlaying = playing);
  }

  Future<void> _export() async {
    if (_videoPath == null || _saving) return;
    final file = File(_videoPath!);
    if (!await file.exists()) {
      setState(() => _message = 'The selected video is no longer available.');
      return;
    }

    setState(() {
      _saving = true;
      _message = 'Exporting selected video…';
      _exportedPath = null;
    });

    try {
      await _trimmer.saveTrimmedVideo(
        startValue: _startValue,
        endValue: _endValue,
        storageDir: StorageDir.applicationDocumentsDirectory,
        videoFolderName: 'PixelMitra',
        onSave: (outputPath) {
          if (!mounted) return;
          setState(() {
            _saving = false;
            _exportedPath = outputPath;
            _message = outputPath == null
                ? 'Export failed. Please try another video or selection.'
                : 'Your trimmed video has been saved on this device.';
          });
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = 'Export failed. Please try another video or selection.';
        });
      }
    }
  }

  Future<void> _shareExport() async {
    final path = _exportedPath;
    if (path == null || !await File(path).exists()) return;
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Trimmed with PixelMitra',
    );
  }

  String _formatMs(double milliseconds) {
    final duration = Duration(milliseconds: milliseconds.round());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = _videoPath != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Studio'),
        actions: [
          if (_exportedPath != null)
            IconButton(
              tooltip: 'Share exported video',
              onPressed: _shareExport,
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Trim your video',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a video, adjust the trim handles, preview your selection '
            'and export a separate trimmed copy. Your original video stays unchanged.',
          ),
          const SizedBox(height: 18),
          if (hasVideo)
            Container(
              constraints: const BoxConstraints(minHeight: 220, maxHeight: 360),
              color: Colors.black,
              alignment: Alignment.center,
              child: VideoViewer(trimmer: _trimmer),
            )
          else
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.movie_outlined, size: 72),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading || _saving ? null : _choose,
            icon: const Icon(Icons.video_library_outlined),
            label: Text(_loading ? 'Opening video…' : 'Choose video'),
          ),
          if (hasVideo) ...[
            const SizedBox(height: 20),
            const Text(
              'Select the section to keep',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TrimViewer(
              trimmer: _trimmer,
              viewerHeight: 64,
              viewerWidth: MediaQuery.of(context).size.width - 40,
              onChangeStart: (value) => _startValue = value,
              onChangeEnd: (value) => _endValue = value,
              onChangePlaybackState: (playing) {
                if (mounted) setState(() => _isPlaying = playing);
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start  ${_formatMs(_startValue)}'),
                Text('End  ${_formatMs(_endValue)}'),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _togglePlayback,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(_isPlaying ? 'Pause preview' : 'Preview selection'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _export,
              icon: const Icon(Icons.save_alt),
              label: Text(_saving ? 'Exporting…' : 'Export trimmed video'),
            ),
            if (_saving) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_exportedPath != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _shareExport,
                icon: const Icon(Icons.share),
                label: const Text('Share trimmed video'),
              ),
            ],
          ],
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(
              _message!,
              style: TextStyle(
                color: _exportedPath != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Processing is performed locally on your device. PixelMitra does '
            'not upload your video to an AI provider for trimming.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
