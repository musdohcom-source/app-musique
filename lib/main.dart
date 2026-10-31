import 'package:flutter/material.dart';

void main() {
  runApp(const Mp3ConverterApp());
}

class Mp3ConverterApp extends StatelessWidget {
  const Mp3ConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dustomuet MP3 Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const ConverterHomePage(),
    );
  }
}

class ConverterHomePage extends StatefulWidget {
  const ConverterHomePage({super.key});

  @override
  State<ConverterHomePage> createState() => _ConverterHomePageState();
}

class _ConverterHomePageState extends State<ConverterHomePage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';

  void _startDownload() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un lien valide !')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Connexion au serveur...';
    });

    // Simulation d'une étape de téléchargement/conversion réaliste
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _statusMessage = 'Conversion en cours (MP3 320kbps)...';
      });
    });

    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
        _urlController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Succès ! Fichier enregistré dans les Téléchargements.'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convertisseur MP3'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1DB954),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.audiotrack, size: 90, color: Color(0xFF1DB954)),
            const SizedBox(height: 10),
            const Text(
              'Télécharge et convertis tes audios',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Colle ton lien ici (YouTube, TikTok...)',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF1DB954), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF1DB954)),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _startDownload,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download, color: Colors.white),
                label: Text(
                  _isLoading ? _statusMessage : 'Lancer le téléchargement',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
