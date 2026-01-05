import 'package:flutter/material.dart';
import 'package:oxide_player/src/domain/models/file_system_entry.dart';
import 'package:oxide_player/src/domain/services/hierarchy_service.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:oxide_player/src/core/services/audio_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:drift/drift.dart' as d;
import 'package:oxide_player/src/core/services/music_finder.dart';
import 'package:oxide_player/src/presentation/widgets/mini_player.dart';

class ExplorerScreen extends StatefulWidget {
  final String path;

  const ExplorerScreen({super.key, this.path = '/'});

  @override
  _ExplorerScreenState createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  late HierarchyService _hierarchyService;
  late Future<List<FileSystemEntry>> _entriesFuture;
  final MyAudioHandler _audioHandler = GetIt.I<MyAudioHandler>();
  late MusicFinder _musicFinder;

  @override
  void initState() {
    super.initState();
    final database = Provider.of<AppDatabase>(context, listen: false);
    _hierarchyService = HierarchyService(database);
    _musicFinder = MusicFinder(database);
    _entriesFuture = _hierarchyService.getEntriesForPath(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.path == '/' ? 'My Music' : widget.path.split('/').last),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            onPressed: () => _showAddStreamDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _musicFinder.startScan();
              setState(() {
                _entriesFuture = _hierarchyService.getEntriesForPath(widget.path);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<FileSystemEntry>>(
              future: _entriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No music found in this folder.'));
                }

                final entries = snapshot.data!;
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    if (entry.type == EntryType.folder) {
                      return ListTile(
                        leading: const Icon(Icons.folder),
                        title: Text(entry.name),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ExplorerScreen(path: entry.path),
                            ),
                          );
                        },
                      );
                    } else {
                      final trackEntry = entry as TrackEntry;
                      return ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(trackEntry.name),
                        subtitle:
                            Text(trackEntry.track.artist ?? 'Unknown Artist'),
                        onTap: () async {
                          final tracksInFolder = entries
                              .where((e) => e.type == EntryType.track)
                              .map((e) => (e as TrackEntry).track)
                              .toList();

                          final queue =
                              tracksInFolder.map(_trackToMediaItem).toList();
                          final trackIndex =
                              tracksInFolder.indexOf(trackEntry.track);

                          await _audioHandler.updateQueue(queue);
                          await _audioHandler.skipToQueueItem(trackIndex);
                        },
                      );
                    }
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
                  final database = Provider.of<AppDatabase>(context, listen: false);
                  await database.into(database.tracks).insert(
                        TracksCompanion.insert(
                          path: url,
                          title: name,
                          folderPath: 'Streams',
                          sourceType: const d.Value('online'),
                          duration: 0,
                        ),
                      );
                  Navigator.pop(context);
                  setState(() {
                    _entriesFuture = _hierarchyService.getEntriesForPath(widget.path);
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  MediaItem _trackToMediaItem(Track track) {
    return MediaItem(
      id: track.path,
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
      artUri: track.remoteArtworkUri != null
          ? Uri.parse(track.remoteArtworkUri!)
          : (track.artworkUri != null ? Uri.parse(track.artworkUri!) : null),
      extras: <String, dynamic>{
        'id': track.id.toString(),
      },
    );
  }
}
