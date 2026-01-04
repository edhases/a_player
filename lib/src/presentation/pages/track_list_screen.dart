import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:oxide_player/src/core/services/audio_handler.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:oxide_player/src/presentation/pages/player_screen.dart';
import 'package:oxide_player/src/presentation/widgets/mini_player.dart';
import 'package:provider/provider.dart';

class TrackListScreen extends StatefulWidget {
  final String folderPath;

  const TrackListScreen({super.key, required this.folderPath});

  @override
  _TrackListScreenState createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  late AppDatabase _database;
  final MyAudioHandler _audioHandler = GetIt.I<MyAudioHandler>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _database = Provider.of<AppDatabase>(context);
  }

  Future<List<Track>> _getTracks() async {
    final query = _database.select(_database.tracks)
      ..where((t) => t.folderPath.equals(widget.folderPath));
    return query.get();
  }

  MediaItem _trackToMediaItem(Track track) {
    return MediaItem(
      id: track.path,
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
      artUri: track.remoteArtworkUri != null
          ? Uri.parse(track.remoteArtworkUri!)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderPath.split('/').last),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Track>>(
              future: _getTracks(),
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
                      leading: Icon(
                        track.sourceType == 'online'
                            ? Icons.public
                            : Icons.music_note,
                      ),
                      title: Text(track.title),
                      subtitle: Text(track.artist ?? 'Unknown Artist'),
                      onTap: () async {
                        final queue = tracks.map(_trackToMediaItem).toList();
                        await _audioHandler.updateQueue(queue);
                        await _audioHandler.skipToQueueItem(index);
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
}
