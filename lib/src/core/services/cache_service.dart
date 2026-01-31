import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:metadata_god/metadata_god.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/app_database.dart';
// import '../services/recommendation_service.dart'; // Removed
import 'package:flutter/foundation.dart';
import 'settings_service.dart';

class CacheService {
  final AppDatabase _db;
  final SettingsService? _settingsService;
  final Dio _dio = Dio();

  // Default max cache size: 500MB
  static const int _defaultMaxCacheSize = 500 * 1024 * 1024;
  int _maxCacheSize = _defaultMaxCacheSize;

  CacheService({
    required AppDatabase db,
    SettingsService? settingsService,
  })  : _db = db,
        _settingsService = settingsService;

  Future<void> init() async {
    // Load max cache size from settings
    final settings = _settingsService;
    if (settings != null) {
      _maxCacheSize = settings.loadMaxCacheSize();
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

    // Also check for cached files that might not be in DB
    // (handles migration from old .mp3 format)
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(dir.path, 'songs_cache'));
    if (await cacheDir.exists()) {
      for (final ext in ['webm', 'm4a', 'mp3']) {
        final file = File(p.join(cacheDir.path, '$videoId.$ext'));
        if (await file.exists()) return true;
      }
    }

    return false;
  }

  Future<String?> getCachedFilePath(String videoId) async {
    final track = await (_db.select(_db.youTubeTracks)
          ..where((t) => t.videoId.equals(videoId)))
        .getSingleOrNull();
    return track?.downloadPath;
  }

  /// Cache a track to local storage
  /// [container] should be 'webm' or 'mp4' from YouTubeHelper for correct extension
  Future<void> cacheTrack({
    required String videoId,
    required String url,
    required String title,
    required String artist,
    required String thumbnailUrl,
    String? container, // webm or mp4
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(dir.path, 'songs_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    // Determine file extension based on container format
    // webm = Opus audio, mp4 = AAC audio
    final extension = (container?.toLowerCase() == 'webm') ? 'webm' : 'm4a';

    // Temporary path
    final tempPath = p.join(cacheDir.path, '$videoId.tmp');
    final finalPath = p.join(cacheDir.path, '$videoId.$extension');

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

      // Embed metadata tags into m4a files for persistence after reinstall
      if (extension == 'm4a') {
        try {
          // Download artwork
          Picture? picture;
          if (thumbnailUrl.isNotEmpty) {
            try {
              final response = await http.get(Uri.parse(thumbnailUrl));
              if (response.statusCode == 200) {
                picture = Picture(
                  data: response.bodyBytes,
                  mimeType: 'image/jpeg',
                );
              }
            } catch (e) {
              debugPrint('Error downloading artwork: $e');
            }
          }

          final metadata = Metadata(
            title: title,
            artist: artist,
            picture: picture,
          );
          await MetadataGod.writeMetadata(file: finalPath, metadata: metadata);
          debugPrint('Embedded tags into cached m4a: $title');
        } catch (e) {
          debugPrint('Tag embedding failed (non-fatal): $e');
        }
      } else {
        debugPrint('Skipping tag embedding for webm format (not supported)');
      }

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

  /// Checks if there is sufficient space for a new file of [estimatedSize] bytes
  /// without deleting existing tracks. Returns false if cache is full.
  Future<bool> hasSufficientSpace(int estimatedSize) async {
    // Current usage
    final allTracks = await (_db.select(_db.youTubeTracks)
          ..where((t) => t.downloadPath.isNotNull()))
        .get();

    final currentSize =
        allTracks.fold<int>(0, (sum, t) => sum + (t.fileSize ?? 0));

    return (currentSize + estimatedSize) <= _maxCacheSize;
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

  /// Returns total cache usage in bytes
  /// First tries to calculate from actual files, falls back to DB records
  Future<int> getCacheUsage() async {
    try {
      // First try to get actual file sizes from disk
      final cacheDir = await getCacheDirectory();
      if (await cacheDir.exists()) {
        int totalSize = 0;
        await for (final entity in cacheDir.list()) {
          if (entity is File) {
            try {
              totalSize += await entity.length();
            } catch (_) {}
          }
        }
        if (totalSize > 0) return totalSize;
      }
    } catch (e) {
      debugPrint('[CacheService] Error getting cache from disk: $e');
    }
    
    // Fallback to DB records
    final allTracks = await (_db.select(_db.youTubeTracks)
          ..where((t) => t.downloadPath.isNotNull()))
        .get();
    return allTracks.fold<int>(0, (sum, t) => sum + (t.fileSize ?? 0));
  }

  /// Returns the cache directory for backup purposes
  Future<Directory> getCacheDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory(p.join(dir.path, 'songs_cache'));
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
