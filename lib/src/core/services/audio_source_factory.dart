import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'youtube_helper.dart';
import 'youtube_audio_source.dart';
import 'cache_service.dart';

class AudioSourceFactory {
  final YouTubeHelper _ytHelper;
  final CacheService _cacheService;
  final http.Client _httpClient = http.Client();

  AudioSourceFactory(this._ytHelper, this._cacheService);

  Future<AudioSource> createSource(MediaItem item) async {
    debugPrint('[AudioSourceFactory] Creating AudioSource for ${item.title}');

    // Check if it's an online YouTube track that needs JIT fetching.
    if (item.extras?['isOnline'] == true) {
      // If it is a radio station, it uses direct URL, so skip YouTube logic
      if (item.extras?['isRadio'] == true) {
        return AudioSource.uri(Uri.parse(item.id), tag: item);
      }

      final videoId = item.extras!['videoId'] as String;

      // 0. Check for pre-resolved cachedUrl (e.g. from Search)
      if (item.extras?['cachedUrl'] != null) {
        final cachedUrl = item.extras!['cachedUrl'] as String;
        debugPrint(
            '[AudioSourceFactory] Using pre-resolved cached URL for $videoId');
        final headers = <String, String>{};
        if (item.extras?['user_agent'] != null) {
          headers['User-Agent'] = item.extras!['user_agent'];
        }
        return AudioSource.uri(Uri.parse(cachedUrl),
            tag: item, headers: headers.isEmpty ? null : headers);
      }

      // Check cache first
      final isCached = await _cacheService.isCached(videoId);
      debugPrint('[AudioSourceFactory] Cache check for $videoId: $isCached');

      if (isCached) {
        final path = await _cacheService.getCachedFilePath(videoId);
        debugPrint('[AudioSourceFactory] Cache path: $path');

        if (path != null) {
          final file = File(path); // Use dart:io File
          if (await file.exists()) {
            debugPrint('[AudioSourceFactory] Playing from cache: $path');
            _cacheService.updateLastPlayed(videoId);
            return AudioSource.uri(Uri.file(path), tag: item);
          } else {
            debugPrint(
                '[AudioSourceFactory] File NOT found at: $path (despite canCached=true?)');
          }
        }
      }

      debugPrint(
          '[AudioSourceFactory] Creating YoutubeAudioSource for videoId: $videoId');
      final ytSource = YoutubeAudioSource(videoId, _ytHelper,
          tag: item, client: _httpClient);

      // NOTE: Automatic prefetch is disabled here to prevent connection storms.
      // Sequential prefetching is now handled by PrefetchManager.
      // ytSource.prefetch();

      return ytSource;
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

  void dispose() {
    _httpClient.close();
  }
}
