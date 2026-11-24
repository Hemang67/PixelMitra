// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PhotoEditorScreen extends StatefulWidget {
  const PhotoEditorScreen({super.key});
  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  final _picker = ImagePicker();
  File? _file;
  int _turns = 0;
  double _brightness = 1;
  double _contrast = 1;
  double _saturation = 1;
  bool _busy = false;
  String? _status;

  Future<void> _pick() async {
    final p = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (p == null || !mounted) return;
    setState(() { _file = File(p.path); _turns = 0; _brightness = 1; _contrast = 1; _saturation = 1; _status = null; });
  }

  Future<void> _export() async {
    if (_file == null || _busy) return;
    setState(() => _busy = true);
    try {
      final decoded = img.decodeImage(await _file!.readAsBytes());
      if (decoded == null) throw const FormatException('Unsupported image');
      var output = img.copyRotate(decoded, angle: _turns * 90);
      output = img.adjustColor(output, brightness: _brightness, contrast: _contrast, saturation: _saturation);
      final dir = await getTemporaryDirectory();
      final out = File('${dir.path}/pixelmitra_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await out.writeAsBytes(img.encodeJpg(output, quality: 92), flush: true);
      await Share.shareXFiles([XFile(out.path)], text: 'Edited with PixelMitra');
      if (mounted) setState(() => _status = 'JPEG export created and ready to share.');
    } catch (_) {
      if (mounted) setState(() => _status = 'Could not process this photo. Try another image.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Photo Editor')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(height: 300, alignment: Alignment.center,
        child: _file == null ? const Text('Choose a photo to start')
          : RotatedBox(quarterTurns: _turns, child: Image.file(_file!, fit: BoxFit.contain))),
      OutlinedButton.icon(onPressed: _busy ? null : _pick, icon: const Icon(Icons.photo_library), label: const Text('Choose photo')),
      OutlinedButton.icon(onPressed: _file == null || _busy ? null : () => setState(() => _turns = (_turns + 1) % 4), icon: const Icon(Icons.rotate_right), label: const Text('Rotate 90°')),
      if (_file != null) ...[
        _adjustment('Brightness', _brightness, (v) => setState(() => _brightness = v)),
        _adjustment('Contrast', _contrast, (v) => setState(() => _contrast = v)),
        _adjustment('Saturation', _saturation, (v) => setState(() => _saturation = v)),
        TextButton(onPressed: () => setState(() { _brightness = 1; _contrast = 1; _saturation = 1; _turns = 0; }), child: const Text('Reset adjustments')),
      ],
      FilledButton.icon(onPressed: _file == null || _busy ? null : _export, icon: const Icon(Icons.ios_share), label: Text(_busy ? 'Processing…' : 'Export and share')),
      if (_status != null) Text(_status!),
      const Text('All adjustments are processed locally. No AI service receives this photo.'),
    ]),
  );

  Widget _adjustment(String label, double value, ValueChanged<double> onChanged) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label: ${value.toStringAsFixed(2)}'),
      Slider(value: value, min: 0, max: 2, divisions: 40, onChanged: _busy ? null : onChanged),
    ]);
}
