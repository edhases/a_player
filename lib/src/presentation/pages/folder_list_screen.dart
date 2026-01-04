import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import 'package:oxide_player/src/core/services/music_finder.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:oxide_player/src/presentation/pages/track_list_screen.dart';
import 'package:oxide_player/src/presentation/widgets/mini_player.dart';
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
            icon: const Icon(Icons.add_link),
            onPressed: () => _showAddStreamDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startScan,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isScanning
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
                                  builder: (context) =>
                                      TrackListScreen(folderPath: folderPath),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  void _showAddStreamDialog(BuildContext context) {
    final urlController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Stream'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL'),
                keyboardType: TextInputType.url,
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final url = urlController.text;
                final name = nameController.text;
                if (url.isNotEmpty && name.isNotEmpty) {
                  await _database.into(_database.tracks).insert(
                        TracksCompanion.insert(
                          path: url,
                          title: name,
                          folderPath: 'Streams',
                          sourceType: const d.Value('online'),
                          duration: 0, // Duration is not applicable for streams
                        ),
                      );
                  Navigator.pop(context);
                  setState(() {}); // Refresh the folder list
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
