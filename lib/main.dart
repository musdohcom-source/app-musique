import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

void main() {
  runApp(const Mp3ConverterApp());
}

class Mp3ConverterApp extends StatelessWidget {
  const Mp3ConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DUSTMP3',
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
  
  String _selectedPlatform = 'YouTube';
  String _namingFormat = 'Artiste - Titre';

  bool _metadataLoaded = false;
  final String _trackTitle = 'Mon Morceau';
  final String _artistName = 'DUSTOMUET';
  String? _lastDownloadedPath;

  @override
  void initState() {
    super.initState();
    _requestStoragePermissionOnStartup();
  }

  Future<void> _requestStoragePermissionOnStartup() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
      var manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        await Permission.manageExternalStorage.request();
      }
    }
  }

  Future<void> _startRealDownload() async {
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
      _lastDownloadedPath = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _statusMessage = 'Téléchargement du fichier audio...';
        _metadataLoaded = true;
      });

      // Utilisation d'un lien direct testable et sécurisé en HTTPS
      final response = await http.get(Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'));

      if (response.statusCode == 200) {
        String fileName = '';
        if (_namingFormat == 'Artiste - Titre') {
          fileName = '$_artistName - $_trackTitle.mp3';
        } else if (_namingFormat == 'Titre - Artiste') {
          fileName = '$_trackTitle - $_artistName.mp3';
        } else if (_namingFormat == 'Titre uniquement') {
          fileName = '$_trackTitle.mp3';
        } else {
          fileName = '$_artistName.mp3';
        }
        
        fileName = fileName.replaceAll(RegExp(r'[^\w\s\.-]'), '');

        // Récupération d'un répertoire accessible sur Android
        Directory? directory;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory != null && !await directory.exists()) {
          await directory.create(recursive: true);
        }

        final filePath = '${directory!.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _isLoading = false;
          _statusMessage = '';
          _lastDownloadedPath = filePath;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Téléchargé avec succès : $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception('Erreur réseau : ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de téléchargement : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openDownloadedFile() {
    if (_lastDownloadedPath != null && File(_lastDownloadedPath!).existsSync()) {
      OpenFile.open(_lastDownloadedPath);
    } else {
      OpenFile.open('/storage/emulated/0/Download');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DUSTMP3 Multi-Downloader'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1DB954),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                onPressed: _isLoading ? null : _startRealDownload,
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
            
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _openDownloadedFile,
                icon: const Icon(Icons.folder_open, color: Color(0xFF1DB954)),
                label: const Text(
                  'Ouvrir les Téléchargements',
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1DB954)),
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
