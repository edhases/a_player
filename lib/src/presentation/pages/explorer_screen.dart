import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import '../../data/datasources/app_database.dart';
import '../../core/services/music_finder.dart';
import '../../../main.dart';
import '../widgets/mini_player.dart'; // 1. Імпорт віджета

class ExplorerScreen extends StatelessWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    final musicFinder = Provider.of<MusicFinder>(context);

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
      // 2. Використовуємо Column для розміщення списку і плеєра
      body: Column(
        children: [
          // Expanded займає весь доступний простір для списку
          Expanded(
            child: StreamBuilder<List<Track>>(
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
                        _playTrack(track);
                      },
                    );
                  },
                );
              },
            ),
          ),
          // 3. Додаємо МініПлеєр в самий низ
          const MiniPlayer(),
        ],
      ),
    );
  }

  Future<void> _playTrack(Track track) async {
    final mediaItem = MediaItem(
      id: track.path,
      album: track.album ?? '',
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
      artUri: null,
    );

    await audioHandler.addQueueItems([mediaItem]);
    await audioHandler.play();
  }
}
