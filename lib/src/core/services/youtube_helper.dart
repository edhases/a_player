import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import '../../data/datasources/app_database.dart';

import 'rate_limiter.dart';

/// YouTube Helper — wrapper навколо YoutubeExplode для управління
/// URL потоків, кешування й отримання метаданих видео
class YouTubeHelper {
  final YoutubeExplode _yt = YoutubeExplode();
  final AppDatabase _db;
  YouTubeHelper(this._db);
  final RateLimiter _rateLimiter = RateLimiter();

  // LRU cache with maximum size limit
  static const int _maxCacheSize = 150;
  final Map<String, _CachedUrl> _urlCache = {};
  final List<String> _cacheOrder = []; // Track access order for LRU

  /// Add to cache with LRU eviction
  void _addToCache(String videoId, _CachedUrl cached) {
    // Remove if already exists to update order
    if (_urlCache.containsKey(videoId)) {
      _cacheOrder.remove(videoId);
    }

    // Evict oldest entries if cache is full
    while (_urlCache.length >= _maxCacheSize && _cacheOrder.isNotEmpty) {
      final oldest = _cacheOrder.removeAt(0);
      _urlCache.remove(oldest);
    }

    _urlCache[videoId] = cached;
    _cacheOrder.add(videoId);
  }

  /// Get from cache and update LRU order
  _CachedUrl? _getFromCache(String videoId) {
    final cached = _urlCache[videoId];
    if (cached != null) {
      // Move to end (most recently used)
      _cacheOrder.remove(videoId);
      _cacheOrder.add(videoId);
    }
    return cached;
  }

  /// Отримати URL для потокування аудіо
  Future<String?> getAudioUrl(String videoId) async {
    try {
      // 1. Check shared cache with LRU access
      final now = DateTime.now();
      final cached = _getFromCache(videoId);
      if (cached != null) {
        if (cached.expiry.isAfter(now)) {
          debugPrint('[YouTubeHelper] using shared cached URL for: $videoId');
          return cached.url;
        } else {
          _urlCache.remove(videoId);
          _cacheOrder.remove(videoId);
        }
      }

      await _rateLimiter.throttle();
      debugPrint('[YouTubeHelper] Getting audio URL for: $videoId');

      // Use youtube_explode_dart with ANDROID_VR and Safari clients
      // These handle signature cipher decryption and PO Token automatically
      final manifest = await _yt.videos.streams.getManifest(
        videoId,
        ytClients: [
          YoutubeApiClient.androidVr,
          YoutubeApiClient.safari,
        ],
      );

      // Smart format selection (prefers Opus/WebM, validates contentLength)
      final audioStream = _selectBestAudioStream(manifest.audioOnly.toList());
      if (audioStream == null) {
        debugPrint('[YouTubeHelper] No valid audio streams found');
        return null;
      }

      final url = audioStream.url.toString();

      debugPrint(
          '[YouTubeHelper] Selected: ${audioStream.codec.subtype} @ ${audioStream.bitrate.kiloBitsPerSecond.toStringAsFixed(0)} kbps');

      // Save to LRU cache (default TTL 45 min)
      _addToCache(
          videoId,
          _CachedUrl(
            url: url,
            expiry: now.add(
                const Duration(minutes: 45)), // slightly less than typical 1h
          ));

      return url;
    } catch (e) {
      debugPrint('[YouTubeHelper] Error getting audio URL: $e');
      return null;
    }
  }

  /// Get audio URL with User-Agent for just_audio header compatibility
  /// Returns a map with 'url' and 'agent' keys, or null on failure
  ///
  /// Uses smart format selection:
  /// - Prefers Opus/WebM over AAC/M4A at similar bitrate (better quality)
  /// - Validates contentLength to avoid corrupted streams
  Future<Map<String, String>?> getAudioUrlWithAgent(String videoId) async {
    try {
      // Check LRU cache first
      final now = DateTime.now();
      final cached = _getFromCache(videoId);
      if (cached != null) {
        if (cached.expiry.isAfter(now)) {
          debugPrint(
              '[YouTubeHelper] using cached URL with agent for: $videoId');
          return {
            'url': cached.url,
            'agent': _androidVrUserAgent,
          };
        } else {
          _urlCache.remove(videoId);
          _cacheOrder.remove(videoId);
        }
      }

      await _rateLimiter.throttle();
      debugPrint('[YouTubeHelper] Getting audio URL with agent for: $videoId');

      // Use youtube_explode_dart with ANDROID_VR client
      // This handles signature cipher decryption and PO Token automatically
      final manifest = await _yt.videos.streams.getManifest(
        videoId,
        ytClients: [
          YoutubeApiClient.androidVr,
          YoutubeApiClient.safari,
        ],
      );

      // Smart format selection
      final audioStream = _selectBestAudioStream(manifest.audioOnly.toList());
      if (audioStream == null) {
        debugPrint('[YouTubeHelper] No valid audio streams found');
        return null;
      }

      final url = audioStream.url.toString();
      final container = audioStream.container.name.toLowerCase(); // webm or mp4
      final codec = audioStream.codec.subtype.toLowerCase();

      debugPrint(
          '[YouTubeHelper] Selected: $codec @ ${audioStream.bitrate.kiloBitsPerSecond.toStringAsFixed(0)} kbps, '
          'container: $container, size: ${audioStream.size.totalMegaBytes.toStringAsFixed(1)} MB');

      // Add to LRU cache
      _addToCache(
          videoId,
          _CachedUrl(
            url: url,
            expiry: now.add(const Duration(minutes: 45)),
          ));

      return {
        'url': url,
        'agent': _androidVrUserAgent,
        'container': container, // webm or mp4 - use for file extension
        'codec': codec, // opus or mp4a
      };
    } catch (e) {
      debugPrint('[YouTubeHelper] Error getting audio URL with agent: $e');
      return null;
    }
  }

  /// Select the best audio stream based on:
  /// 1. Valid contentLength (> 0)
  /// 2. Prefer Opus/WebM over AAC/M4A at similar bitrate tier
  /// 3. Highest bitrate within preferred codec
  AudioOnlyStreamInfo? _selectBestAudioStream(
      List<AudioOnlyStreamInfo> streams) {
    if (streams.isEmpty) return null;

    // Filter out streams with invalid/missing contentLength
    final validStreams = streams.where((s) => s.size.totalBytes > 0).toList();
    if (validStreams.isEmpty) {
      debugPrint(
          '[YouTubeHelper] Warning: No streams with valid contentLength, using all');
      // Fallback to all streams if none have contentLength
      validStreams.addAll(streams);
    }

    // Sort by bitrate descending
    validStreams.sort(
        (a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));

    // Group into bitrate tiers (within 20kbps is considered same tier)
    // Then prefer Opus/WebM within same tier
    final highestBitrate = validStreams.first.bitrate.kiloBitsPerSecond;

    // Get streams in the top tier (within 20% of highest bitrate)
    final topTier = validStreams
        .where((s) => s.bitrate.kiloBitsPerSecond >= highestBitrate * 0.8)
        .toList();

    // Prefer Opus (audio/webm) over AAC (audio/mp4)
    final opusStreams = topTier
        .where((s) =>
            s.codec.subtype.toLowerCase().contains('opus') ||
            s.container.name.toLowerCase() == 'webm')
        .toList();

    if (opusStreams.isNotEmpty) {
      // Return highest bitrate Opus stream
      return opusStreams.first;
    }

    // Fallback to highest bitrate AAC/M4A
    return topTier.first;
  }

  // User-Agent for ANDROID_VR client (matches youtube_explode_dart)
  static const String _androidVrUserAgent =
      'com.google.android.apps.youtube.vr.oculus/1.61.48 '
      '(Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip';

  /// Отримати деталі видео (тривалість, назва тощо)
  Future<Video?> getVideoDetails(String videoId) async {
    try {
      await _rateLimiter.throttle();
      debugPrint('[YouTubeHelper] Getting video details for: $videoId');

      // Спочатку перевірити кеш
      final cached = await getCachedMetadata(videoId);
      if (cached != null) {
        debugPrint('[YouTubeHelper] Using cached data: ${cached.title}');
        // Повернути базову інформацію з кеша (можна створити простий Video об'єкт або повернути дані окремо)
        return await _yt.videos.get(
            videoId); // Тимчасово все ще отримуємо з YouTube для повних даних
      }

      final video = await _yt.videos.get(videoId);
      debugPrint('[YouTubeHelper] Video: ${video.title} (${video.duration})');

      // Кешувати метадані
      final thumbnailUrl = video.thumbnails.highResUrl;
      if (thumbnailUrl.isNotEmpty) {
        await cacheVideoMetadata(
          videoId,
          video.title,
          video.author,
          thumbnailUrl.toString(),
          video.duration?.inSeconds,
        );
      }

      return video;
    } catch (e) {
      debugPrint('[YouTubeHelper] Error getting video details: $e');
      return null;
    }
  }

  /// Отримати відео з YouTube плейлиста
  Future<List<Video>> getPlaylistVideos(String playlistId) async {
    try {
      await _rateLimiter.throttle();
      debugPrint('[YouTubeHelper] Getting playlist videos for: $playlistId');
      final playlist = await _yt.playlists.get(playlistId);
      final videos = await _yt.playlists.getVideos(playlistId).toList();

      debugPrint(
          '[YouTubeHelper] Playlist: ${playlist.title}, videos: ${videos.length}');

      // Кешувати метадані для кожного відео
      for (final video in videos) {
        final thumbnailUrl = video.thumbnails.highResUrl;
        if (thumbnailUrl.isNotEmpty) {
          await cacheVideoMetadata(
            video.id.value,
            video.title,
            video.author,
            thumbnailUrl.toString(),
            video.duration?.inSeconds,
          );
        }
      }

      return videos;
    } catch (e) {
      debugPrint('[YouTubeHelper] Error getting playlist videos: $e');
      return [];
    }
  }

  /// Завантажити аудіо файл локально для офлайн відтворення
  Future<String?> downloadAudio(String videoId,
      {Function(double)? onProgress}) async {
    try {
      await _rateLimiter.throttle();
      debugPrint('[YouTubeHelper] Downloading audio for: $videoId');

      final cached = await getCachedMetadata(videoId);
      if (cached == null) {
        debugPrint('[YouTubeHelper] No cached metadata found for download');
        return null;
      }

      final manifest = await _yt.videos.streams.getManifest(videoId);
      final audioStream = manifest.audioOnly.withHighestBitrate();

      final stream = _yt.videos.streams.get(audioStream);

      // Отримати директорію для завантажень
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final fileName =
          '${cached.title.replaceAll(RegExp(r'[^\w\s]'), '')}_$videoId.mp3';
      final filePath = '${downloadDir.path}/$fileName';
      final file = File(filePath);

      // Завантажити файл з прогресом
      // Завантажити файл з прогресом

      await stream.pipe(file.openWrite());

      debugPrint('[YouTubeHelper] Downloaded to: $filePath');

      // Оновити кеш з шляхом до файлу
      await _db.updateDownloadPath(videoId, filePath);

      return filePath;
    } catch (e) {
      debugPrint('[YouTubeHelper] Error downloading audio: $e');
      return null;
    }
  }

  /// Видалити завантажений файл
  Future<bool> deleteDownloadedAudio(String videoId) async {
    try {
      final cached = await getCachedMetadata(videoId);
      if (cached != null && cached.downloadPath != null) {
        final file = File(cached.downloadPath!);
        if (await file.exists()) {
          await file.delete();
          // Оновити кеш
          await _db.updateDownloadPath(videoId, null);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('[YouTubeHelper] Error deleting downloaded audio: $e');
      return false;
    }
  }

  /// Перевірити чи файл доступний офлайн
  Future<String?> getLocalFilePath(String videoId) async {
    try {
      final cached = await getCachedMetadata(videoId);
      if (cached != null && cached.downloadPath != null) {
        final file = File(cached.downloadPath!);
        if (await file.exists()) {
          return cached.downloadPath;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[YouTubeHelper] Error getting local file path: $e');
      return null;
    }
  }

  /// Кешувати метаполучення YouTube трека
  Future<void> cacheVideoMetadata(String videoId, String title, String artist,
      String thumbnailUrl, int? duration) async {
    try {
      debugPrint('[YouTubeHelper] Caching metadata for: $videoId');

      await _db.upsertYouTubeTrack(YouTubeTrack(
        videoId: videoId,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        duration: duration ?? 0,
        downloadPath: null,
        lastPlayed: null,
        cachedAt: DateTime.now(),
        isFavorite: false,
        pendingCache: false,
      ));

      debugPrint('[YouTubeHelper] Metadata cached successfully');
    } catch (e) {
      debugPrint('[YouTubeHelper] Error caching metadata: $e');
    }
  }

  /// Отримати кешовані метадані
  Future<YouTubeTrack?> getCachedMetadata(String videoId) async {
    try {
      final result = await _db.getYouTubeTrack(videoId);
      return result;
    } catch (e) {
      debugPrint('[YouTubeHelper] Error getting cached metadata: $e');
      return null;
    }
  }

  /// Отримати thumbnail URL для відео
  Future<String?> getThumbnailUrl(String videoId) async {
    try {
      // Спочатку перевірити кеш
      final cached = await getCachedMetadata(videoId);
      if (cached != null && cached.thumbnailUrl.isNotEmpty) {
        return cached.thumbnailUrl;
      }

      // Якщо немає в кеші, отримати з YouTube
      final video = await _yt.videos.get(videoId);
      final thumbnailUrl = video.thumbnails.highResUrl;
      if (thumbnailUrl.isNotEmpty) {
        // Кешувати метадані
        await cacheVideoMetadata(
          videoId,
          video.title,
          video.author,
          thumbnailUrl.toString(),
          video.duration?.inSeconds,
        );
        return thumbnailUrl.toString();
      }

      return null;
    } catch (e) {
      debugPrint('[YouTubeHelper] Error getting thumbnail: $e');
      return null;
    }
  }

  /// Створити чергу відтворення з YouTube плейлиста
  Future<List<MediaItem>> createPlaylistQueue(String playlistId) async {
    try {
      debugPrint('[YouTubeHelper] Creating playlist queue for: $playlistId');
      final videos = await getPlaylistVideos(playlistId);

      // Create all MediaItems in parallel to avoid blocking the UI.
      final mediaItemFutures = videos
          .map((video) => createMediaItem(
                video.id.value,
                customTitle: video.title,
                customArtist: video.author,
                customDuration: video.duration,
                customThumbnail: video.thumbnails.highResUrl,
              ))
          .toList();

      final mediaItems = await Future.wait(mediaItemFutures);

      debugPrint(
          '[YouTubeHelper] Created ${mediaItems.length} media items from playlist');
      return mediaItems;
    } catch (e) {
      debugPrint('[YouTubeHelper] Error creating playlist queue: $e');
      return [];
    }
  }

  /// Create a MediaItem from a YouTube video ID
  Future<MediaItem> createMediaItem(
    String videoId, {
    String? customTitle,
    String? customArtist,
    Duration? customDuration,
    String? customThumbnail,
    Map<String, dynamic>? extras,
    String? cachedUrl, // New parameter
  }) async {
    try {
      // Спочатку перевірити кеш
      var cached = await getCachedMetadata(videoId);

      // Якщо немає в кеші, але передані кастомні дані - використовуємо їх
      if (cached == null &&
          customTitle != null &&
          customArtist != null &&
          customThumbnail != null) {
        // Кешуємо отримані дані
        await cacheVideoMetadata(
          videoId,
          customTitle,
          customArtist,
          customThumbnail,
          customDuration?.inSeconds,
        );
        // Не перечитуємо з бази, створюємо об'єкт з того що є
      } else if (cached == null) {
        // Якщо немає в кеші і немає кастомних даних - тягнемо з YouTube
        final video = await _yt.videos.get(videoId);
        final thumbnailUrl = video.thumbnails.highResUrl;
        if (thumbnailUrl.isNotEmpty) {
          await cacheVideoMetadata(
            videoId,
            video.title,
            video.author,
            thumbnailUrl.toString(),
            video.duration?.inSeconds,
          );
          cached = await getCachedMetadata(videoId);
        }
      }

      // Формуємо фінальні дані (пріоритет: кастом -> кеш -> unknown)
      final title = customTitle ?? cached?.title ?? 'Unknown Title';
      final artist = customArtist ?? cached?.artist ?? 'Unknown Artist';
      final duration =
          customDuration ?? Duration(seconds: cached?.duration ?? 0);
      final artUri = Uri.parse(customThumbnail ?? cached?.thumbnailUrl ?? '');

      // Перевірити чи є локальний файл
      final localPath = await getLocalFilePath(videoId);
      final mediaId = localPath ?? videoId;

      final desktopUA =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36';

      final finalExtras = <String, dynamic>{
        'isOnline': localPath == null,
        'videoId': videoId,
        'user_agent': desktopUA,
        'cachedUrl': cachedUrl, // Ensure cachedUrl is passed to extras
      };

      if (extras != null) {
        finalExtras.addAll(extras);
      }

      return MediaItem(
        id: mediaId,
        title: title,
        artist: artist,
        duration: duration,
        artUri: artUri,
        extras: finalExtras,
      );
    } catch (e) {
      debugPrint('[YouTubeHelper] Error creating MediaItem: $e');
      return MediaItem(
        id: videoId,
        title: customTitle ?? 'Error',
        artist: customArtist ?? 'Error',
      );
    }
  }
}

class _CachedUrl {
  final String url;
  final DateTime expiry;

  _CachedUrl({required this.url, required this.expiry});
}
