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
    setState(() { _loading = true; _message = null; });
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      final path = result?.files.single.path;
      if (path == null) return;
      final next = VideoPlayerController.file(File(path));
      await next.initialize();
      await _controller?.dispose();
      if (!mounted) { await next.dispose(); return; }
      setState(() { _controller = next; _start = 0; _end = 1; });
    } catch (_) {
      if (mounted) setState(() => _message = 'Unable to open this video.');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _previewTrim() async {
    final controller = _controller;
    if (controller == null) return;
    final duration = controller.value.duration;
    await controller.seekTo(Duration(milliseconds: (duration.inMilliseconds * _start).round()));
    await controller.play();
  }

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller?.value.isInitialized ?? false;
    final duration = ready ? controller!.value.duration : Duration.zero;
    return Scaffold(
      appBar: AppBar(title: const Text('Video Studio')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Offline video preview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Open a local video and choose a trim range. No video is uploaded.'),
        const SizedBox(height: 16),
        if (ready)
          AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller))
        else
          const SizedBox(height: 220, child: Center(child: Icon(Icons.movie_outlined, size: 70))),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _loading ? null : _choose,
          icon: const Icon(Icons.video_library), label: Text(_loading ? 'Opening…' : 'Choose video')),
        if (ready) ...[
          const SizedBox(height: 16),
          Text('Duration: ${duration.inSeconds} seconds'),
          RangeSlider(
            values: RangeValues(_start, _end),
            min: 0, max: 1,
            labels: RangeLabels(
              '${(_start * duration.inSeconds).round()}s',
              '${(_end * duration.inSeconds).round()}s'),
            onChanged: (values) => setState(() { _start = values.start; _end = values.end; }),
          ),
          OutlinedButton.icon(onPressed: _previewTrim,
            icon: const Icon(Icons.play_arrow), label: const Text('Preview from trim start')),
          OutlinedButton.icon(onPressed: () async {
            if (controller.value.isPlaying) { await controller.pause(); }
            else { await controller.play(); }
            if (mounted) setState(() {});
          }, icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
            label: Text(controller.value.isPlaying ? 'Pause' : 'Play')),
          const SizedBox(height: 16),
          const Text('Trim selection is a preview only. Native video trim/merge/export is not implemented yet.'),
        ],
        if (_message != null) Text(_message!),
      ]),
    );
  }
}
