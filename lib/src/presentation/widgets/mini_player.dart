import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import '../pages/player_screen.dart';
import '../../core/services/audio_handler.dart';
import 'common_artwork.dart';

/// Mini player widget displayed at the bottom of the app.
/// Poweramp-inspired design with smooth animations.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioHandler = GetIt.I<MyAudioHandler>();
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, mediaItemSnapshot) {
        final mediaItem = mediaItemSnapshot.data;
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        final heroTag = 'player_art_${mediaItem.id}';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    PlayerScreen(heroTag: heroTag),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar at top
                StreamBuilder<Duration>(
                  stream: audioHandler.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = mediaItem.duration ?? Duration.zero;
                    final progress = duration.inMilliseconds > 0
                        ? position.inMilliseconds / duration.inMilliseconds
                        : 0.0;

                    return LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 2,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    );
                  },
                ),
                // Main content
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Album art
                      Hero(
                        tag: heroTag,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: CommonArtwork(
                            mediaStoreId:
                                mediaItem.extras?['mediaStoreId'] as int?,
                            path: mediaItem.id,
                            url: mediaItem.artUri?.toString(),
                            size: 48,
                            radius: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Track info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mediaItem.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mediaItem.artist ?? 'Unknown Artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Controls
                      _buildControls(audioHandler, colorScheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls(MyAudioHandler audioHandler, ColorScheme colorScheme) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, playbackStateSnapshot) {
        final isPlaying = playbackStateSnapshot.data?.playing ?? false;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 32,
              ),
              onPressed: isPlaying ? audioHandler.pause : audioHandler.play,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, size: 28),
              onPressed: audioHandler.skipToNext,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        );
      },
    );
  }
}
