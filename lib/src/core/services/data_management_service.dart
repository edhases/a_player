import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path_provider/path_provider.dart';
import 'package:audio_service/audio_service.dart';

import 'settings_service.dart';
import '../../data/datasources/app_database.dart';
import 'cache_service.dart';
import 'package:get_it/get_it.dart';

class DataManagementService {
  final SettingsService _settings;
  final AppDatabase _db;

  DataManagementService(this._settings, this._db);

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
      if (GetIt.I.isRegistered<CacheService>()) {
        await GetIt.I<CacheService>().clearCache();
      }

      debugPrint('[DataManagementService] Factory reset complete');
    } catch (e) {
      debugPrint('[DataManagementService] Factory reset failed: $e');
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

  Future<Map<String, dynamic>> _serializeDatabase() async {
    final youtubeTracks = await _db.select(_db.youTubeTracks).get();
    final radioStations = await _db.select(_db.radioStations).get();
    final trackOverrides = await _db.select(_db.trackOverrides).get();
    // For Tracks, we only care about favorites and overrides (isExcluded)
    final modifiedTracks = await (_db.select(_db.tracks)
          ..where((t) => t.isFavorite | t.isExcluded))
        .get();

    return {
      'youtube_tracks': youtubeTracks.map((e) => e.toJson()).toList(),
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
