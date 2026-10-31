import 'package:flutter/material.dart';

void main() {
  runApp(const Mp3ConverterApp());
}

class Mp3ConverterApp extends StatelessWidget {
  const Mp3ConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dustomuet MP3 Downloader',
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
  
  // Options de configuration
  String _selectedPlatform = 'YouTube';
  String _namingFormat = 'Artiste - Titre';

  // Métadonnées simulées
  bool _metadataLoaded = false;
  String _trackTitle = '';
  String _artistName = '';

  void _startProcess() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un lien valide !')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Connexion à $_selectedPlatform...';
      _metadataLoaded = false;
    });

    // Étape 1 : Analyse de la plateforme et récupération des tags
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _statusMessage = 'Récupération de la pochette & métadonnées...';
        _trackTitle = 'Titre extrait de $_selectedPlatform';
        _artistName = 'DUSTOMUET';
        _metadataLoaded = true;
      });
    });

    // Étape 2 : Enregistrement final selon le format de nommage choisi
    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Téléchargé via $_selectedPlatform ! Format : $_namingFormat'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dustomuet Multi-Downloader'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1DB954),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pochette d'album dynamique
            Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1DB954), width: 2),
                ),
                child: _metadataLoaded
                    ? const Icon(Icons.album, size: 70, color: Color(0xFF1DB954))
                    : const Icon(Icons.music_note, size: 50, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // Choix de la plateforme
            const Text(
              'Plateforme source :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['YouTube', 'Spotify', 'Deezer'].map((platform) {
                bool isSelected = _selectedPlatform == platform;
                return ChoiceChip(
                  label: Text(platform),
                  selected: isSelected,
                  selectedColor: const Color(0xFF1DB954),
                  backgroundColor: const Color(0xFF1e1e1e),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedPlatform = platform;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Champ Lien
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Colle ton lien de $_selectedPlatform...',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF1DB954), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF1DB954)),
              ),
            ),
            const SizedBox(height: 20),

            if (_metadataLoaded) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1e1e1e),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Titre : $_trackTitle', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 5),
                    Text('Artiste : $_artistName', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Choix du format de nommage
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

            // Bouton de téléchargement
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _startProcess,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.download, color: Colors.white),
                label: Text(
                  _isLoading ? _statusMessage : 'Télécharger la musique',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
