import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/services/audio_handler.dart';
import '../../data/datasources/app_database.dart';
import 'equalizer_screen.dart';
import '../widgets/common_artwork.dart';
import '../../core/services/sleep_timer_service.dart';
import '../../core/utils/localization.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/youtube_helper.dart';
import '../../core/services/favorites_service.dart';
import 'package:share_plus/share_plus.dart';

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
                        _buildFavoriteButton(mediaItem),
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

  Widget _buildFavoriteButton(MediaItem mediaItem) {
    final isOnline = mediaItem.extras?['isOnline'] == true;
    final videoId = mediaItem.extras?['videoId'] as String?;

    // Always use videoId for like checks - liked songs are stored by videoId only
    // Always use videoId for like checks - liked songs are stored by videoId only
    if (isOnline && videoId != null) {
      // YouTube track - use FavoritesService
      final favService = GetIt.I<FavoritesService>();
      return StreamBuilder<bool>(
        stream: favService.isLikedStream(videoId),
        builder: (context, snapshot) {
          final isLiked = snapshot.data ?? false;
          return IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.white70,
              size: 28,
            ),
            onPressed: () {
              favService.toggleFavorite(
                videoId: videoId,
                title: mediaItem.title,
                artist: mediaItem.artist ?? 'Unknown',
                thumbnailUrl: mediaItem.artUri?.toString() ?? '',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isLiked
                      ? AppLocalizations.of(context).removedFromFavorites
                      : AppLocalizations.of(context).addedToFavorites),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          );
        },
      );
    } else {
      // Local track - use AppDatabase
      final db = GetIt.I<AppDatabase>();
      return StreamBuilder<bool>(
        stream: db.watchIsFavorite(mediaItem.id),
        builder: (context, snapshot) {
          final isFavorite = snapshot.data ?? false;
          return IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white70,
              size: 28,
            ),
            onPressed: () => db.toggleFavorite(mediaItem.id),
          );
        },
      );
    }
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
          mediaItem.artist ?? AppLocalizations.of(context).unknownArtist,
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(AppLocalizations.of(context).currentQueue,
                      style: const TextStyle(
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
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.download, color: Colors.white),
            title:
                Text(loc.download, style: const TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context); // Close sheet

              final mediaItem = _audioHandler.mediaItem.value;
              if (mediaItem == null || mediaItem.extras?['videoId'] == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.cannotDownload)),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.startingDownload)),
              );

              try {
                final videoId = mediaItem.extras!['videoId'] as String;
                final ytHelper = GetIt.I<YouTubeHelper>();
                final url = await ytHelper.getAudioUrl(videoId);

                if (url != null) {
                  await GetIt.I<CacheService>().cacheTrack(
                    videoId: videoId,
                    url: url,
                    title: mediaItem.title,
                    artist: mediaItem.artist ?? 'Unknown',
                    thumbnailUrl: mediaItem.artUri?.toString() ?? '',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(loc.translate('downloaded',
                              args: {'title': mediaItem.title}))),
                    );
                  }
                } else {
                  throw Exception('Could not get audio URL');
                }
              } catch (e) {
                debugPrint('Download error: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(loc
                            .translate('download_error', args: {'error': e}))),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer, color: Colors.white),
            title: Text(loc.sleepTimer,
                style: const TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context); // Close options sheet first
              _showSleepTimerDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white),
            title: Text(loc.shareTrack,
                style: const TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              final mediaItem = _audioHandler.mediaItem.value;
              final videoId = mediaItem?.extras?['videoId'] as String?;
              if (videoId != null && videoId.length == 11) {
                final url = 'https://music.youtube.com/watch?v=$videoId';
                await Share.share(url, subject: mediaItem?.title ?? 'Track');
              } else {
                // For local tracks, share title/artist info
                final title = mediaItem?.title ?? 'Unknown';
                final artist = mediaItem?.artist ?? 'Unknown';
                await Share.share('$title - $artist');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    final sleepTimer = GetIt.I<SleepTimerService>();
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ValueListenableBuilder<Duration?>(
          valueListenable: sleepTimer.remainingTime,
          builder: (context, remaining, child) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                        remaining != null
                            ? '${loc.sleepTimer}: ${_formatDuration(remaining)}'
                            : loc.setSleepTimer,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  if (remaining != null)
                    ListTile(
                        title: Text(loc.stopTimer,
                            style: const TextStyle(color: Colors.red)),
                        leading: const Icon(Icons.timer_off, color: Colors.red),
                        onTap: () {
                          sleepTimer.cancelTimer();
                          Navigator.pop(context);
                        }),
                  ...[15, 30, 45, 60].map((minutes) => ListTile(
                        leading: const Icon(Icons.access_time,
                            color: Colors.white70),
                        title: Text('$minutes ${loc.minutesSuffix}',
                            style: const TextStyle(color: Colors.white)),
                        onTap: () {
                          sleepTimer.startTimer(Duration(minutes: minutes));
                          Navigator.pop(context);
                        },
                      )),
                  // Optional: Custom Time? Keeping it simple for now as requested.
                ],
              ),
            );
          }),
    );
  }

  void _showDetailsSheet(BuildContext context, MediaItem? item) {
    if (item == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(AppLocalizations.of(context).trackDetails,
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(AppLocalizations.of(context).trackDetails,
                item.title), // Title is title
            _detailRow(
                AppLocalizations.of(context).artists, item.artist ?? 'Unknown'),
            _detailRow(
                AppLocalizations.of(context).albums, item.album ?? 'Unknown'),
            _detailRow(AppLocalizations.of(context).path, item.id),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).close)),
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
