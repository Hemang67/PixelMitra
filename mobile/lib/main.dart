import 'package:flutter/material.dart';

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
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('PixelMitra ✨')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            Text('Your Creative Friend',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Create, edit and celebrate with PixelMitra.'),
            SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.photo_library_outlined),
              title: Text('Photo Editor'),
              subtitle: Text('Crop, adjust, filter and export offline.'),
            ),
            ListTile(
              leading: Icon(Icons.auto_awesome),
              title: Text('AI Studio'),
              subtitle: Text('Connect your own OpenAI or Gemini API key.'),
            ),
            ListTile(
              leading: Icon(Icons.movie_outlined),
              title: Text('Video Editor'),
              subtitle: Text('Basic editing designed for offline use.'),
            ),
          ],
        ),
      );
}
