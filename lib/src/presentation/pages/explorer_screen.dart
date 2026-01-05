import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import '../../data/datasources/app_database.dart';
import '../../core/services/music_finder.dart';
import '../../core/services/audio_handler.dart';

class ExplorerScreen extends StatelessWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    final musicFinder = Provider.of<MusicFinder>(context);
    final audioHandler = Provider.of<MyAudioHandler>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await musicFinder.pickFolderAndScan();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Track>>(
        stream: db.select(db.tracks).watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tracks = snapshot.data!;

          if (tracks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No music found.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => musicFinder.pickFolderAndScan(),
                    child: const Text('Scan Music Folder'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(track.title),
                subtitle: Text(track.artist ?? 'Unknown'),
                onTap: () {
                  _playTrack(track, audioHandler);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _playTrack(Track track, MyAudioHandler audioHandler) async {
    final mediaItem = MediaItem(
      id: track.path,
      album: track.album ?? '',
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
      artUri: null, // Keep null to prevent crashes
    );

    await audioHandler.addQueueItems([mediaItem]);
    await audioHandler.play();
  }
}
