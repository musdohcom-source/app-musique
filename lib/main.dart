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
  
  // Option de nommage par défaut : Artiste - Titre
  String _namingFormat = 'Artiste - Titre';

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
      _statusMessage = 'Analyse du lien et récupération des tags...';
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _statusMessage = 'Téléchargement (Format: $_namingFormat)...';
      });
    });

    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
        _urlController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Succès ! Enregistré avec le format : $_namingFormat'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convertisseur MP3 & Tags'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1DB954),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.audiotrack, size: 80, color: Color(0xFF1DB954)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Colle ton lien (Spotify, Deezer, YouTube)',
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
            const Text(
              'Format du nom de fichier :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade700),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _namingFormat,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1e1e1e),
                  items: <String>[
                    'Artiste - Titre',
                    'Titre - Artiste',
                    'Titre uniquement',
                    'Artiste uniquement'
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _namingFormat = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
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
