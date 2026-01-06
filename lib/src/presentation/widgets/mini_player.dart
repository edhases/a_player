import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import 'package:metadata_god/metadata_god.dart';
import '../pages/player_screen.dart';
import '../../core/services/audio_handler.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioHandler = GetIt.I<MyAudioHandler>();

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, mediaItemSnapshot) {
        if (!mediaItemSnapshot.hasData || mediaItemSnapshot.data == null) {
          return const SizedBox.shrink();
        }

        final mediaItem = mediaItemSnapshot.data!;
        final heroTag = 'player_art_${mediaItem.id}';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlayerScreen(heroTag: heroTag)),
            );
          },
          child: Container(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Hero(
                    tag: heroTag,
                    child: _buildArtwork(mediaItem),
                  ),
                  title: Text(mediaItem.title, maxLines: 1),
                  subtitle: Text(mediaItem.artist ?? 'Unknown', maxLines: 1),
                  trailing: _buildControls(audioHandler),
                ),
                _buildProgressBar(audioHandler),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtwork(MediaItem mediaItem) {
    return FutureBuilder<Metadata?>(
      future: MetadataGod.readMetadata(file: mediaItem.id),
      builder: (context, snapshot) {
        final artwork = snapshot.data?.picture?.data;
        return ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: SizedBox(
            width: 50,
            height: 50,
            child: artwork != null
                ? Image.memory(artwork, fit: BoxFit.cover, gaplessPlayback: true)
                : const Icon(Icons.music_note),
          ),
        );
      },
    );
  }

  Widget _buildControls(MyAudioHandler audioHandler) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, playbackStateSnapshot) {
        final isPlaying = playbackStateSnapshot.data?.playing ?? false;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: isPlaying ? audioHandler.pause : audioHandler.play,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: audioHandler.skipToNext,
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar(MyAudioHandler audioHandler) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final position = snapshot.data?.updatePosition ?? Duration.zero;
        final duration = audioHandler.mediaItem.value?.duration ?? Duration.zero;
        final progress = (duration.inMilliseconds > 0)
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;
        return LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 2,
        );
      },
    );
  }
}
