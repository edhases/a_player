import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:oxide_player/main.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:oxide_player/src/presentation/pages/player_screen.dart';
import 'package:oxide_player/src/presentation/providers/track_list_provider.dart';
import 'package:oxide_player/src/presentation/widgets/artwork_widget.dart';
import 'package:provider/provider.dart';

class TrackListScreen extends StatelessWidget {
  final String folderPath;

  const TrackListScreen({super.key, required this.folderPath});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TrackListProvider(
        context.read<AppDatabase>(),
        folderPath,
      ),
      child: Consumer<TrackListProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(folderPath.split('/').last),
            ),
            body: buildTrackList(context, provider),
          );
        },
      ),
    );
  }

  Widget buildTrackList(BuildContext context, TrackListProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.tracks.isEmpty) {
      return const Center(child: Text('No tracks found.'));
    }

    return ListView.builder(
      itemCount: provider.tracks.length,
      itemBuilder: (context, index) {
        final track = provider.tracks[index];
        return ListTile(
          leading: ArtworkWidget(track: track),
          title: Text(track.title),
          subtitle: Text(track.artist ?? 'Unknown Artist'),
          onTap: () {
            final audioHandler = getIt<AudioHandler>();
            final mediaItems = provider.tracks
                .map(
                  (track) => MediaItem(
                    id: track.path,
                    title: track.title,
                    artist: track.artist,
                    album: track.album,
                    duration: Duration(milliseconds: track.durationMs),
                    extras: {'track': track},
                  ),
                )
                .toList();
            audioHandler.addQueueItems(mediaItems);
            audioHandler.skipToQueueItem(index);
            audioHandler.play();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PlayerScreen(),
              ),
            );
          },
        );
      },
    );
  }
}
