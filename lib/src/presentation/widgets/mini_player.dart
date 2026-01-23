import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../pages/player_screen.dart';
import '../blocs/player/player_bloc.dart';
import 'common_artwork.dart';

/// Mini player widget displayed at the bottom of the app.
/// Poweramp-inspired design with smooth animations.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        final mediaItem = state.mediaItem;
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
                // For smoother progress bar we might still want a StreamBuilder or Ticker
                // leveraging the position from Bloc + timestamp or just StreamBuilder on audioHandler if available?
                // But we want to decouple.
                // Let's use the state.position for now, accepting it update frequency (which is tied to handler stream).
                LinearProgressIndicator(
                  value: (state.duration.inMilliseconds > 0)
                      ? (state.position.inMilliseconds /
                              state.duration.inMilliseconds)
                          .clamp(0.0, 1.0)
                      : 0.0,
                  minHeight: 2,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
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
                      _buildControls(context, state, colorScheme),
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

  Widget _buildControls(
      BuildContext context, PlayerState state, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 32,
          ),
          onPressed: () {
            context
                .read<PlayerBloc>()
                .add(state.isPlaying ? PlayerPause() : PlayerPlay());
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, size: 28),
          onPressed: () {
            context.read<PlayerBloc>().add(PlayerSkipNext());
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ],
    );
  }
}
