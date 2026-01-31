import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../data/datasources/app_database.dart';
import '../../core/services/innertube/innertube.dart';
import '../../domain/entities/youtube_song.dart';
import 'tag_editor_service.dart';
import 'settings_service.dart';

class MetadataMatchingService {
  final AppDatabase _db;
  final InnerTubeService _innerTube;
  final TagEditorService _tagEditor;
  final SettingsService _settings;

  MetadataMatchingService(
      this._db, this._innerTube, this._tagEditor, this._settings);

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
      final songs = searchResult.take(3).toList();

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
      return await _innerTube.search(query);
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

    // Physical tagging if enabled
    if (_settings.loadSaveMetadataToFile()) {
      debugPrint('[MetadataMatcher] Physical tagging enabled, writing tags...');
      // We don't have album here easily, maybe we can try to guess or just use "Unknown Album"
      // Or we can try to find the track in DB to get its current album
      String album = 'Unknown Album';
      try {
        final track = await (_db.select(_db.tracks)
              ..where((t) => t.path.equals(filePath)))
            .getSingleOrNull();
        if (track != null && track.album != null) {
          album = track.album!;
        }
      } catch (e) {
        debugPrint('[MetadataMatcher] Error getting track for album: $e');
      }

      await _tagEditor.writeTags(
        path: filePath,
        title: title,
        artist: artist,
        album: album,
        requestPermission: true,
      );
    }

    // Return inserted object (fetch back)
    return (await getTrackOverride(filePath))!;
  }

  String _cleanFilename(String filePath, String rawTitle) {
    String filename = p.basenameWithoutExtension(filePath);

    // 1. Common technical prefixes/suffixes
    final patternsToRemove = [
      RegExp(r'^downloaded_', caseSensitive: false),
      RegExp(r'^yt-dlp_', caseSensitive: false),
      RegExp(r'_\d{8,12}$'), // Date or ID at the end
      RegExp(r'\.mp3$', caseSensitive: false),
    ];

    for (var pattern in patternsToRemove) {
      filename = filename.replaceFirst(pattern, '');
    }

    // 2. Clear common dividers
    filename = filename.replaceAll('_', ' ');
    filename = filename.replaceAll('-', ' ');

    // 3. Remove track numbers at start
    filename = filename.replaceAll(RegExp(r'^\d+\s*[\.-]?\s*'), '');

    // 4. Remove extra spaces
    filename = filename.replaceAll(RegExp(r'\s+'), ' ').trim();

    // If filename is too short after cleaning, fallback to rawTitle if it's not "Unknown"
    if (filename.length < 3 &&
        rawTitle != "Unknown" &&
        !rawTitle.contains(".mp3")) {
      return rawTitle;
    }

    return filename;
  }

  bool _isSimilar(String query, YouTubeSong song) {
    final lowerQuery = query.toLowerCase();
    final lowerTitle = song.title.toLowerCase();
    final lowerArtist = song.artist.toLowerCase();

    // Direct match
    if (lowerTitle.contains(lowerQuery) || lowerQuery.contains(lowerTitle)) {
      return true;
    }

    // Match if query contains artist AND title (common for many filenames)
    if (lowerQuery.contains(lowerArtist) && lowerQuery.contains(lowerTitle)) {
      return true;
    }

    // Basic Levenshtein would be better, but simple keyword check for now
    final keywords = lowerQuery.split(' ').where((w) => w.length > 2).toList();
    if (keywords.isEmpty) return false;

    int matches = 0;
    for (var word in keywords) {
      if (lowerTitle.contains(word) || lowerArtist.contains(word)) {
        matches++;
      }
    }

    return matches >= 2 || (keywords.length == 1 && matches == 1);
  }

  Stream<String> scanEntireLibrary() async* {
    try {
      final tracks = await _db.select(_db.tracks).get();
      int processed = 0;

      for (var track in tracks) {
        final existing = await getTrackOverride(track.path);
        if (existing != null) continue;

        yield "Processing: ${p.basename(track.path)}";
        await autoMatchTags(track.path, track.title);
        await Future.delayed(const Duration(milliseconds: 500));

        processed++;
      }
      yield "Scan complete. Processed $processed tracks.";
    } catch (e) {
      yield "Error scanning library: $e";
      debugPrint('[MetadataMatcher] Scan error: $e');
    }
  }
}
