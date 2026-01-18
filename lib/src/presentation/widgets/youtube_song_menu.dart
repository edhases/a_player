import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/youtube_song.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/audio_handler.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/youtube_helper.dart';
import '../../core/utils/localization.dart';
import '../pages/playlist_tracks_screen.dart';

/// Reusable bottom sheet menu for YouTubeSong actions.
///
/// Provides a unified context menu with:
/// - Add to Queue
/// - Download
/// - Toggle Favorite
class YouTubeSongMenu extends StatelessWidget {
  final YouTubeSong song;
  final bool isLiked;

  const YouTubeSongMenu({
    super.key,
    required this.song,
    required this.isLiked,
  });

  /// Shows the context menu as a modal bottom sheet.
  ///
  /// This is the primary entry point for displaying the menu.
  static Future<void> show(BuildContext context, YouTubeSong song) async {
    // Use videoId directly - consistency with Player and Home Feed
    // Local tracks should keep 'local:' prefix in database to match playback logic
    final isLiked = await GetIt.I<FavoritesService>().isLiked(song.videoId);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => YouTubeSongMenu(song: song, isLiked: isLiked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = GetIt.I<MyAudioHandler>();
    final loc = AppLocalizations.of(context);

    // Use videoId directly
    final videoId = song.videoId;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Song header
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey[800],
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note),
                ),
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

          // Contextual Actions based on item type
          if (song.isPlaylist ||
              song.category == 'Artist' ||
              song.category == 'Album' ||
              song.category == 'Playlist') ...[
            // For playlists/artists/albums -> Show "Open" action
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(loc.open),
              onTap: () {
                // Determine navigation logic
                Navigator.pop(context);
                final playlistId = song.playlistId ?? song.videoId;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaylistTracksScreen(
                      playlistId: playlistId,
                      title: song.title,
                      knownArtist: song.artist,
                      knownThumbnail: song.thumbnailUrl,
                    ),
                  ),
                );
              },
            ),
          ] else ...[
            // For Songs -> Show Queue, Download, Favorite

            // Add to Queue
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(loc.addToQueue),
              onTap: () {
                audioHandler.addYouTubeToQueue(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.queueAdded),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),

            // Download
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(loc.download),
              onTap: () => _handleDownload(context),
            ),

            // Toggle Favorite
            StreamBuilder<bool>(
              stream: GetIt.I<FavoritesService>().isLikedStream(videoId),
              builder: (context, snapshot) {
                final isLiked = snapshot.data ?? false;
                debugPrint(
                    '[YouTubeSongMenu] Stream update: videoId=$videoId, isLiked=$isLiked');
                return ListTile(
                  leading: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color:
                        isLiked ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(
                      isLiked ? loc.removeFromFavorites : loc.addToFavorites),
                  onTap: () {
                    GetIt.I<FavoritesService>().toggleFavorite(
                      videoId: videoId,
                      title: song.title,
                      artist: song.artist,
                      thumbnailUrl: song.thumbnailUrl,
                    );
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.startingDownload)),
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
              content: Text(
                loc.translate('downloaded', args: {'title': song.title}),
              ),
            ),
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
            content: Text(
              loc.translate('download_error', args: {'error': e}),
            ),
          ),
        );
      }
    }
  }
}
