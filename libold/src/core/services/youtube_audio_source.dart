import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../data/datasources/app_database.dart';

/// YouTubeAudioSource - управління завантаженням та потоковою передачею YouTube аудіо
class YouTubeAudioSource {
  final AppDatabase _db;
  final YoutubeExplode _yt;

  YouTubeAudioSource(this._db) : _yt = YoutubeExplode();

  /// Скачує аудіо трек для офлайн програвання
  Future<bool> downloadTrack(String videoId, String title) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${appDir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create();
      }
      
      final fileName = '${videoId}.opus';
      final file = File('${downloadsDir.path}/$fileName');
      
      // Перевірка чи файл вже існує
      if (await file.exists()) {
        debugPrint('[YouTubeAudioSource] File already exists: ${file.path}');
        return true;
      }
      
      debugPrint('[YouTubeAudioSource] Downloading: $title');
      final manifest = await _yt.videos.streams.getManifest(videoId);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      
      if (audioStream == null) {
        debugPrint('[YouTubeAudioSource] No audio stream found');
        return false;
      }

      // Створити вихідний файл та записувати в нього потік
      final fileStream = file.openWrite();
      await _yt.videos.streams.get(audioStream).pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();
      
      debugPrint('[YouTubeAudioSource] Successfully downloaded: $title -> ${file.path}');
      return true;
    } catch (e) {
      debugPrint('[YouTubeAudioSource] Error downloading track $videoId: $e');
      return false;
    }
  }
  
  /// Повертає шлях до локального файлу, якщо доступно, або null
  Future<String?> getLocalFilePath(String videoId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${videoId}.opus';
      final file = File('${appDir.path}/downloads/$fileName');
      
      if (await file.exists()) {
        debugPrint('[YouTubeAudioSource] Found local file: ${file.path}');
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('[YouTubeAudioSource] Error getting local file path: $e');
      return null;
    }
  }

  /// Закрити YoutubeExplode
  void dispose() {
    _yt.close();
  }
}
