import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import '../../data/datasources/app_database.dart';
import 'google_auth_service.dart';

class RateLimiter {
  Future<void> throttle() async {
    // Simple throttle: wait 100ms
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

/// Helper for managing YouTube URL extraction, caching, and downloads.
/// Combines functionality from old YouTubeService and YouTubeHelper.
class YouTubeHelper {
  final YoutubeExplode _yt = YoutubeExplode();
  final AppDatabase _db;
  final GoogleAuthService _authService;
  final RateLimiter _rateLimiter = RateLimiter();

  YouTubeHelper(this._db, {GoogleAuthService? authService})
      : _authService = authService ?? GetIt.I<GoogleAuthService>();

  /// Get audio URL for streaming
  Future<String?> getAudioUrl(String videoId) async {
    try {
      await _rateLimiter.throttle();
      debugPrint('[YouTubeHelper] Getting audio URL for: $videoId');

      final manifest = await _yt.videos.streams.getManifest(videoId);
      final audioStream = manifest.audioOnly.withHighestBitrate();

      if (audioStream != null) {
        return audioStream.url.toString();
      }
      return null;
    } catch (e) {
      debugPrint('[YouTubeHelper] Error getting audio URL: $e');
      return null;
    }
  }

  /// Create MediaItem from YouTube ID
  Future<MediaItem> createMediaItem(String videoId,
      {String? customTitle, String? customArtist}) async {
    try {
      Video? video;
      try {
        video = await _yt.videos.get(videoId);
      } catch (e) {
        // Ignore fetch error
      }

      final title = customTitle ?? video?.title ?? 'Unknown Title';
      final artist = customArtist ?? video?.author ?? 'Unknown Artist';
      final duration = video?.duration;
      final artUri = video?.thumbnails.mediumResUrl;

      return MediaItem(
        id: videoId,
        title: title,
        artist: artist,
        duration: duration,
        artUri: artUri != null ? Uri.parse(artUri) : null,
        extras: {
          'isOnline': true,
          'videoId': videoId,
        },
      );
    } catch (e) {
      return MediaItem(
        id: videoId,
        title: customTitle ?? 'Error',
        artist: customArtist ?? 'Error',
      );
    }
  }

  /// Search for videos (wrapper for basic search if needed)
  Future<List<MediaItem>> search(String query) async {
    try {
      final results = await _yt.search.search(query);
      return results
          .map((video) => MediaItem(
                id: video.id.value,
                title: video.title,
                artist: video.author,
                artUri: Uri.parse(video.thumbnails.mediumResUrl),
                duration: video.duration,
                extras: {
                  'isNetwork': true,
                  'url': video.url,
                },
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
