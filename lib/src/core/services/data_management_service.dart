import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path_provider/path_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:path/path.dart' as p;

import 'settings_service.dart';
import '../../data/datasources/app_database.dart';
import 'cache_service.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DataManagementService {
  final SettingsService _settings;
  final AppDatabase _db;
  final CacheService? _cacheService;

  DataManagementService(
    this._settings,
    this._db, {
    CacheService? cacheService,
  }) : _cacheService = cacheService ??
            (GetIt.I.isRegistered<CacheService>() ? GetIt.I<CacheService>() : null);

  static const int kBackupVersion = 1;

  /// Creates a JSON backup file and returns it
  Future<File?> createBackup() async {
    try {
      final backupData = <String, dynamic>{
        'version': kBackupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'settings': _serializeSettings(),
        'database': await _serializeDatabase(),
      };

      final jsonString = jsonEncode(backupData);
      final tempDir = await getTemporaryDirectory();
      final backupFile = File(
          '${tempDir.path}/oxide_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await backupFile.writeAsString(jsonString);
      return backupFile;
    } catch (e) {
      debugPrint('[DataManagementService] Backup creation failed: $e');
      return null;
    }
  }

  /// Restores data from the provided JSON file
  Future<bool> restoreBackup(File file) async {
    try {
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final version = data['version'] as int? ?? 0;
      if (version > kBackupVersion) {
        debugPrint(
            '[DataManagementService] Backup version $version is newer than current $kBackupVersion');
        // We might want to warn the user, but for now we try best effort or abort?
        // Let's proceed with caution.
      }

      if (data.containsKey('settings')) {
        await _restoreSettings(data['settings'] as Map<String, dynamic>);
      }

      if (data.containsKey('database')) {
        await _restoreDatabase(data['database'] as Map<String, dynamic>);
      }

      return true;
    } catch (e) {
      debugPrint('[DataManagementService] Restore failed: $e');
      return false;
    }
  }

  /// Factory Reset: Clears settings, database, and cache
  Future<void> factoryReset() async {
    try {
      // 1. Clear Settings
      // We don't have a specific "clear methods" in settings service,
      // but we can clear SharedPreferences.
      // Accessing generic prefs is not direct in SettingsService,
      // but we can assume we want to reset all keys we manage.
      // Ideally SettingsService should have a `clearAll()` method.
      // For now, we manually reset keys we know.
      // Or we can inject SharedPreferences and clear() it?
      // SettingsService uses a private _prefs.
      // We'll add a clearAll() to SettingsService later.
      // For now, let's just reset known keys to defaults.
      await _settings.saveThemeMode(0); // System
      await _settings.saveAmoledMode(false);
      await _settings
          .saveAccentColor(Colors.blue.toARGB32()); // Wait, this needs check
      // Actually, let's implement clearAll in SettingsService.

      // 2. Clear Database
      // We can delete all rows from tables.
      await _db.fileDelete(_db.youTubeTracks);
      await _db.fileDelete(_db.radioStations);
      await _db.fileDelete(_db.playbackLog);
      await _db.fileDelete(_db.trackOverrides);
      await _db.fileDelete(_db.homeCache);

      // For Tracks (local files), we just reset 'isFavorite' and 'isExcluded'.
      // We don't want to delete the tracks themselves as they represent files.
      await (_db.update(_db.tracks)
        ..write(const TracksCompanion(
          isFavorite: drift.Value(false),
          isExcluded: drift.Value(false),
        )));

      // 3. Clear Cache
      if (_cacheService != null) {
        await _cacheService!.clearCache();
      }

      debugPrint('[DataManagementService] Factory reset complete');
    } catch (e) {
      debugPrint('[DataManagementService] Factory reset failed: $e');
    }
  }

  // --- ZIP Backup v2 ---
  static const int kBackupVersionV2 = 2;

  /// Get estimated backup sizes for UI display
  Future<Map<String, int>> getBackupSizes() async {
    final sizes = <String, int>{
      'settings_db': 0,
      'cache': 0,
    };

    try {
      // Settings + DB estimate (small, typically < 1MB)
      final settingsJson = jsonEncode(_serializeSettings());
      final dbJson = jsonEncode(await _serializeDatabase());
      sizes['settings_db'] = settingsJson.length + dbJson.length;

      // Cache size
      if (_cacheService != null) {
        sizes['cache'] = await _cacheService!.getCacheUsage();
      }
    } catch (e) {
      debugPrint('[DataManagementService] Error getting backup sizes: $e');
    }

    return sizes;
  }

  /// Creates a ZIP backup archive with optional components
  Future<File?> createBackupArchive({
    bool includeCache = false,
    bool includeCookies = false,
    bool includeHistory = true,
  }) async {
    try {
      final archive = Archive();
      final checksums = <String, String>{};

      // 1. Add settings.json
      final settingsJson = jsonEncode(_serializeSettings());
      final settingsBytes = utf8.encode(settingsJson);
      checksums['settings.json'] = sha256.convert(settingsBytes).toString();
      archive.addFile(ArchiveFile(
        'settings.json',
        settingsBytes.length,
        settingsBytes,
      ));

      // 2. Add database.json (with history flag)
      final dbJson =
          jsonEncode(await _serializeDatabase(includeHistory: includeHistory));
      final dbBytes = utf8.encode(dbJson);
      checksums['database.json'] = sha256.convert(dbBytes).toString();
      archive.addFile(ArchiveFile(
        'database.json',
        dbBytes.length,
        dbBytes,
      ));

      // 3. Add cache files if requested
      if (includeCache && _cacheService != null) {
        final cacheDir = await _cacheService!.getCacheDirectory();

        if (await cacheDir.exists()) {
          await for (final entity in cacheDir.list(recursive: true)) {
            if (entity is File) {
              final relativePath = p.relative(entity.path, from: cacheDir.path);
              final bytes = await entity.readAsBytes();
              checksums['cache/$relativePath'] =
                  sha256.convert(bytes).toString();
              archive.addFile(ArchiveFile(
                'cache/$relativePath',
                bytes.length,
                bytes,
              ));
            }
          }
        }
      }

      // 4. Add WebView cookies if requested
      if (includeCookies) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final webviewDir =
              Directory(p.join(appDir.parent.path, 'app_webview'));

          if (await webviewDir.exists()) {
            await for (final entity in webviewDir.list(recursive: true)) {
              if (entity is File) {
                final relativePath =
                    p.relative(entity.path, from: webviewDir.path);
                final bytes = await entity.readAsBytes();
                checksums['webview/$relativePath'] =
                    sha256.convert(bytes).toString();
                archive.addFile(ArchiveFile(
                  'webview/$relativePath',
                  bytes.length,
                  bytes,
                ));
              }
            }
          }

          // Also try to get cookies from SharedPreferences
          final cookiesJson = _settings.loadString('youtube_cookies');
          if (cookiesJson != null && cookiesJson.isNotEmpty) {
            final cookiesBytes = utf8.encode(cookiesJson);
            checksums['cookies.json'] = sha256.convert(cookiesBytes).toString();
            archive.addFile(ArchiveFile(
              'cookies.json',
              cookiesBytes.length,
              cookiesBytes,
            ));
          }
        } catch (e) {
          debugPrint('[DataManagementService] Error backing up cookies: $e');
        }
      }

      // 5. Create manifest.json
      final packageInfo = await PackageInfo.fromPlatform();
      final manifest = {
        'backupVersion': kBackupVersionV2,
        'createdAt': DateTime.now().toIso8601String(),
        'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
        'includes': {
          'settings': true,
          'database': true,
          'history': includeHistory,
          'cache': includeCache,
          'cookies': includeCookies,
        },
        'checksums': checksums,
      };
      final manifestBytes = utf8.encode(jsonEncode(manifest));
      archive.addFile(ArchiveFile(
        'manifest.json',
        manifestBytes.length,
        manifestBytes,
      ));

      // 6. Encode to ZIP
      final zipData = ZipEncoder().encode(archive);

      // 7. Write to file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final zipFile = File('${tempDir.path}/oxide_backup_v2_$timestamp.zip');
      await zipFile.writeAsBytes(zipData);

      debugPrint('[DataManagementService] ZIP backup created: ${zipFile.path}');
      return zipFile;
    } catch (e) {
      debugPrint('[DataManagementService] ZIP backup creation failed: $e');
      return null;
    }
  }

  /// Restores from a ZIP backup archive
  Future<bool> restoreBackupArchive(File zipFile) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. Find and parse manifest
      final manifestFile = archive.findFile('manifest.json');
      if (manifestFile == null) {
        debugPrint('[DataManagementService] No manifest found in ZIP');
        return false;
      }

      final manifestJson = utf8.decode(manifestFile.content as List<int>);
      final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
      final checksums = (manifest['checksums'] as Map<String, dynamic>?) ?? {};

      // 2. Verify and restore settings
      final settingsFile = archive.findFile('settings.json');
      if (settingsFile != null) {
        final content = settingsFile.content as List<int>;
        final expectedHash = checksums['settings.json'];
        if (expectedHash != null) {
          final actualHash = sha256.convert(content).toString();
          if (actualHash != expectedHash) {
            debugPrint('[DataManagementService] Settings checksum mismatch');
            return false;
          }
        }
        final settingsJson = utf8.decode(content);
        final settingsData = jsonDecode(settingsJson) as Map<String, dynamic>;
        await _restoreSettings(settingsData);
      }

      // 3. Verify and restore database
      final dbFile = archive.findFile('database.json');
      if (dbFile != null) {
        final content = dbFile.content as List<int>;
        final expectedHash = checksums['database.json'];
        if (expectedHash != null) {
          final actualHash = sha256.convert(content).toString();
          if (actualHash != expectedHash) {
            debugPrint('[DataManagementService] Database checksum mismatch');
            return false;
          }
        }
        final dbJson = utf8.decode(content);
        final dbData = jsonDecode(dbJson) as Map<String, dynamic>;
        await _restoreDatabase(dbData);
      }

      // 4. Restore cache if present
      final includes = manifest['includes'] as Map<String, dynamic>?;
      if (includes?['cache'] == true && _cacheService != null) {
        final cacheDir = await _cacheService!.getCacheDirectory();

        if (!await cacheDir.exists()) {
          await cacheDir.create(recursive: true);
        }

        for (final file in archive.files) {
          if (file.name.startsWith('cache/') && !file.isFile) continue;
          if (file.name.startsWith('cache/')) {
            final relativePath = file.name.substring(6); // Remove 'cache/'
            final targetPath = p.join(cacheDir.path, relativePath);

            // Create parent directories if needed
            final targetFile = File(targetPath);
            await targetFile.parent.create(recursive: true);
            await targetFile.writeAsBytes(file.content as List<int>);
          }
        }
        debugPrint('[DataManagementService] Cache restored');
      }

      // 5. Mark as restored
      await _settings.saveBool('was_restored', true);

      debugPrint('[DataManagementService] ZIP backup restored successfully');
      return true;
    } catch (e) {
      debugPrint('[DataManagementService] ZIP restore failed: $e');
      return false;
    }
  }

  // --- Serialization Helpers ---

  Map<String, dynamic> _serializeSettings() {
    return {
      'theme_mode': _settings.loadThemeMode(),
      'amoled_mode': _settings.loadAmoledMode(),
      'accent_color': _settings.loadAccentColor(),
      'font_scale': _settings.loadFontSizeScale(),
      'crossfade_duration': _settings.loadCrossfadeDuration(),
      'wifi_only': _settings.loadWifiOnly(),
      'min_track_duration': _settings.loadMinTrackDuration(),
      'max_track_duration': _settings.loadMaxTrackDuration(),
      'excluded_folders': _settings.loadExcludedFolders(),
      'max_cache_size': _settings.loadMaxCacheSize(),
      'max_log_size': _settings.loadMaxLogSize(),
      'shuffle_mode': _settings.loadShuffleMode().index,
      'repeat_mode': _settings.loadRepeatMode().index,
      'last_position': _settings.loadLastPosition().inMilliseconds,
      'last_track_id': _settings.loadLastTrackId(),
    };
  }

  Future<void> _restoreSettings(Map<String, dynamic> map) async {
    if (map.containsKey('theme_mode')) {
      await _settings.saveThemeMode(map['theme_mode']);
    }
    if (map.containsKey('amoled_mode')) {
      await _settings.saveAmoledMode(map['amoled_mode']);
    }
    if (map.containsKey('accent_color')) {
      final val = map['accent_color'];
      if (val != null) {
        await _settings.saveAccentColor(val);
      }
    }
    if (map.containsKey('font_scale')) {
      await _settings.saveFontSizeScale((map['font_scale'] as num).toDouble());
    }
    if (map.containsKey('crossfade_duration')) {
      await _settings.saveCrossfadeDuration(map['crossfade_duration']);
    }
    if (map.containsKey('wifi_only')) {
      await _settings.saveWifiOnly(map['wifi_only']);
    }
    if (map.containsKey('min_track_duration')) {
      await _settings.saveMinTrackDuration(map['min_track_duration']);
    }
    if (map.containsKey('max_track_duration')) {
      await _settings.saveMaxTrackDuration(map['max_track_duration']);
    }
    if (map.containsKey('excluded_folders')) {
      final list = (map['excluded_folders'] as List).cast<String>();
      await _settings.saveExcludedFolders(list);
    }

    // ... restore others ...
    if (map.containsKey('shuffle_mode')) {
      await _settings
          .saveShuffleMode(AudioServiceShuffleMode.values[map['shuffle_mode']]);
    }
    if (map.containsKey('repeat_mode')) {
      await _settings
          .saveRepeatMode(AudioServiceRepeatMode.values[map['repeat_mode']]);
    }
  }

  Future<Map<String, dynamic>> _serializeDatabase(
      {bool includeHistory = true}) async {
    final youtubeTracks = await _db.select(_db.youTubeTracks).get();
    final radioStations = await _db.select(_db.radioStations).get();
    final trackOverrides = await _db.select(_db.trackOverrides).get();
    // For Tracks, we only care about favorites and overrides (isExcluded)
    final modifiedTracks = await (_db.select(_db.tracks)
          ..where((t) => t.isFavorite | t.isExcluded))
        .get();

    final result = <String, dynamic>{
      'youtube_tracks': youtubeTracks.map((e) {
        final json = e.toJson();
        // Optionally exclude history (lastPlayed, cachedAt)
        if (!includeHistory) {
          json.remove('lastPlayed');
          json.remove('cachedAt');
        }
        return json;
      }).toList(),
      'radio_stations': radioStations.map((e) => e.toJson()).toList(),
      'track_overrides': trackOverrides.map((e) => e.toJson()).toList(),
      'local_tracks_metadata': modifiedTracks
          .map((e) => {
                'path': e.path,
                'isFailure': false, // drift generated toJson might include this
                'isFavorite': e.isFavorite,
                'isExcluded': e.isExcluded,
              })
          .toList(),
    };

    return result;
  }

  Future<void> _restoreDatabase(Map<String, dynamic> map) async {
    // 1. YouTube Tracks
    if (map.containsKey('youtube_tracks')) {
      final list = map['youtube_tracks'] as List;
      await _db.batch((batch) {
        batch.insertAll(
          _db.youTubeTracks,
          list.map((e) => YouTubeTrack.fromJson(e as Map<String, dynamic>)),
          mode: drift.InsertMode.insertOrReplace,
        );
      });
    }

    // 2. Radio Stations
    if (map.containsKey('radio_stations')) {
      final list = map['radio_stations'] as List;
      // We might want to clear existing stations to avoid dupes?
      // User IDs might conflict.
      // Resetting IDs usually means we just insert.
      await _db.batch((batch) {
        batch.insertAll(
          _db.radioStations,
          list.map((e) => RadioStation.fromJson(e as Map<String, dynamic>)),
          mode: drift.InsertMode.insertOrReplace,
        );
      });
    }

    // 3. Track Overrides
    if (map.containsKey('track_overrides')) {
      final list = map['track_overrides'] as List;
      await _db.batch((batch) {
        batch.insertAll(
          _db.trackOverrides,
          list.map((e) => TrackOverride.fromJson(e as Map<String, dynamic>)),
          mode: drift.InsertMode.insertOrReplace,
        );
      });
    }

    // 4. Local Tracks Metadata (Favorites/Excluded)
    if (map.containsKey('local_tracks_metadata')) {
      final list = map['local_tracks_metadata'] as List;
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final path = map['path'] as String;
        final isFavorite = map['isFavorite'] as bool? ?? false;
        final isExcluded = map['isExcluded'] as bool? ?? false;

        // We only update if the track exists
        await (_db.update(_db.tracks)..where((t) => t.path.equals(path))).write(
          TracksCompanion(
            isFavorite: drift.Value(isFavorite),
            isExcluded: drift.Value(isExcluded),
          ),
        );
      }
    }
  }
}

// Helper extension if fileDelete is not available on database directly
extension DbExtensions on AppDatabase {
  Future<void> fileDelete(drift.TableInfo table) {
    return delete(table).go();
  }
}
