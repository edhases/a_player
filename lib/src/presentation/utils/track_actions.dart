import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/youtube_helper.dart';
import '../../core/utils/localization.dart';
import '../../core/theme/app_theme.dart';
import '../pages/settings_screen.dart';

class TrackActions {
  /// Handles the Like button press: toggles favorite status and initiates caching if needed.
  static Future<void> handleLikeButton(
    BuildContext context, {
    required String videoId,
    required String title,
    required String artist,
    required String thumbnailUrl,
    bool? currentLikeStatus,
  }) async {
    final favoritesService = GetIt.I<FavoritesService>();
    final cacheService = GetIt.I<CacheService>();

    // 1. Toggle Favorite
    // If we don't know the status, we can check a stream or just toggle.
    // However, for the UI feedback we usually want to know if we are Adding or Removing.
    // FavoritesService.toggleFavorite logic flips the status.

    // We can assume if we are calling this, we want to toggle.
    await favoritesService.toggleFavorite(
      videoId: videoId,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
    );

    // Check new status
    final isLiked = await favoritesService.isLiked(videoId);
    final loc = AppLocalizations.of(context);

    // Show SnackBar
    if (context.mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(isLiked ? loc.addedToFavorites : loc.removedFromFavorites),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // 2. If Liked, handling Caching (only if auto-cache is enabled)
    if (isLiked) {
      // Check if auto-cache for liked songs is enabled
      final settingsService = GetIt.I<SettingsService>();
      if (!settingsService.loadAutoCacheLiked()) {
        return; // Auto-cache disabled, skip caching
      }

      // Check if already cached (downloaded)
      final isCached = await cacheService.isCached(videoId);
      if (isCached) return;

      // Check space (Estimate 5MB per song? Or check exact if possible?)
      // We don't know the size yet. Average 128kbps 3min song ~ 3-4MB. Safe bet 10MB.
      const estimatedSize = 10 * 1024 * 1024;
      final hasSpace = await cacheService.hasSufficientSpace(estimatedSize);

      if (hasSpace) {
        // Cache silently
        _performCache(context, videoId, title, artist, thumbnailUrl);
      } else {
        if (context.mounted) {
          _showCacheFullDialog(context, videoId, title, artist, thumbnailUrl);
        }
      }
    }
  }

  static Future<void> _performCache(
    BuildContext context,
    String videoId,
    String title,
    String artist,
    String thumbnail,
  ) async {
    try {
      final ytHelper = GetIt.I<YouTubeHelper>();
      final audioData = await ytHelper.getAudioUrlWithAgent(videoId);

      if (audioData != null) {
        await GetIt.I<CacheService>().cacheTrack(
          videoId: videoId,
          url: audioData['url']!,
          title: title,
          artist: artist,
          thumbnailUrl: thumbnail,
          container: audioData['container'],
        );
      }
    } catch (e) {
      debugPrint('Auto-cache failed for $videoId: $e');
      if (context.mounted) {
        // Check for disk space error
        String errorMsg = 'Failed to cache track';
        if (e.toString().contains('No space left on device') ||
            (e is FileSystemException && e.osError?.errorCode == 28)) {
          errorMsg = 'Device storage is full!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  static void _showCacheFullDialog(
    BuildContext context,
    String videoId,
    String title,
    String artist,
    String thumbnail,
  ) {
    final loc = AppLocalizations.of(context);
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.sheetBackground,
        title: Text(loc.translate('cache_full_title'),
            style: TextStyle(color: colors.textPrimary)),
        content: Text(loc.translate('cache_full_message'),
            style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.translate('dont_cache'),
                style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Navigate to Settings -> Cache
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));

              // Retry caching if space was freed/increased
              if (context.mounted) {
                const estimatedSize = 10 * 1024 * 1024;
                final cacheService = GetIt.I<CacheService>();
                final hasSpace =
                    await cacheService.hasSufficientSpace(estimatedSize);

                if (hasSpace && context.mounted) {
                  _performCache(context, videoId, title, artist, thumbnail);
                }
              }
            },
            child: Text(loc.ok,
                style:
                    TextStyle(color: colors.textPrimary)), // "OK" or "Increase"
          ),
        ],
      ),
    );
  }
}
