import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import '../../data/datasources/app_database.dart';
import '../../core/services/music_finder.dart';
import '../../../main.dart'; // для доступу до audioHandler

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    final musicFinder = Provider.of<MusicFinder>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // Запуск сканування
              await musicFinder.pickFolderAndScan(); // Або scanAndSaveToDb()
              setState(() {}); // Оновити UI після сканування
            },
          )
        ],
      ),
      // StreamBuilder автоматично оновлює список, коли змінюється БД
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
                  const Text('No music found yet.'),
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
    );
  }

  Future<void> _playTrack(Track track) async {
    // Конвертуємо Track з БД в MediaItem для AudioService
    final mediaItem = MediaItem(
      id: track.path, // Шлях до файлу
      album: track.album ?? '',
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
      artUri: null, // Поки що без картинок, щоб не крешилось
    );

    // Додаємо в чергу і граємо
    await audioHandler.addQueueItems([mediaItem]);
    await audioHandler.play();
  }
}
