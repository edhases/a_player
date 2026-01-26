import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../data/datasources/app_database.dart';
// import '../services/recommendation_service.dart'; // Removed
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'settings_service.dart';

class CacheService {
  final AppDatabase _db = GetIt.I<AppDatabase>();
  final Dio _dio = Dio();

  // Default max cache size: 500MB
  static const int _defaultMaxCacheSize = 500 * 1024 * 1024;
  int _maxCacheSize = _defaultMaxCacheSize;

  CacheService();

  Future<void> init() async {
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
    final track = await (_db.select(_db.youTubeTracks)
          ..where((t) => t.videoId.equals(videoId)))
        .getSingleOrNull();

    if (track != null && track.downloadPath != null) {
      final file = File(track.downloadPath!);
      if (await file.exists()) return true;

      // If file missing but record exists, clean up path
      await (_db.update(_db.youTubeTracks)
            ..where((t) => t.videoId.equals(videoId)))
          .write(const YouTubeTracksCompanion(
              downloadPath: Value(null), fileSize: Value(null)));
    }
    return false;
  }

  Future<String?> getCachedFilePath(String videoId) async {
    final track = await (_db.select(_db.youTubeTracks)
          ..where((t) => t.videoId.equals(videoId)))
        .getSingleOrNull();
    return track?.downloadPath;
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
    // await checkCacheSpace(10 * 1024 * 1024); // Removed fixed size check

    try {
      bool spaceChecked = false;
      await _dio.download(
        url,
        tempPath,
        onReceiveProgress: (received, total) async {
          if (!spaceChecked && total > 0) {
            spaceChecked = true;
            await checkCacheSpace(total);
          }
        },
      );
      final file = File(tempPath);
      final fileSize = await file.length();

      // Fallback check if total was 0 during download
      if (!spaceChecked) {
        await checkCacheSpace(fileSize);
      }

      await file.rename(finalPath);

      // Upsert in Drift
      await _db.into(_db.youTubeTracks).insertOnConflictUpdate(
            YouTubeTracksCompanion(
              videoId: Value(videoId),
              title: Value(title),
              artist: Value(artist),
              thumbnailUrl: Value(thumbnailUrl),
              downloadPath: Value(finalPath),
              fileSize: Value(fileSize),
              duration: const Value(0), // Default
              cachedAt: Value(DateTime.now()),
              lastPlayed: Value(DateTime.now()),
            ),
          );

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
    final allTracks = await (_db.select(_db.youTubeTracks)
          ..where((t) => t.downloadPath.isNotNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.lastPlayed, mode: OrderingMode.asc)
          ])) // Delete oldest played first
        .get();

    var currentSize =
        allTracks.fold<int>(0, (sum, t) => sum + (t.fileSize ?? 0));

    if (currentSize + newFileSize <= _maxCacheSize) return;

    debugPrint('Cache space low. Cleaning up...');

    for (var track in allTracks) {
      if (currentSize + newFileSize <= _maxCacheSize) break;

      if (track.downloadPath != null) {
        final file = File(track.downloadPath!);
        if (await file.exists()) {
          await file.delete();
        }

        // Just nullify the download path/size, don't delete the record (keep history/favorites)
        await (_db.update(_db.youTubeTracks)
              ..where((t) => t.videoId.equals(track.videoId)))
            .write(const YouTubeTracksCompanion(
                downloadPath: Value(null), fileSize: Value(null)));

        currentSize -= (track.fileSize ?? 0);
        debugPrint('Deleted cached track: ${track.title}');
      }
    }
  }

  Future<void> updateLastPlayed(String videoId) async {
    await (_db.update(_db.youTubeTracks)
          ..where((t) => t.videoId.equals(videoId)))
        .write(YouTubeTracksCompanion(lastPlayed: Value(DateTime.now())));
  }

  Future<void> clearCache() async {
    final allTracks = await (_db.select(_db.youTubeTracks)
          ..where((t) => t.downloadPath.isNotNull()))
        .get();

    for (var track in allTracks) {
      if (track.downloadPath != null) {
        final file = File(track.downloadPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    // Reset columns in DB
    await (_db.update(_db.youTubeTracks)
          ..where((t) => t.downloadPath.isNotNull()))
        .write(const YouTubeTracksCompanion(
            downloadPath: Value(null), fileSize: Value(null)));
  }

  Future<int> getCacheUsage() async {
    final allTracks = await (_db.select(_db.youTubeTracks)
          ..where((t) => t.downloadPath.isNotNull()))
        .get();
    return allTracks.fold<int>(0, (sum, t) => sum + (t.fileSize ?? 0));
  }

  Future<List<YouTubeTrack>> getCachedTracks() async {
    return await (_db.select(_db.youTubeTracks)
          ..where((t) => t.downloadPath.isNotNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.lastPlayed, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<void> deleteCachedTrack(String videoId) async {
    final track = await (_db.select(_db.youTubeTracks)
          ..where((t) => t.videoId.equals(videoId)))
        .getSingleOrNull();

    if (track != null && track.downloadPath != null) {
      final file = File(track.downloadPath!);
      if (await file.exists()) {
        await file.delete();
      }
      await (_db.update(_db.youTubeTracks)
            ..where((t) => t.videoId.equals(videoId)))
          .write(const YouTubeTracksCompanion(
              downloadPath: Value(null), fileSize: Value(null)));
    }
  }
}
