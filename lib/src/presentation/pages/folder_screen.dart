import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import 'package:path/path.dart' as p;

import '../../data/datasources/app_database.dart';
import '../../domain/services/hierarchy_service.dart';
import '../../core/services/audio_handler.dart';

class FolderScreen extends StatelessWidget {
  /// The path to display. '.' represents the root.
  final String path;
  final HierarchyService _hierarchyService = HierarchyService();

  FolderScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final audioHandler = GetIt.I<MyAudioHandler>();

    final bool isRoot = path == '.';
    final String title = isRoot ? 'Folders' : p.basename(path);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        // The root view doesn't get a back button in the app bar
        automaticallyImplyLeading: !isRoot,
      ),
      body: StreamBuilder<List<Track>>(
        stream: db.select(db.tracks).watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allTracks = snapshot.data!;
          final entries = _hierarchyService.getEntriesForPath(allTracks, path);

          if (entries.isEmpty) {
            return const Center(child: Text('This folder is empty.'));
          }

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              if (entry is FolderEntry) {
                return ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(entry.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FolderScreen(path: entry.path),
                      ),
                    );
                  },
                );
              } else if (entry is TrackEntry) {
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(entry.track.title),
                  subtitle: Text(entry.track.artist ?? 'Unknown Artist'),
                  onTap: () {
                    // Get all tracks in the current directory to form a queue.
                    final tracksInFolder = entries
                        .whereType<TrackEntry>()
                        .map((te) => te.track)
                        .toList();

                    _playQueue(audioHandler, tracksInFolder, entry.track);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  void _playQueue(MyAudioHandler audioHandler, List<Track> tracks, Track startTrack) {
    final mediaItems = tracks.map((track) => MediaItem(
      id: track.path,
      album: track.album ?? '',
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
    )).toList();

    final startIndex = tracks.indexOf(startTrack);

    audioHandler.updateQueue(mediaItems);
    audioHandler.skipToQueueItem(startIndex);
  }
}
