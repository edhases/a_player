import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:oxide_player/src/core/services/audio_handler.dart';
import 'package:oxide_player/src/presentation/pages/player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerScreen()),
            );
          },
          child: Container(
            color: Colors.grey.shade900,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPlayerControls(context, audioHandler, mediaItem),
                _buildProgressBar(audioHandler),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerControls(
      BuildContext context, MyAudioHandler audioHandler, MediaItem mediaItem) {
    return ListTile(
      leading: _buildArtwork(mediaItem),
      title: Text(mediaItem.title, maxLines: 1),
      subtitle: Text(mediaItem.artist ?? 'Unknown Artist', maxLines: 1),
      trailing: StreamBuilder<PlaybackState>(
        stream: audioHandler.playbackState,
        builder: (context, playbackStateSnapshot) {
          final isPlaying = playbackStateSnapshot.data?.playing ?? false;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  if (isPlaying) {
                    audioHandler.pause();
                  } else {
                    audioHandler.play();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: audioHandler.skipToNext,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArtwork(MediaItem mediaItem) {
    final artworkUrl = mediaItem.artUri?.toString();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: SizedBox(
        width: 50,
        height: 50,
        child: artworkUrl != null && artworkUrl.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: artworkUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.music_note),
              )
            : Container(
                color: Colors.grey,
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildProgressBar(MyAudioHandler audioHandler) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final position = snapshot.data?.updatePosition ?? Duration.zero;
        final duration =
            audioHandler.mediaItem.value?.duration ?? Duration.zero;
        final progress = (duration.inMilliseconds > 0)
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;
        return LinearProgressIndicator(
          value: progress.isNaN || progress.isInfinite ? 0.0 : progress,
          backgroundColor: Colors.grey.shade700,
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        );
      },
    );
  }
}
