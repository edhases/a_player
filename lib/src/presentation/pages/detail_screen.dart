import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import '../../data/datasources/app_database.dart';
import '../../core/services/audio_handler.dart';

enum DetailScreenType { album, artist }

class DetailScreen extends StatelessWidget {
  final DetailScreenType type;
  final int entityId;
  final String title;

  const DetailScreen({
    super.key,
    required this.type,
    required this.entityId,
    required this.title,
  });

  Future<List<Track>> _fetchTracks(AppDatabase db) {
    if (type == DetailScreenType.album) {
      return db.getTracksForAlbum(entityId);
    } else {
      return db.getTracksForArtist(entityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final audioHandler = GetIt.I<MyAudioHandler>();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<List<Track>>(
        future: _fetchTracks(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tracks found.'));
          }

          final tracks = snapshot.data!;

          return ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(track.title),
                subtitle: Text(track.artist ?? 'Unknown Artist'),
                onTap: () {
                  _playQueue(audioHandler, tracks, index);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _playQueue(MyAudioHandler audioHandler, List<Track> tracks, int startIndex) {
    final mediaItems = tracks.map((track) => MediaItem(
      id: track.path,
      album: track.album ?? '',
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
    )).toList();

    audioHandler.updateQueue(mediaItems);
    audioHandler.skipToQueueItem(startIndex);
  }
}
