import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

void main() {
  runApp(const DustMp3App());
}

class DustMp3App extends StatelessWidget {
  const DustMp3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DUSTMP3 - DUSTOMUET',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1DB954),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),
          secondary: Color(0xFF1ED760),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const ConverterHomePage(),
    );
  }
}

class DownloadItem {
  final String title;
  final String path;
  final DateTime date;

  DownloadItem({required this.title, required this.path, required this.date});
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
  String _trackTitle = '';
  String _artistName = 'DUSTOMUET';
  String? _lastDownloadedPath;

  // Liste pour conserver l'historique des téléchargements de la session
  final List<DownloadItem> _downloadHistory = [];

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
    final inputUrl = _urlController.text.trim();
    if (inputUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un lien valide !')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Analyse du lien via backend...';
      _metadataLoaded = false;
      _lastDownloadedPath = null;
    });

    try {
      // 1. Interrogation du service backend de conversion audio
      final apiUri = Uri.parse('https://api.cobalt.tools/api/json');
      final responseApi = await http.post(
        apiUri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'url': inputUrl,
          'downloadMode': 'audio',
          'audioFormat': 'mp3',
        }),
      );

      if (responseApi.statusCode != 200) {
        throw Exception('Impossible de traiter ce lien ($inputUrl).');
      }

      final data = jsonDecode(responseApi.body);
      final String? downloadUrl = data['url'];
      final String titleFromApi = data['filename'] ?? 'Musique_DUSTMP3';

      if (downloadUrl == null) {
        throw Exception('Aucun flux audio récupéré.');
      }

      setState(() {
        _statusMessage = 'Téléchargement du fichier MP3...';
        _trackTitle = titleFromApi.replaceAll('.mp3', '');
        _metadataLoaded = true;
      });

      // 2. Téléchargement du binaire MP3
      final audioResponse = await http.get(Uri.parse(downloadUrl));

      if (audioResponse.statusCode == 200) {
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
        await file.writeAsBytes(audioResponse.bodyBytes);

        setState(() {
          _isLoading = false;
          _statusMessage = '';
          _lastDownloadedPath = filePath;
          _downloadHistory.insert(
            0,
            DownloadItem(
              title: fileName,
              path: filePath,
              date: DateTime.now(),
            ),
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Succès : $fileName enregistré !'),
            backgroundColor: const Color(0xFF1DB954),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception('Erreur de réseau lors de la récupération du MP3.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _openFile(String path) {
    if (File(path).existsSync()) {
      OpenFile.open(path);
    } else {
      OpenFile.open('/storage/emulated/0/Download');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DUSTMP3',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1DB954),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pochette / Logo principal
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1DB954), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1DB954).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.music_note, size: 60, color: Color(0xFF1DB954)),
              ),
            ),
            const SizedBox(height: 25),

            // Sélection de la plateforme
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
                  backgroundColor: const Color(0xFF1E1E1E),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedPlatform = platform;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Champ de texte pour le lien
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Colle ton lien $_selectedPlatform...',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF1DB954), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF1DB954)),
              ),
            ),
            const SizedBox(height: 20),

            // Choix du format de nommage
            const Text(
              'Format du nom de fichier :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border.all(color: Colors.grey.shade800),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _namingFormat,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E1E1E),
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
            const SizedBox(height: 25),

            // Bouton de Téléchargement
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _startRealDownload,
                icon: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Icon(Icons.download_rounded, color: Colors.white),
                label: Text(
                  _isLoading ? _statusMessage : 'Convertir & Télécharger',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
              ),
            ),
            
            const SizedBox(height: 15),

            // Bouton Ouvrir Téléchargements
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _openFile(_lastDownloadedPath ?? '/storage/emulated/0/Download'),
                icon: const Icon(Icons.folder_open, color: Color(0xFF1DB954)),
                label: const Text(
                  'Dossier Téléchargements',
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1DB954)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(color: Colors.grey),
            const SizedBox(height: 10),

            // Section Historique
            const Text(
              'Historique de cette session :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),

            _downloadHistory.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Aucun téléchargement récent.',
                        style: TextStyle(color: Colors.grey, italic: true),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _downloadHistory.length,
                    itemBuilder: (context, index) {
                      final item = _downloadHistory[index];
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: const Icon(Icons.audiotrack, color: Color(0xFF1DB954)),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${item.date.hour}:${item.date.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow, color: Color(0xFF1DB954)),
                            onPressed: () => _openFile(item.path),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
