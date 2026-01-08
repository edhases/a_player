import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../data/datasources/app_database.dart';

/// YouTube Helper — wrapper навколо YoutubeExplode для управління
/// URL потоків, кешування й отримання метаданих видео
class YouTubeHelper {
  final YoutubeExplode _yt = YoutubeExplode();
  final AppDatabase _db;

  YouTubeHelper(this._db);

  /// Отримати URL для потокування аудіо
  Future<String?> getAudioUrl(String videoId) async {
    try {
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
      debugPrint('[YouTubeHelper] Getting video details for: $videoId');
      final video = await _yt.videos.get(videoId);
      debugPrint('[YouTubeHelper] Video: ${video.title} (${video.duration})');
      return video;
    } catch (e) {
      debugPrint('[YouTubeHelper] Error getting video details: $e');
      return null;
    }
  }

  /// Отримати локальний шлях до файлу, якщо доступно
  Future<String?> getLocalFilePath(String videoId) async {
    try {
      // Просто повертаємо null тут, оскільки офлайн завантаження є окремою функцією
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
      // Тут можна зберегти до бази даних YouTube треків, якщо потрібно
    } catch (e) {
      debugPrint('[YouTubeHelper] Error caching metadata: $e');
    }
  }

  /// Закрити YoutubeExplode
  void dispose() {
    _yt.close();
  }
}
