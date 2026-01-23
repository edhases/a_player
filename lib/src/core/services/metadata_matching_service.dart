import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../data/datasources/app_database.dart';
import '../../core/services/innertube_service.dart';
import '../../domain/entities/youtube_song.dart';

class MetadataMatchingService {
  final AppDatabase _db;
  final InnerTubeService _innerTube;

  MetadataMatchingService(this._db, this._innerTube);

  /// Отримує інформацію про трек (спочатку перевіряє DB, потім повертає null).
  /// Gets track info (checks DB first, then returns null).
  Future<TrackOverride?> getTrackOverride(String filePath) async {
    return await (_db.select(_db.trackOverrides)
          ..where((t) => t.filePath.equals(filePath)))
        .getSingleOrNull();
  }

  /// Спостерігає за змінами (для реактивного UI).
  /// Watch for changes (for reactive UI).
  Stream<TrackOverride?> watchTrackOverride(String filePath) {
    return (_db.select(_db.trackOverrides)
          ..where((t) => t.filePath.equals(filePath)))
        .watchSingleOrNull();
  }

  /// Автоматичний пошук тегів для локального файлу.
  /// Auto-match tags for a local file.
  Future<TrackOverride?> autoMatchTags(String filePath, String rawTitle) async {
    try {
      // Крок 1: Очищення назви файлу
      // Step 1: Clean filename
      String query = _cleanFilename(filePath, rawTitle);
      debugPrint('[MetadataMatcher] Cleaned query: "$query" for "$rawTitle"');

      // Крок 2: Пошук на YouTube Music (using InnerTubeService)
      final searchResult = await _innerTube.search(query);
      final songs = searchResult.data?.take(3).toList() ?? [];

      if (songs.isEmpty) return null;

      final bestMatch = songs.first;

      // Крок 3: Перевірка схожості (Similarity Check)
      if (_isSimilar(query, bestMatch)) {
        return await saveOverride(
          filePath: filePath,
          youtubeId: bestMatch.videoId,
          title: bestMatch.title,
          artist: bestMatch.artist,
          thumbnailUrl: bestMatch.thumbnailUrl,
        );
      }

      return null;
    } catch (e) {
      debugPrint('[MetadataMatcher] Error matching tags: $e');
      return null;
    }
  }

  /// Ручний пошук треків для вибору користувачем.
  /// Manual search for tracks for user selection.
  Future<List<YouTubeSong>> searchTracks(String query) async {
    try {
      final result = await _innerTube.search(query);
      if (result.isSuccess) {
        return result.data ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('[MetadataMatcher] Search error: $e');
      return [];
    }
  }

  /// Зберігає "віртуальні" теги в базу.
  /// Saves "virtual" tags to database.
  Future<TrackOverride> saveOverride({
    required String filePath,
    required String youtubeId,
    required String title,
    required String artist,
    required String thumbnailUrl,
  }) async {
    final override = TrackOverridesCompanion.insert(
      filePath: filePath,
      youtubeId: Value(youtubeId),
      correctTitle: Value(title),
      correctArtist: Value(artist),
      thumbnailUrl: Value(thumbnailUrl),
      updatedAt: DateTime.now(),
    );

    // Upsert equivalent in Drift
    await _db.into(_db.trackOverrides).insertOnConflictUpdate(override);

    debugPrint(
        '[MetadataMatcher] Saved override for: $title (Path: $filePath)');

    // Return inserted object (fetch back)
    return (await getTrackOverride(filePath))!;
  }

  String _cleanFilename(String filePath, String rawTitle) {
    if (rawTitle != "Unknown" && !rawTitle.contains(".mp3")) {
      return rawTitle;
    }
    String filename = p.basenameWithoutExtension(filePath);
    filename = filename.replaceAll(RegExp(r'^\d+\s*[\.-]?\s*'), '');
    filename = filename.replaceAll('_', ' ');
    return filename.trim();
  }

  bool _isSimilar(String query, YouTubeSong song) {
    final lowerQuery = query.toLowerCase();
    final lowerTitle = song.title.toLowerCase();
    return lowerTitle.contains(lowerQuery) || lowerQuery.contains(lowerTitle);
  }

  Stream<String> scanEntireLibrary() async* {
    try {
      final tracks = await _db.select(_db.tracks).get();
      int processed = 0;

      for (var track in tracks) {
        final existing = await getTrackOverride(track.path);
        if (existing != null) continue;

        // Since user manually invoked this, we scan everything that doesn't have an override yet.
        // We can optionally check if it looks complete, but users often want to match everything.
        // Let's rely on _cleanFilename to do smart work, or if not dirty enough, maybe skip?
        // User reported "only 2/4 tracks changed", implying others were skipped.
        // Let's remove the strict dirty check and try to match everything missing an override.
        bool needsScan = true;

        // Optional: Filter out tracks that already look perfect?
        // For now, let's scan all. If _cleanFilename returns same title, search results might be poor
        // but it gives a chance to match "Track 1" or similar.

        if (needsScan) {
          yield "Processing: ${p.basename(track.path)}";
          await autoMatchTags(track.path, track.title);
          await Future.delayed(const Duration(milliseconds: 500));
        }
        processed++;
      }
      yield "Scan complete. Processed $processed tracks.";
    } catch (e) {
      yield "Error scanning library: $e";
      debugPrint('[MetadataMatcher] Scan error: $e');
    }
  }
}
