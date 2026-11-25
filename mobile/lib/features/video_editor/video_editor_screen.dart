// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  VideoPlayerController? _controller;
  bool _loading = false;
  String? _message;
  double _start = 0;
  double _end = 1;

  Future<void> _choose() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    VideoPlayerController? next;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      final path = result?.files.single.path;
      if (path == null) return;

      next = VideoPlayerController.file(File(path));
      await next.initialize();
      await next.setLooping(false);
      final previous = _controller;
      if (!mounted) {
        await next.dispose();
        return;
      }
      setState(() {
        _controller = next;
        _start = 0;
        _end = 1;
      });
      await previous?.dispose();
    } catch (_) {
      await next?.dispose();
      if (mounted) {
        setState(() => _message =
            'Unable to open this video. Try a supported MP4 or MOV file.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _previewTrim() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration;
    final start = Duration(
      milliseconds: (duration.inMilliseconds * _start).round(),
    );
    await controller.pause();
    await controller.seekTo(start);
    await controller.play();
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${value.inHours > 0 ? '${value.inHours}:' : ''}$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final duration = ready ? controller.value.duration : Duration.zero;
    final position = ready ? controller.value.position : Duration.zero;

    return Scaffold(
      appBar: AppBar(title: const Text('Video Studio')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Offline video preview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a video stored on your device. Preview and select a section '
            'without uploading the original file.',
          ),
          const SizedBox(height: 16),
          if (ready)
            AspectRatio(
              aspectRatio: controller.value.aspectRatio > 0
                  ? controller.value.aspectRatio
                  : 16 / 9,
              child: VideoPlayer(controller),
            )
          else
            const SizedBox(
              height: 220,
              child: Center(child: Icon(Icons.movie_outlined, size: 70)),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _choose,
            icon: const Icon(Icons.video_library),
            label: Text(_loading ? 'Opening…' : 'Choose video'),
          ),
          if (ready) ...[
            const SizedBox(height: 12),
            Text('Playback: ${_format(position)} / ${_format(duration)}'),
            VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _togglePlayback,
                    icon: Icon(controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow),
                    label: Text(
                        controller.value.isPlaying ? 'Pause' : 'Play'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previewTrim,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Preview selection'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Selected section: ${_format(Duration(milliseconds: (duration.inMilliseconds * _start).round()))}'
              ' – ${_format(Duration(milliseconds: (duration.inMilliseconds * _end).round()))}',
            ),
            RangeSlider(
              values: RangeValues(_start, _end),
              min: 0,
              max: 1,
              divisions: 100,
              onChanged: (values) {
                setState(() {
                  _start = values.start;
                  _end = values.end;
                });
              },
            ),
            const Text(
              'The selected range can be previewed. Exporting/trimming the '
              'video file is a separate feature and is not included in this preview workflow.',
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            )),
          ],
        ],
      ),
    );
  }
}
