import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:ui';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../data/datasources/app_database.dart';

import '../utils/localization.dart';

/// Service for finding and scanning music files.
/// Uses on_audio_query for fast MediaStore queries.
class MusicFinder {
  final AppDatabase _db;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final ValueNotifier<bool> isScanning = ValueNotifier(false);
  final ValueNotifier<String> scanStatus = ValueNotifier('');

  MusicFinder(this._db);

  /// Scans all music from device using Android MediaStore.
  /// This is MUCH faster than manual file scanning with metadata_god.
  Future<void> scanAllMusic() async {
    if (isScanning.value) return;

    try {
      isScanning.value = true;
      final localeCode = Platform.localeName.split('_')[0];
      // Default to English if parsing fails or specialized handling needed,
      // but delegate handles fallback.
      final loc =
          await const AppLocalizationsDelegate().load(Locale(localeCode));

      scanStatus.value = loc.scanQuerying;

      // Query all songs from MediaStore
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      debugPrint('[MusicFinder] Found ${songs.length} songs in MediaStore');
      scanStatus.value =
          loc.translate('scan_found', args: {'count': songs.length});

      if (songs.isEmpty) {
        debugPrint('[MusicFinder] No songs found in MediaStore');
        return;
      }

      // Process in Isolate to avoid blocking UI
      // We also removed per-item UI updates to prevent 60fps rebuilds
      scanStatus.value = loc.scanProcessing;

      final trackCompanions = await compute(_mapSongsToCompanions, songs);

      // Insert into database
      if (trackCompanions.isNotEmpty) {
        scanStatus.value = loc
            .translate('scan_saving', args: {'count': trackCompanions.length});

        await _db.batch((batch) {
          batch.insertAll(_db.tracks, trackCompanions,
              mode: InsertMode.replace);
        });

        debugPrint(
            '[MusicFinder] Saved ${trackCompanions.length} tracks to database');
      }
    } catch (e, stackTrace) {
      debugPrint('[MusicFinder] Error: $e');
      debugPrint('[MusicFinder] Stack: $stackTrace');
    } finally {
      isScanning.value = false;
      scanStatus.value = '';
    }
  }

  /// Legacy method for picking a specific folder (slower, uses metadata_god).
  /// Keep for cases where user wants to scan a specific folder.
  Future<void> pickFolderAndScan() async {
    // For now, just use the fast MediaStore scan
    await scanAllMusic();
  }

  /// Clears all tracks from the database.
  Future<void> clearLibrary() async {
    await _db.delete(_db.tracks).go();
    debugPrint('[MusicFinder] Library cleared');
  }

  /// Check and request audio permission.
  Future<bool> checkPermission() async {
    return await _audioQuery.checkAndRequest();
  }

  /// Get recently played tracks from local database
  Future<List<Track>> getRecentTracks({int limit = 10}) async {
    return _db.getRecentTracks(limit: limit);
  }

  /// Static function to run in Isolate
  static List<TracksCompanion> _mapSongsToCompanions(List<SongModel> songs) {
    final List<TracksCompanion> list = [];

    for (var song in songs) {
      if (song.data.isEmpty) continue;

      list.add(TracksCompanion.insert(
        path: song.data,
        title: song.title.isNotEmpty
            ? song.title
            : p.basenameWithoutExtension(song.data),
        artist: Value(
            song.artist != '<unknown>' && song.artist!.trim().isNotEmpty
                ? song.artist
                : null),
        album: Value(song.album != '<unknown>' && song.album!.trim().isNotEmpty
            ? song.album
            : null),
        duration: song.duration ?? 0,
        folderPath: p.dirname(song.data),
        mediaStoreId: Value(song.id),
      ));
    }

    return list;
  }

  /// Disposes resources used by this service.
  void dispose() {
    isScanning.dispose();
    scanStatus.dispose();
  }
}
