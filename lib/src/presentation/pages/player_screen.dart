import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';

import '../../data/datasources/app_database.dart';
import 'equalizer_screen.dart';
import '../widgets/common_artwork.dart';
import '../../core/services/sleep_timer_service.dart';
import '../../core/utils/localization.dart';
import '../../core/utils/duration_formatter.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/youtube_helper.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/innertube/innertube.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get_it/get_it.dart';
import '../blocs/player/player_bloc.dart';
import '../widgets/lyrics_view.dart';
import '../utils/track_actions.dart';
import 'playlist_tracks_screen.dart';
import '../widgets/player/player_widgets.dart';
import '../../core/theme/app_theme.dart';

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
    final colors = context.appColors;

    return Scaffold(
      key: const Key('player_screen'),
      backgroundColor: colors.overlay,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down,
              size: 32, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            key: const Key('player_options_button'),
            icon: Icon(Icons.more_vert, color: colors.textPrimary),
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
                  colors.overlay.withValues(alpha: 0.8),
                  colors.overlay,
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
                color: context.appColors.overlay.withValues(alpha: 0.6),
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
                final colors = context.appColors;
                return Container(
                  decoration: BoxDecoration(
                    color: colors.sheetBackground,
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
                          color: colors.textMuted,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Lyrics',
                          style: TextStyle(
                              color: colors.textPrimary,
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
                icon: Icon(Icons.heart_broken,
                    color: context.appColors.textSecondary, size: 24),
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
                key: const Key('player_like_button'),
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked
                      ? context.appColors.error
                      : context.appColors.textSecondary,
                  size: 28,
                ),
                onPressed: () {
                  TrackActions.handleLikeButton(
                    context,
                    videoId: videoId,
                    title: mediaItem.title,
                    artist: mediaItem.artist ?? 'Unknown',
                    thumbnailUrl: mediaItem.artUri?.toString() ?? '',
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
              color: isFavorite
                  ? context.appColors.error
                  : context.appColors.textSecondary,
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
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.appColors.textPrimary),
          textAlign: TextAlign.start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          key: const Key('player_artist_link'),
          onTap: () async {
            // Handle Artist Tap - always search on YouTube regardless of track source
            debugPrint(
                '[PlayerScreen] Artist tapped. Extras: ${mediaItem.extras}');

            if (mediaItem.artist == null || mediaItem.artist!.isEmpty) {
              return;
            }

            // Get artistId from extras if available (for YouTube tracks)
            var artistId = mediaItem.extras?['artistId'] as String?;
            debugPrint('[PlayerScreen] artistId from extras: $artistId');

            // If no artistId, search for it on YouTube
            if (artistId == null) {
              debugPrint(
                  '[PlayerScreen] Searching for artist: ${mediaItem.artist}');

              // Show loading indicator
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context)
                            .translate('searching_artist')),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }

              try {
                final innerTube = GetIt.I<InnerTubeService>();
                artistId = await innerTube.findArtistId(mediaItem.artist!);
                debugPrint('[PlayerScreen] Found artistId: $artistId');
              } catch (e) {
                debugPrint('[PlayerScreen] Artist search error: $e');
              }

              // Hide loading snackbar
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }
            }

            if (artistId != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistTracksScreen(
                    playlistId: artistId!,
                    title: mediaItem.artist ?? 'Artist',
                    knownArtist: mediaItem.artist,
                    isArtistPage: true,
                  ),
                ),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        AppLocalizations.of(context).artistPageUnavailable)),
              );
            }
          },
          child: Text(
            mediaItem.artist ?? AppLocalizations.of(context).unknownArtist,
            key: const Key('player_artist_text'),
            style: TextStyle(
              fontSize: 18,
              color: context.appColors.textSecondary,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.solid,
              decorationColor: context.appColors.textMuted,
            ),
            textAlign: TextAlign.start,
            maxLines: 1,
          ),
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
                inactiveTrackColor: context.appColors.textMuted,
                thumbColor: context.appColors.textPrimary,
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
                    style: TextStyle(
                        color: context.appColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                        color: context.appColors.textPrimary,
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
              key: const Key('player_shuffle_button'),
              icon: Icon(Icons.shuffle,
                  color: shuffleMode != AudioServiceShuffleMode.none
                      ? colorScheme.primary
                      : context.appColors.textSecondary),
              onPressed: () => playerBloc.add(PlayerSetShuffleMode(
                  shuffleMode == AudioServiceShuffleMode.none
                      ? AudioServiceShuffleMode.all
                      : AudioServiceShuffleMode.none)),
            ),
            IconButton(
              key: const Key('player_prev_button'),
              icon: Icon(Icons.skip_previous,
                  color: context.appColors.textPrimary, size: 45),
              onPressed: () => playerBloc.add(PlayerSkipPrevious()),
            ),
            GestureDetector(
              key: const Key('player_play_pause_button'),
              onTap: () =>
                  playerBloc.add(isPlaying ? PlayerPause() : PlayerPlay()),
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: colorScheme.primary),
                child: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                    color: context.appColors.textPrimary, size: 50),
              ),
            ),
            IconButton(
              key: const Key('player_next_button'),
              icon: Icon(Icons.skip_next,
                  color: context.appColors.textPrimary, size: 45),
              onPressed: () => playerBloc.add(PlayerSkipNext()),
            ),
            IconButton(
              key: const Key('player_repeat_button'),
              icon: Icon(
                  repeatMode == AudioServiceRepeatMode.one
                      ? Icons.repeat_one
                      : Icons.repeat,
                  color: repeatMode != AudioServiceRepeatMode.none
                      ? colorScheme.primary
                      : context.appColors.textSecondary),
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
                icon: Icon(Icons.equalizer,
                    color: context.appColors.textSecondary),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EqualizerScreen()))),
            IconButton(
                icon: Icon(Icons.lyrics_outlined,
                    color: context.appColors.textSecondary),
                tooltip: AppLocalizations.of(context).lyrics,
                onPressed: () {
                  final mediaItem = state.mediaItem;
                  if (mediaItem != null) {
                    _showLyricsSheet(context, mediaItem);
                  }
                }),
            IconButton(
                icon: Icon(Icons.playlist_play,
                    color: context.appColors.textSecondary),
                onPressed: () => QueueSheet.show(context)),
            IconButton(
                icon: Icon(Icons.info_outline,
                    color: context.appColors.textSecondary),
                onPressed: () {
                  _showDetailsSheet(context, state.mediaItem);
                }),
          ],
        ),
      ],
    );
  }

  void _showOptionsSheet(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final mediaItem = context.read<PlayerBloc>().state.mediaItem;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.sheetBackground,
      builder: (context) {
        final colors = context.appColors;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('player_download_action'),
              leading: Icon(Icons.download, color: colors.textPrimary),
              title: Text(loc.download,
                  style: TextStyle(color: colors.textPrimary)),
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
                  final audioData =
                      await ytHelper.getAudioUrlWithAgent(videoId);

                  if (audioData != null) {
                    await GetIt.I<CacheService>().cacheTrack(
                      videoId: videoId,
                      url: audioData['url']!,
                      title: mediaItem.title,
                      artist: mediaItem.artist ?? 'Unknown',
                      thumbnailUrl: mediaItem.artUri?.toString() ?? '',
                      container: audioData['container'],
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
                          content: Text(loc.translate('download_error',
                              args: {'error': e}))),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.timer, color: colors.textPrimary),
              title: Text(loc.sleepTimer,
                  style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.pop(context); // Close options sheet first
                _showSleepTimerDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: colors.textPrimary),
              title: Text(loc.shareTrack,
                  style: TextStyle(color: colors.textPrimary)),
              onTap: () async {
                Navigator.pop(context);
                final videoId = mediaItem?.extras?['videoId'] as String?;
                if (videoId != null && videoId.length == 11) {
                  final url = 'https://music.youtube.com/watch?v=$videoId';
                  await SharePlus.instance.share(ShareParams(
                      text: url, title: mediaItem?.title ?? 'Track'));
                } else {
                  // For local tracks, share title/artist info
                  final title = mediaItem?.title ?? 'Unknown';
                  final artist = mediaItem?.artist ?? 'Unknown';
                  await SharePlus.instance
                      .share(ShareParams(text: '$title - $artist'));
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    final sleepTimer = GetIt.I<SleepTimerService>();
    SleepTimerDialog.show(context, sleepTimer);
  }

  void _showDetailsSheet(BuildContext context, MediaItem? item) {
    if (item == null) return;
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.sheetBackground,
        title: Text(AppLocalizations.of(context).trackDetails,
            style: TextStyle(color: colors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(context, AppLocalizations.of(context).trackDetails,
                item.title), // Title is title
            _detailRow(context, AppLocalizations.of(context).artists,
                item.artist ?? 'Unknown'),
            _detailRow(context, AppLocalizations.of(context).albums,
                item.album ?? 'Unknown'),
            _detailRow(context, AppLocalizations.of(context).path, item.id),
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

  Widget _detailRow(BuildContext context, String label, String value) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          SelectableText(
            value,
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) => d.formatted;
}
