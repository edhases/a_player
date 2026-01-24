import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';

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
import 'package:get_it/get_it.dart';
import '../blocs/player/player_bloc.dart';
import '../blocs/queue/queue_bloc.dart';
import '../widgets/lyrics_view.dart';

class PlayerScreen extends StatefulWidget {
  final String heroTag;
  const PlayerScreen({super.key, required this.heroTag});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
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
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          final mediaItem = state.mediaItem;
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
                  // Artwork with Swipe Up for Lyrics
                  Expanded(
                    flex: 6,
                    child: _buildArtwork(context, mediaItem),
                  ),
                  const SizedBox(height: 30),
                  // Track Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(child: _buildTrackInfo(context, mediaItem)),
                        _buildFavoriteButton(mediaItem),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Seekbar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildSeekbar(context, mediaItem),
                  ),
                  const SizedBox(height: 30),
                  // Controls
                  _buildControls(context, state, colorScheme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtwork(BuildContext context, MediaItem mediaItem) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 200) {
            context.read<PlayerBloc>().add(PlayerSkipPrevious());
          }
          if (details.primaryVelocity! < -200) {
            context.read<PlayerBloc>().add(PlayerSkipNext());
          }
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -200) {
          // Swipe Up detected
          _showLyricsSheet(context, mediaItem);
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

  void _showLyricsSheet(BuildContext context, MediaItem mediaItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocBuilder<PlayerBloc, PlayerState>(
          builder: (context, state) {
            final currentItem = state.mediaItem;
            if (currentItem == null) return const SizedBox.shrink();

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Lyrics',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: LyricsView(mediaItem: currentItem),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteButton(MediaItem mediaItem) {
    final isOnline = mediaItem.extras?['isOnline'] == true;
    final videoId = mediaItem.extras?['videoId'] as String?;

    // Always use videoId for like checks
    if (isOnline && videoId != null) {
      final favService = GetIt.I<FavoritesService>();
      return StreamBuilder<bool>(
        stream: favService.isLikedStream(videoId),
        builder: (context, snapshot) {
          final isLiked = snapshot.data ?? false;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dislike Button
              IconButton(
                icon: const Icon(Icons.heart_broken,
                    color: Colors.white70, size: 24),
                onPressed: () {
                  favService.dislikeTrack(videoId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)
                          .removedFromFavorites), // Generic message for now
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              // Like Button
              IconButton(
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
              ),
            ],
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

  Widget _buildTrackInfo(BuildContext context, MediaItem mediaItem) {
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

  Widget _buildSeekbar(BuildContext context, MediaItem mediaItem) {
    final playerBloc = context.read<PlayerBloc>();
    return StreamBuilder<Duration>(
      stream: playerBloc.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = mediaItem.duration ?? Duration.zero;

        double sliderValue = _dragValue ?? position.inMilliseconds.toDouble();
        double maxSliderValue = duration.inMilliseconds.toDouble();

        if (maxSliderValue <= 0) maxSliderValue = 1.0;
        sliderValue = sliderValue.clamp(0.0, maxSliderValue);

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
                  playerBloc
                      .add(PlayerSeek(Duration(milliseconds: value.round())));
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
  }

  Widget _buildControls(
      BuildContext context, PlayerState state, ColorScheme colorScheme) {
    final playerBloc = context.read<PlayerBloc>();
    final isPlaying = state.isPlaying;
    final repeatMode = state.repeatMode;
    final shuffleMode = state.shuffleMode;

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
              onPressed: () => playerBloc.add(PlayerSetShuffleMode(
                  shuffleMode == AudioServiceShuffleMode.none
                      ? AudioServiceShuffleMode.all
                      : AudioServiceShuffleMode.none)),
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous,
                  color: Colors.white, size: 45),
              onPressed: () => playerBloc.add(PlayerSkipPrevious()),
            ),
            GestureDetector(
              onTap: () =>
                  playerBloc.add(isPlaying ? PlayerPause() : PlayerPlay()),
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
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 45),
              onPressed: () => playerBloc.add(PlayerSkipNext()),
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
                final nextMode =
                    modes[(modes.indexOf(repeatMode) + 1) % modes.length];
                playerBloc.add(PlayerSetRepeatMode(nextMode));
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
                icon: const Icon(Icons.lyrics_outlined, color: Colors.white54),
                tooltip: AppLocalizations.of(context).lyrics,
                onPressed: () {
                  final mediaItem = state.mediaItem;
                  if (mediaItem != null) {
                    _showLyricsSheet(context, mediaItem);
                  }
                }),
            IconButton(
                icon: const Icon(Icons.playlist_play, color: Colors.white54),
                onPressed: () => _showQueue(context)),
            IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white54),
                onPressed: () {
                  _showDetailsSheet(context, state.mediaItem);
                }),
          ],
        ),
      ],
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        // Use new context if needed, but we check bloc
        return BlocBuilder<QueueBloc, QueueState>(
          builder: (context, state) {
            final currentQueue = state.queue;
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
                      // We need current item to highlight
                      final currentItem =
                          context.read<PlayerBloc>().state.mediaItem;
                      final isCurrent = currentItem?.id == item.id;

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
                          // TODO: Implement skipToQueueItem in PlayerBloc or via handler?
                          // PlayerBloc doesn't have skipToQueueItem event in my design yet??
                          // Checking player_bloc.dart events... nope, only next/prev.
                          // I should add it or use handler directly.
                          // Ideally add to Bloc.
                          GetIt.I<MyAudioHandler>().skipToQueueItem(index);
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
    final mediaItem = context.read<PlayerBloc>().state.mediaItem;

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
              child: StatefulBuilder(
                builder: (context, setState) {
                  // Default to 15 minutes or keep previous state if we could persist it
                  // For now, simple local state reset on open is fine, or we could lift it.
                  // Since we are inside builder, we need a variable outside or init here.
                  // But set state inside StatefulBuilder re-runs this builder.

                  // Initialize checking mainly if we need a variable that persists
                  // through slider changes.
                  // We can't easily init state here without it resetting.
                  // Actually, let's use a variable captured from closure if we want defaults,
                  // but for a simple slider in a dialog, we can assume a default
                  // and modifying it requires a state holder.
                  // Let's assume we initialize `selectedMinutes` to 15.

                  return _SleepTimerContent(
                    sleepTimer: sleepTimer,
                    loc: loc,
                    remaining: remaining,
                  );
                },
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

class _SleepTimerContent extends StatefulWidget {
  final SleepTimerService sleepTimer;
  final AppLocalizations loc;
  final Duration? remaining;

  const _SleepTimerContent({
    required this.sleepTimer,
    required this.loc,
    required this.remaining,
  });

  @override
  State<_SleepTimerContent> createState() => _SleepTimerContentState();
}

class _SleepTimerContentState extends State<_SleepTimerContent> {
  double _selectedMinutes = 30.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            widget.remaining != null
                ? '${widget.loc.sleepTimer}: ${_formatDuration(widget.remaining!)}'
                : widget.loc.setSleepTimer,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (widget.remaining != null)
          ListTile(
            title: Text(
              widget.loc.stopTimer,
              style: const TextStyle(color: Colors.red),
            ),
            leading: const Icon(Icons.timer_off, color: Colors.red),
            onTap: () {
              widget.sleepTimer.cancelTimer();
              Navigator.pop(context);
            },
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(
                  '${_selectedMinutes.round()} ${widget.loc.minutesSuffix}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Slider(
                  value: _selectedMinutes,
                  min: 1,
                  max: 120,
                  divisions: 119,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() {
                      _selectedMinutes = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  widget.sleepTimer.startTimer(
                    Duration(minutes: _selectedMinutes.round()),
                  );
                  Navigator.pop(context);
                },
                child: Text(
                  widget.loc.startTimer,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
