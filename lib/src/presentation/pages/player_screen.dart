import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oxide_player/src/core/services/audio_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioHandler = GetIt.I<MyAudioHandler>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
      ),
      body: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;
          if (mediaItem == null) {
            return const Center(child: Text('Not Playing'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildArtwork(mediaItem),
                const SizedBox(height: 20),
                Text(
                  mediaItem.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  mediaItem.artist ?? 'Unknown Artist',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildProgressBar(audioHandler),
                _buildControls(context, audioHandler),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtwork(MediaItem mediaItem) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: QueryArtworkWidget(
          id: int.parse(mediaItem.extras!['id']),
          type: ArtworkType.AUDIO,
          artworkFit: BoxFit.cover,
          nullArtworkWidget: CachedNetworkImage(
            imageUrl: mediaItem.artUri.toString(),
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
                const Icon(Icons.music_note, size: 100),
          ),
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
        return Column(
          children: [
            Slider(
              value: position.inMilliseconds
                  .toDouble()
                  .clamp(0.0, duration.inMilliseconds.toDouble()),
              max: duration.inMilliseconds.toDouble(),
              onChanged: (value) {
                audioHandler.seek(Duration(milliseconds: value.toInt()));
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position)),
                Text(_formatDuration(duration)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, MyAudioHandler audioHandler) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: 48,
              onPressed: audioHandler.skipToPrevious,
            ),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
              iconSize: 64,
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
              iconSize: 48,
              onPressed: audioHandler.skipToNext,
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
