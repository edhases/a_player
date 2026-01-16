import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'youtube_helper.dart';
import 'youtube_audio_source.dart';
import 'cache_service.dart';

class AudioSourceFactory {
  final YouTubeHelper _ytHelper;
  final CacheService _cacheService;

  AudioSourceFactory(this._ytHelper, this._cacheService);

  Future<AudioSource> createSource(MediaItem item) async {
    debugPrint('[AudioSourceFactory] Creating AudioSource for ${item.title}');

    // Check if it's an online YouTube track that needs JIT fetching.
    if (item.extras?['isOnline'] == true) {
      final videoId = item.extras!['videoId'] as String;

      // Check cache first
      if (await _cacheService.isCached(videoId)) {
        final path = await _cacheService.getCachedFilePath(videoId);
        if (path != null) {
          debugPrint('[AudioSourceFactory] Playing from cache: $path');
          // Update last played in cache service if needed?
          // Maybe better in AudioHandler when playback starts, but here is fine for now.
          _cacheService.updateLastPlayed(videoId);
          return AudioSource.uri(Uri.file(path), tag: item);
        }
      }

      debugPrint(
          '[AudioSourceFactory] Creating YoutubeAudioSource for videoId: $videoId');
      return YoutubeAudioSource(videoId, _ytHelper, tag: item);
    }

    // Handle content URIs from sources like Android MediaStore.
    if (item.id.startsWith('content://')) {
      debugPrint('[AudioSourceFactory] Source: Content URI: ${item.id}');
      return AudioSource.uri(Uri.parse(item.id), tag: item);
    }

    // Handle direct HTTP URLs
    if (item.id.startsWith('http')) {
      final headers = <String, String>{};

      if (item.extras != null && item.extras!.containsKey('user_agent')) {
        headers['User-Agent'] = item.extras!['user_agent'];
      }

      debugPrint(
          '[AudioSourceFactory] Source: HTTP URL: ${item.id.substring(0, item.id.length > 100 ? 100 : item.id.length)}...');

      return AudioSource.uri(Uri.parse(item.id),
          tag: item, headers: headers.isEmpty ? null : headers);
    }

    // Default to assuming the ID is a local file path.
    debugPrint('[AudioSourceFactory] Source: File path: ${item.id}');
    return AudioSource.uri(Uri.file(item.id), tag: item);
  }
}
