import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/youtube_song.dart';
import '../../core/theme/app_theme.dart';

class SongCard extends StatelessWidget {
  final YouTubeSong song;
  final VoidCallback? onTap;

  const SongCard({
    super.key,
    required this.song,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: SizedBox(
                width: 140,
                height: 80, // Fixed height for 16:9 ratio approx
                child: CachedNetworkImage(
                  imageUrl: song.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: colors.sheetBackground,
                    child: Center(
                      child: Icon(Icons.music_note, color: colors.textMuted),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: colors.sheetBackground,
                    child: Center(
                      child: Icon(Icons.broken_image, color: colors.textMuted),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Text Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: colors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colors.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (song.duration > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _formatDuration(Duration(seconds: song.duration)),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.textMuted,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Play Button Icon
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(
                Icons.play_circle_fill,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }
}
