import 'package:flutter/material.dart';
import '../../domain/entities/youtube_song.dart';
import 'common_artwork.dart';

/// A compact list tile for Quick Picks section (YouTube Music style)
class CompactQuickPickTile extends StatelessWidget {
  final YouTubeSong song;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;
  final VoidCallback? onMenuTap;

  const CompactQuickPickTile({
    super.key,
    required this.song,
    this.onTap,
    this.onPlayTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CommonArtwork(
                url: song.thumbnailUrl,
                size: 56,
              ),
            ),
            const SizedBox(width: 12),

            // Title & Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
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

            // Play button
            IconButton(
              icon: Icon(
                Icons.play_circle_filled,
                color: colorScheme.primary,
                size: 36,
              ),
              onPressed: onPlayTap ?? onTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),

            // Menu button
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: Colors.grey[400],
                size: 20,
              ),
              onPressed: onMenuTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
