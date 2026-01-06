import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:metadata_god/metadata_god.dart';
import '../../core/services/audio_handler.dart';

class PlayerScreen extends StatefulWidget {
  final String heroTag;
  const PlayerScreen({super.key, required this.heroTag});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final MyAudioHandler _audioHandler = GetIt.I<MyAudioHandler>();
  late final PlayerController _waveformController;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;
  StreamSubscription<PlaybackState>? _playbackStateSubscription;

  @override
  void initState() {
    super.initState();
    _waveformController = PlayerController();
    _subscribeToPlayer();
  }

  @override
  void dispose() {
    _mediaItemSubscription?.cancel();
    _playbackStateSubscription?.cancel();
    _waveformController.dispose();
    super.dispose();
  }

  void _subscribeToPlayer() {
    _mediaItemSubscription = _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        _prepareWaveform(mediaItem);
      }
    });

    _playbackStateSubscription = _audioHandler.playbackState.listen((playbackState) {
      if (!mounted) return;
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;

      if (isPlaying) {
        _waveformController.startPlayer(finishMode: FinishMode.pause);
      } else if (processingState != AudioProcessingState.completed) {
        _waveformController.pausePlayer();
      }
    });
  }

  Future<void> _prepareWaveform(MediaItem mediaItem) async {
    // This can throw an exception if the file is not found, which is ok.
    try {
      await _waveformController.preparePlayer(
        path: mediaItem.id,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1.0,
      );
      final currentPosition = _audioHandler.playbackState.value.updatePosition;
      _waveformController.seekTo(currentPosition.inMilliseconds);
    } catch (e) {
      debugPrint("Error preparing waveform: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Theme.of(context).colorScheme.primary.withOpacity(0.5),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: StreamBuilder<MediaItem?>(
              stream: _audioHandler.mediaItem,
              builder: (context, snapshot) {
                final mediaItem = snapshot.data;
                if (mediaItem == null) return const SizedBox.shrink();

                return Column(
                  children: [
                    const Spacer(),
                    _buildArtwork(mediaItem),
                    const Spacer(),
                    _buildTrackInfo(context, mediaItem),
                    const SizedBox(height: 20),
                    _buildWaveformSeekbar(),
                    _buildControls(context),
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
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 100) {
          _audioHandler.skipToPrevious();
        } else if (details.primaryVelocity! < -100) {
          _audioHandler.skipToNext();
        }
      },
      child: Hero(
        tag: widget.heroTag,
        child: AspectRatio(
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
                      ? Image.memory(artwork, fit: BoxFit.cover, gaplessPlayback: true)
                      : Container(
                          color: Colors.grey.withOpacity(0.2),
                          child: const Icon(Icons.music_note, size: 100),
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(BuildContext context, MediaItem mediaItem) {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildWaveformSeekbar() {
    return Column(
      children: [
        AudioFileWaveforms(
          size: Size(MediaQuery.of(context).size.width, 100.0),
          playerController: _waveformController,
          enableSeekGesture: true,
          waveformType: WaveformType.long,
          playerWaveStyle: const PlayerWaveStyle(
            fixedWaveColor: Colors.white30,
            liveWaveColor: Colors.white,
            spacing: 6.0,
          ),
          onSeekChange: (duration) {
            _audioHandler.seek(duration);
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<Duration>(
          stream: _audioHandler.player.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration = _audioHandler.mediaItem.value?.duration ?? Duration.zero;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position), style: const TextStyle(color: Colors.white70)),
                Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: _audioHandler.playbackState,
      builder: (context, snapshot) {
        final playbackState = snapshot.data;
        final isPlaying = playbackState?.playing ?? false;
        final repeatMode = playbackState?.repeatMode ?? AudioServiceRepeatMode.none;
        final shuffleMode = playbackState?.shuffleMode ?? AudioServiceShuffleMode.none;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.equalizer, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EqualizerScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.shuffle, color: Colors.white),
              color: shuffleMode == AudioServiceShuffleMode.all
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.white,
              onPressed: () {
                final nextMode = shuffleMode == AudioServiceShuffleMode.all
                    ? AudioServiceShuffleMode.none
                    : AudioServiceShuffleMode.all;
                _audioHandler.setShuffleMode(nextMode);
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              iconSize: 48,
              onPressed: _audioHandler.skipToPrevious,
            ),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white),
              iconSize: 64,
              onPressed: isPlaying ? _audioHandler.pause : _audioHandler.play,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              iconSize: 48,
              onPressed: _audioHandler.skipToNext,
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
                _audioHandler.setRepeatMode(nextMode);
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
