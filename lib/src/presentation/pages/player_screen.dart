import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/services/audio_handler.dart';
import '../../data/datasources/app_database.dart';
import 'equalizer_screen.dart';
import '../widgets/common_artwork.dart';
import 'package:metadata_god/metadata_god.dart';

class PlayerScreen extends StatefulWidget {
  final String heroTag;
  const PlayerScreen({super.key, required this.heroTag});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final MyAudioHandler _audioHandler = GetIt.I<MyAudioHandler>();
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final db = GetIt.I<AppDatabase>();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 32, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showOptionsSheet(context);
            },
          ),
        ],
      ),
      body: StreamBuilder<MediaItem?>(
        stream: _audioHandler.mediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;
          if (mediaItem == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.8),
                  Colors.black,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Album Art
                  Expanded(
                    flex: 6,
                    child: _buildArtwork(mediaItem),
                  ),
                  const SizedBox(height: 30),
                  // Track Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(child: _buildTrackInfo(mediaItem)),
                        StreamBuilder<bool>(
                          stream: db.watchIsFavorite(mediaItem.id),
                          builder: (context, favSnapshot) {
                            final isFavorite = favSnapshot.data ?? false;
                            return IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.white70,
                                size: 28,
                              ),
                              onPressed: () => db.toggleFavorite(mediaItem.id),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Seekbar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildSeekbar(mediaItem),
                  ),
                  const SizedBox(height: 30),
                  // Controls
                  _buildControls(colorScheme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtwork(MediaItem mediaItem) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 200) _audioHandler.skipToPrevious();
          if (details.primaryVelocity! < -200) _audioHandler.skipToNext();
        }
      },
      child: Hero(
        tag: widget.heroTag,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1,
              child: CommonArtwork(
                mediaStoreId: mediaItem.extras?['mediaStoreId'] as int?,
                path: mediaItem.id,
                url: mediaItem.artUri
                    ?.toString(), // Pass artUri for network thumbnails
                size: 400,
                radius: 0,
                placeholderIcon: Icons.music_note,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(MediaItem mediaItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mediaItem.title,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          mediaItem.artist ?? 'Unknown Artist',
          style: TextStyle(
              fontSize: 18, color: Colors.white.withValues(alpha: 0.7)),
          textAlign: TextAlign.start,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildSeekbar(MediaItem mediaItem) {
    return StreamBuilder<Duration>(
      stream: Rx.combineLatest2<Duration, Duration?, Duration>(
        _audioHandler.player.positionStream,
        _audioHandler.player.durationStream,
        (pos, dur) => dur ?? mediaItem.duration ?? Duration.zero,
      ),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? mediaItem.duration ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: _audioHandler.player.positionStream,
          builder: (context, posSnapshot) {
            final position = posSnapshot.data ?? Duration.zero;
            double sliderValue =
                _dragValue ?? position.inMilliseconds.toDouble();
            double maxSliderValue = duration.inMilliseconds.toDouble();

            if (maxSliderValue <= 0) maxSliderValue = 1.0;
            sliderValue = sliderValue.clamp(0.0, maxSliderValue);

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: maxSliderValue,
                    value: sliderValue,
                    onChanged: (value) => setState(() => _dragValue = value),
                    onChangeEnd: (value) {
                      _audioHandler.seek(Duration(milliseconds: value.round()));
                      _dragValue = null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(
                            Duration(milliseconds: sliderValue.round())),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControls(ColorScheme colorScheme) {
    return StreamBuilder<PlaybackState>(
      stream: _audioHandler.playbackState,
      builder: (context, snapshot) {
        final playbackState = snapshot.data;
        final isPlaying = playbackState?.playing ?? false;
        final repeatMode =
            playbackState?.repeatMode ?? AudioServiceRepeatMode.none;
        final shuffleMode =
            playbackState?.shuffleMode ?? AudioServiceShuffleMode.none;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.shuffle,
                      color: shuffleMode != AudioServiceShuffleMode.none
                          ? colorScheme.primary
                          : Colors.white70),
                  onPressed: () => _audioHandler.setShuffleMode(
                      shuffleMode == AudioServiceShuffleMode.none
                          ? AudioServiceShuffleMode.all
                          : AudioServiceShuffleMode.none),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous,
                      color: Colors.white, size: 45),
                  onPressed: _audioHandler.skipToPrevious,
                ),
                GestureDetector(
                  onTap: isPlaying ? _audioHandler.pause : _audioHandler.play,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: colorScheme.primary),
                    child: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white, size: 50),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next,
                      color: Colors.white, size: 45),
                  onPressed: _audioHandler.skipToNext,
                ),
                IconButton(
                  icon: Icon(
                      repeatMode == AudioServiceRepeatMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: repeatMode != AudioServiceRepeatMode.none
                          ? colorScheme.primary
                          : Colors.white70),
                  onPressed: () {
                    final modes = [
                      AudioServiceRepeatMode.none,
                      AudioServiceRepeatMode.all,
                      AudioServiceRepeatMode.one
                    ];
                    _audioHandler.setRepeatMode(
                        modes[(modes.indexOf(repeatMode) + 1) % modes.length]);
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    icon: const Icon(Icons.equalizer, color: Colors.white54),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const EqualizerScreen()))),
                IconButton(
                    icon:
                        const Icon(Icons.playlist_play, color: Colors.white54),
                    onPressed: () => _showQueue(context)),
                IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white54),
                    onPressed: () {
                      _showDetailsSheet(context, _audioHandler.mediaItem.value);
                    }),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StreamBuilder<List<MediaItem>>(
          stream: _audioHandler.queue,
          builder: (context, snapshot) {
            final currentQueue = snapshot.data ?? [];
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Current Queue',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQueue.length,
                    itemBuilder: (context, index) {
                      final item = currentQueue[index];
                      final isCurrent =
                          _audioHandler.mediaItem.value?.id == item.id;
                      return ListTile(
                        leading: _buildQueueArtwork(item),
                        title: Text(item.title,
                            style: TextStyle(
                                color: isCurrent
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white)),
                        subtitle: Text(item.artist ?? '',
                            style: const TextStyle(color: Colors.white70)),
                        onTap: () {
                          _audioHandler.skipToQueueItem(index);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQueueArtwork(MediaItem item) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CommonArtwork(
        mediaStoreId: item.extras?['mediaStoreId'] as int?,
        path: item.id,
        url: item.artUri?.toString(),
        size: 40,
        radius: 4,
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.timer, color: Colors.white),
            title: const Text('Sleep Timer',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white),
            title: const Text('Share Track',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showDetailsSheet(BuildContext context, MediaItem? item) {
    if (item == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text('Track Details', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Title', item.title),
            _detailRow('Artist', item.artist ?? 'Unknown'),
            _detailRow('Album', item.album ?? 'Unknown'),
            _detailRow('Path', item.id),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          SelectableText(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
