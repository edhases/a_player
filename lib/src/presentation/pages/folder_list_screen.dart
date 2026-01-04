import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import 'package:oxide_player/src/core/services/music_finder.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:oxide_player/src/presentation/pages/settings_screen.dart';
import 'package:oxide_player/src/presentation/pages/track_list_screen.dart';
import 'package:provider/provider.dart';

class FolderListScreen extends StatefulWidget {
  const FolderListScreen({super.key});

  @override
  _FolderListScreenState createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  late AppDatabase _database;
  late MusicFinder _musicFinder;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _database = Provider.of<AppDatabase>(context, listen: false);
    _musicFinder = MusicFinder(_database);
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
    });
    await _musicFinder.startScan();
    setState(() {
      _isScanning = false;
    });
  }

  Future<List<String>> _getFolders() async {
    final tracks = await _database.select(_database.tracks).get();
    final folders = tracks.map((t) => t.folderPath).toSet().toList();
    folders.sort();
    return folders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startScan,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isScanning
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<String>>(
              future: _getFolders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No music folders found.'));
                }

                final folders = snapshot.data!;
                return ListView.builder(
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folderPath = folders[index];
                    final folderName = folderPath.split('/').last;
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(folderName),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrackListScreen(folderPath: folderPath),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
