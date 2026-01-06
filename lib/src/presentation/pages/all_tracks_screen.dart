import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import '../../data/datasources/app_database.dart';
import '../../core/services/music_finder.dart';
import '../../core/services/audio_handler.dart';

// Self-Correction: Renamed from ExplorerScreen to AllTracksScreen
class AllTracksScreen extends StatelessWidget {
  const AllTracksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    final musicFinder = Provider.of<MusicFinder>(context);
    final audioHandler = GetIt.I<MyAudioHandler>();

    // Self-Correction: Removed Scaffold, AppBar, and MiniPlayer.
    // This widget is now just the content for a tab.
    return Scaffold(
        appBar: AppBar(
            title: const Text('All Tracks'),
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
                                _playQueue(audioHandler, tracks, index);
                            },
                        );
                    },
                );
            },
        ));
  }

  // Self-Correction: When a track is tapped, the entire list becomes the new queue.
  Future<void> _playQueue(MyAudioHandler audioHandler, List<Track> tracks, int startIndex) async {
    final mediaItems = tracks.map((track) => MediaItem(
      id: track.path,
      album: track.album ?? '',
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
    )).toList();

    await audioHandler.updateQueue(mediaItems);
    await audioHandler.skipToQueueItem(startIndex);
  }
}
