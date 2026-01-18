import 'package:flutter/material.dart';
import '../../domain/entities/youtube_song.dart';
import 'common_artwork.dart';
import 'youtube_song_menu.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/favorites_service.dart';
import '../../core/utils/localization.dart';

class SquareSongCard extends StatelessWidget {
  final YouTubeSong song;
  final VoidCallback? onTap;
  final double width;

  const SquareSongCard({
    super.key,
    required this.song,
    this.onTap,
    this.width = 160,
  });

  Future<void> _showContextMenu(BuildContext context) async {
    // Використовуємо централізоване контекстне меню
    await YouTubeSongMenu.show(context, song);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      child: Container(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Квадратна обкладинка
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CommonArtwork(
                        url: song.thumbnailUrl,
                        size: 120,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: StreamBuilder<bool>(
                      stream: GetIt.I<FavoritesService>()
                          .isLikedStream(song.videoId),
                      builder: (context, snapshot) {
                        final isLiked = snapshot.data ?? false;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: 16,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(5),
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.white,
                            ),
                            onPressed: () {
                              GetIt.I<FavoritesService>().toggleFavorite(
                                videoId: song.videoId,
                                title: song.title,
                                artist: song.artist,
                                thumbnailUrl: song.thumbnailUrl,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isLiked
                                      ? AppLocalizations.of(context)
                                          .removedFromFavorites
                                      : AppLocalizations.of(context)
                                          .addedToFavorites),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              song.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            // Artist / Type
            Builder(builder: (context) {
              final loc = AppLocalizations.of(context);
              String categoryText = song.category;
              if (song.category == 'Single') categoryText = loc.single;
              if (song.category == 'Album') categoryText = loc.albumType;
              if (song.category == 'EP') categoryText = loc.epType;
              if (song.category == 'Playlist') categoryText = loc.playlistType;

              final typeLabel = categoryText.isNotEmpty
                  ? categoryText
                  : song.isPlaylist
                      ? loc.playlistType
                      : loc.songType;

              final artistLabel =
                  song.artist == 'Unknown' || song.artist == 'Unknown Artist'
                      ? loc.unknownArtist
                      : song.artist;

              // Avoid "Single • Single" (clean up UI if metadata is poor)
              String text = '$typeLabel • $artistLabel';
              if (typeLabel.toLowerCase() == artistLabel.toLowerCase()) {
                text = typeLabel;
              }

              return Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[400],
                    ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
