import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:oxide_player/src/core/services/audio_handler.dart';

class PlayerScreen extends StatelessWidget {
  final String heroTag;
  const PlayerScreen({super.key, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final audioHandler = GetIt.I<MyAudioHandler>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.9),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: StreamBuilder<MediaItem?>(
              stream: audioHandler.mediaItem,
              builder: (context, snapshot) {
                final mediaItem = snapshot.data;
                if (mediaItem == null) {
                  return const Center(child: Text('Not Playing'));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Hero(
                      tag: heroTag,
                      child: _buildArtwork(mediaItem),
                    ),
                    const Spacer(),
                    Text(
                      mediaItem.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mediaItem.artist ?? 'Unknown Artist',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildProgressBar(audioHandler),
                    _buildControls(context, audioHandler),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(MediaItem mediaItem) {
    return AspectRatio(
      aspectRatio: 1,
      child: FutureBuilder<Metadata?>(
        future: MetadataGod.readMetadata(file: mediaItem.id),
        builder: (context, snapshot) {
          final artwork = snapshot.data?.picture?.data;
          return Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: artwork != null
                  ? Image.memory(
                      artwork,
                      gaplessPlayback: true,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                      child: const Icon(Icons.music_note, size: 100),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(MyAudioHandler audioHandler) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final position = snapshot.data?.updatePosition ?? Duration.zero;
        final duration = audioHandler.mediaItem.value?.duration ?? Duration.zero;
        return Column(
          children: [
            Slider(
              value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
              max: duration.inSeconds.toDouble(),
              onChanged: (value) {
                audioHandler.seek(Duration(seconds: value.toInt()));
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position), style: const TextStyle(color: Colors.white70)),
                Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70)),
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
        final playbackState = snapshot.data;
        final isPlaying = playbackState?.playing ?? false;
        final repeatMode = playbackState?.repeatMode ?? AudioServiceRepeatMode.none;
        final shuffleMode = playbackState?.shuffleMode ?? AudioServiceShuffleMode.none;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.shuffle),
              color: shuffleMode == AudioServiceShuffleMode.all
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.white,
              onPressed: () {
                final nextMode = shuffleMode == AudioServiceShuffleMode.all
                    ? AudioServiceShuffleMode.none
                    : AudioServiceShuffleMode.all;
                audioHandler.setShuffleMode(nextMode);
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              iconSize: 48,
              onPressed: audioHandler.skipToPrevious,
            ),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white),
              iconSize: 64,
              onPressed: isPlaying ? audioHandler.pause : audioHandler.play,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              iconSize: 48,
              onPressed: audioHandler.skipToNext,
            ),
            IconButton(
              icon: _getRepeatIcon(repeatMode),
              color: repeatMode != AudioServiceRepeatMode.none
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.white,
              onPressed: () {
                AudioServiceRepeatMode nextMode;
                if (repeatMode == AudioServiceRepeatMode.none) {
                  nextMode = AudioServiceRepeatMode.all;
                } else if (repeatMode == AudioServiceRepeatMode.all) {
                  nextMode = AudioServiceRepeatMode.one;
                } else {
                  nextMode = AudioServiceRepeatMode.none;
                }
                audioHandler.setRepeatMode(nextMode);
              },
            ),
          ],
        );
      },
    );
  }

  Icon _getRepeatIcon(AudioServiceRepeatMode repeatMode) {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        return const Icon(Icons.repeat, color: Colors.white);
      case AudioServiceRepeatMode.one:
        return const Icon(Icons.repeat_one, color: Colors.white);
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        return const Icon(Icons.repeat, color: Colors.white);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
