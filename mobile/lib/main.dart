// Flutter 3.50 currently deprecates the umbrella Material import during its
// Material UI package transition. Keep the stable Flutter Material API for now.
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'features/ai_connect/connect_screen.dart';
import 'features/photo_editor/photo_editor_screen.dart';
import 'features/updates/update_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PixelMitraApp());
}

class PixelMitraApp extends StatelessWidget {
  const PixelMitraApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PixelMitra',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFFFBFF),
    ),
    home: const HomeScreen(),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('PixelMitra ✨'),
      actions: [IconButton(
        tooltip: 'Check updates',
        icon: const Icon(Icons.system_update_alt),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateScreen())),
      )],
    ),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Your Creative Friend', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('Make something wonderful today.', style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 24),
      _FeatureCard(icon: Icons.photo_camera_back_outlined, title: 'Photo Editor', subtitle: 'Pick, rotate, adjust brightness and share offline.', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoEditorScreen()))),
      _FeatureCard(icon: Icons.auto_awesome, title: 'AI Connect', subtitle: 'Use your own OpenAI and Gemini API keys.', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectScreen()))),
      const _FeatureCard(icon: Icons.movie_outlined, title: 'Video Studio', subtitle: 'Video playback foundation is being added; export tools are next.', onTap: null),
      const SizedBox(height: 16),
      const Text('Your media stays on your device unless you explicitly choose to share it with an AI provider.', style: TextStyle(fontSize: 12)),
    ]),
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
