import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import '../../data/datasources/app_database.dart';
import 'package:drift/drift.dart';
import 'google_auth_service.dart'; // Import the GoogleAuthService
import 'package:get_it/get_it.dart';
import 'rate_limiter.dart';

/// YouTube Helper — wrapper навколо YoutubeExplode для управління
/// URL потоків, кешування й отримання метаданих видео
class YouTubeHelper {
  final YoutubeExplode _yt = YoutubeExplode();
  final AppDatabase _db;
  final GoogleAuthService? _authService; // Optional reference to GoogleAuthService
  final RateLimiter _rateLimiter = RateLimiter();

  YouTubeHelper(this._db, {GoogleAuthService? authService}) 
      : _authService = authService ?? GetIt.I<GoogleAuthService>();

  /// Отримати URL для потокування аудіо
  Future<String?> getAudioUrl(String videoId) async {
    try {
      await _rateLimiter.throttle();
      debugPrint('[YouTubeHelper] Getting audio URL for: $videoId');

      // Отримати маніфест потоків з multi-client strategy
      final manifest = await _yt.videos.streams.getManifest(
        videoId,
        ytClients: [
          YoutubeApiClient.androidVr,
          YoutubeApiClient.safari,
          YoutubeApiClient.tvSimplyEmbedded,
        ],
      );

      // Вибрати найкращий аудіопотік за бітрейтом
      final audioStream = manifest.audioOnly.withHighestBitrate();
      if (audioStream != null) {
        debugPrint('[YouTubeHelper] Found audio stream: ${audioStream.bitrate} bps');
        return audioStream.url.toString();
      }

      debugPrint('[YouTubeHelper] No audio stream found for: $videoId');
      return null;
    } catch (e) {
      debugPrint('[YouTubeHelper] Error getting audio URL: $e');
      return null;
    }
  }

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
        return await _yt.videos.get(videoId); // Тимчасово все ще отримуємо з YouTube для повних даних
      }

      final video = await _yt.videos.get(videoId);
      debugPrint('[YouTubeHelper] Video: ${video.title} (${video.duration})');

      // Кешувати метадані
      final thumbnailUrl = video.thumbnails.highResUrl ?? video.thumbnails.mediumResUrl ?? video.thumbnails.lowResUrl;
      if (thumbnailUrl != null) {
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

      debugPrint('[YouTubeHelper] Playlist: ${playlist.title}, videos: ${videos.length}');

      // Кешувати метадані для кожного відео
      for (final video in videos) {
        final thumbnailUrl = video.thumbnails.highResUrl ?? video.thumbnails.mediumResUrl ?? video.thumbnails.lowResUrl;
        if (thumbnailUrl != null) {
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
  Future<String?> downloadAudio(String videoId, {Function(double)? onProgress}) async {
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

      if (audioStream == null) return null;

      final stream = _yt.videos.streams.get(audioStream);

      // Отримати директорію для завантажень
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final fileName = '${cached.title.replaceAll(RegExp(r'[^\w\s]'), '')}_${videoId}.mp3';
      final filePath = '${downloadDir.path}/$fileName';
      final file = File(filePath);

      // Завантажити файл з прогресом
      final streamLength = audioStream.size.totalBytes;
      var downloadedBytes = 0;

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
  Future<void> cacheVideoMetadata(String videoId, String title, String artist, String thumbnailUrl, int? duration) async {
    try {
      debugPrint('[YouTubeHelper] Caching metadata for: $videoId');

      await _db.upsertYouTubeTrack(
        YouTubeTrack(
          videoId: videoId,
          title: title,
          artist: artist,
          thumbnailUrl: thumbnailUrl,
          duration: duration ?? 0,
          downloadPath: null,
          lastPlayed: null,
          cachedAt: DateTime.now(),
        )
      );

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
      final thumbnailUrl = video.thumbnails.highResUrl ?? video.thumbnails.mediumResUrl ?? video.thumbnails.lowResUrl;

      if (thumbnailUrl != null) {
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
      final mediaItemFutures = videos.map((video) =>
        createMediaItem(video.id.value, customTitle: video.title, customArtist: video.author)
      ).toList();

      final mediaItems = await Future.wait(mediaItemFutures);

      debugPrint('[YouTubeHelper] Created ${mediaItems.length} media items from playlist');
      return mediaItems;
    } catch (e) {
      debugPrint('[YouTubeHelper] Error creating playlist queue: $e');
      return [];
    }
  }

  /// Create a MediaItem from a YouTube video ID
  Future<MediaItem> createMediaItem(String videoId, {String? customTitle, String? customArtist}) async {
    try {
      // Спочатку перевірити кеш
      var cached = await getCachedMetadata(videoId);

      if (cached == null) {
        // Якщо немає в кеші, отримати дані з YouTube
        final video = await _yt.videos.get(videoId);
        final thumbnailUrl = video.thumbnails.highResUrl ?? video.thumbnails.mediumResUrl ?? video.thumbnails.lowResUrl;

        if (thumbnailUrl != null) {
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

      if (cached != null) {
        // Перевірити чи є локальний файл для офлайн відтворення
        final localPath = await getLocalFilePath(videoId);
        // Для JIT-фетчингу, ID медіа-елемента - це videoId для онлайн-треків
        // або шлях до файлу для офлайн-треків.
        final mediaId = localPath ?? videoId;

        final desktopUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36';

        return MediaItem(
          id: mediaId,
          title: customTitle ?? cached.title,
          artist: customArtist ?? cached.artist,
          duration: Duration(seconds: cached.duration),
          artUri: Uri.parse(cached.thumbnailUrl),
          extras: {
            'isOnline': localPath == null,
            'videoId': videoId,
            'user_agent': desktopUA,
          },
        );
      }

      // Fallback якщо немає кеша
      return MediaItem(
        id: videoId,
        title: customTitle ?? 'Unknown Title',
        artist: customArtist ?? 'Unknown Artist',
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