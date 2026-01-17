import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/youtube_song.dart';
import 'common_artwork.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/youtube_helper.dart';
import '../../core/utils/localization.dart';

import '../../core/services/audio_handler.dart';

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
    final audioHandler = GetIt.I<MyAudioHandler>();
    final isLiked = await GetIt.I<FavoritesService>().isLiked(song.videoId);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: song.thumbnailUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(song.artist),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(AppLocalizations.of(context).addToQueue),
                onTap: () {
                  audioHandler.addYouTubeToQueue(song);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(AppLocalizations.of(context).queueAdded),
                        duration: const Duration(seconds: 1)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: Text(AppLocalizations.of(context).download),
                onTap: () async {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            AppLocalizations.of(context).startingDownload)),
                  );
                  try {
                    final ytHelper = GetIt.I<YouTubeHelper>();
                    final url = await ytHelper.getAudioUrl(song.videoId);
                    if (url != null) {
                      await GetIt.I<CacheService>().cacheTrack(
                        videoId: song.videoId,
                        url: url,
                        title: song.title,
                        artist: song.artist,
                        thumbnailUrl: song.thumbnailUrl,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppLocalizations.of(context)
                                  .translate('downloaded',
                                      args: {'title': song.title}))),
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
                            content: Text(AppLocalizations.of(context)
                                .translate('download_error',
                                    args: {'error': e}))),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                title: Text(isLiked
                    ? AppLocalizations.of(context).removeFromFavorites
                    : AppLocalizations.of(context).addToFavorites),
                onTap: () {
                  GetIt.I<FavoritesService>().toggleFavorite(
                    videoId: song.videoId,
                    title: song.title,
                    artist: song.artist,
                    thumbnailUrl: song.thumbnailUrl,
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Hero(
                        tag: 'artwork-${song.videoId}',
                        child: CommonArtwork(
                          // Assuming CommonArtwork is improved or using CachedNetworkImage directly if CommonArtwork not suitable for stack filling context, but CommonArtwork should be fine if it fits.
                          // Actually CommonArtwork usually has fixed size. Let's use CachedNetworkImage directly or ensure CommonArtwork fits.
                          // CommonArtwork takes `size` and `url`.
                          // Previous code used CommonArtwork(url: song.thumbnailUrl, size: 150).
                          url: song.thumbnailUrl,
                          size: 150,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: StreamBuilder<bool>(
                      stream: GetIt.I<FavoritesService>()
                          .isLikedStream(song.videoId),
                      builder: (context, snapshot) {
                        final isLiked = snapshot.data ?? false;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: 20,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
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
            const SizedBox(height: 8),
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
