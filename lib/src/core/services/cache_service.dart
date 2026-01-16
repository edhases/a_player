import 'dart:io';
import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../data/models/cached_track.dart';
import '../services/recommendation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'settings_service.dart';

class CacheService {
  final RecommendationService _recommendationService;
  late final Isar _isar;
  final Dio _dio = Dio();

  // Default max cache size: 500MB
  static const int _defaultMaxCacheSize = 500 * 1024 * 1024;
  int _maxCacheSize = _defaultMaxCacheSize;

  CacheService(this._recommendationService);

  Future<void> init() async {
    if (_recommendationService.isar != null) {
      _isar = _recommendationService.isar!;
    }
    // Load max cache size
    if (GetIt.I.isRegistered<SettingsService>()) {
      _maxCacheSize = GetIt.I<SettingsService>().loadMaxCacheSize();
    }
  }

  Future<void> setMaxCacheSize(int bytes) {
    _maxCacheSize = bytes;
    return checkCacheSpace(0); // Clean up if new limit is smaller
  }

  Future<bool> isCached(String videoId) async {
    final track =
        await _isar.cachedTracks.filter().videoIdMatches(videoId).findFirst();
    if (track != null) {
      final file = File(track.filePath);
      if (await file.exists()) return true;
      // If file missing but record exists, clean up
      await _isar.writeTxn(() async {
        await _isar.cachedTracks.delete(track.id);
      });
    }
    return false;
  }

  Future<String?> getCachedFilePath(String videoId) async {
    final track =
        await _isar.cachedTracks.filter().videoIdMatches(videoId).findFirst();
    return track?.filePath;
  }

  Future<void> cacheTrack({
    required String videoId,
    required String url,
    required String title,
    required String artist,
    required String thumbnailUrl,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(dir.path, 'songs_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    // Temporary path
    final tempPath = p.join(cacheDir.path, '$videoId.tmp');
    final finalPath = p.join(cacheDir.path, '$videoId.mp3');

    // Check space
    // We don't know exact size yet, assume 10MB safety margin or separate HEAD request?
    // Let's just run cleanup logic first.
    await checkCacheSpace(10 * 1024 * 1024);

    try {
      await _dio.download(url, tempPath);
      final file = File(tempPath);
      final fileSize = await file.length();

      await file.rename(finalPath);

      await _isar.writeTxn(() async {
        // Remove existing if re-downloading
        await _isar.cachedTracks.filter().videoIdMatches(videoId).deleteAll();

        final cachedTrack = CachedTrack()
          ..videoId = videoId
          ..filePath = finalPath
          ..fileSize = fileSize
          ..lastPlayedAt = DateTime.now()
          ..title = title
          ..artist = artist
          ..thumbnailUrl = thumbnailUrl;

        await _isar.cachedTracks.put(cachedTrack);
      });

      debugPrint('Track cached: $title ($fileSize bytes)');
    } catch (e) {
      debugPrint('Error caching track: $e');
      if (await File(tempPath).exists()) {
        await File(tempPath).delete();
      }
      rethrow;
    }
  }

  Future<void> checkCacheSpace(int newFileSize) async {
    final allTracks =
        await _isar.cachedTracks.where().sortByLastPlayedAt().findAll();
    var currentSize = allTracks.fold<int>(0, (sum, t) => sum + t.fileSize);

    if (currentSize + newFileSize <= _maxCacheSize) return;

    debugPrint('Cache space low. Cleaning up...');

    // Delete oldest until space fits
    for (var track in allTracks) {
      if (currentSize + newFileSize <= _maxCacheSize) break;

      final file = File(track.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      await _isar.writeTxn(() async {
        await _isar.cachedTracks.delete(track.id);
      });

      currentSize -= track.fileSize;
      debugPrint('Deleted cached track: ${track.title}');
    }
  }

  Future<void> updateLastPlayed(String videoId) async {
    final track =
        await _isar.cachedTracks.filter().videoIdMatches(videoId).findFirst();
    if (track != null) {
      await _isar.writeTxn(() async {
        track.lastPlayedAt = DateTime.now();
        await _isar.cachedTracks.put(track);
      });
    }
  }

  Future<void> clearCache() async {
    final allTracks = await _isar.cachedTracks.where().findAll();
    for (var track in allTracks) {
      final file = File(track.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _isar.writeTxn(() async {
      await _isar.cachedTracks.clear();
    });
  }

  Future<int> getCacheUsage() async {
    if (_recommendationService.isar == null) return 0;
    final allTracks = await _isar.cachedTracks.where().findAll();
    return allTracks.fold<int>(0, (sum, t) => sum + t.fileSize);
  }

  Future<List<CachedTrack>> getCachedTracks() async {
    if (_recommendationService.isar == null) return [];
    return await _isar.cachedTracks.where().sortByLastPlayedAtDesc().findAll();
  }

  Future<void> deleteCachedTrack(int id) async {
    final track = await _isar.cachedTracks.get(id);
    if (track != null) {
      final file = File(track.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await _isar.writeTxn(() async {
        await _isar.cachedTracks.delete(id);
      });
    }
  }
}
