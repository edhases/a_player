import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;

import '../../data/models/local_track_override.dart';
import '../../data/datasources/app_database.dart';

import '../../core/services/innertube_service.dart';
import '../../domain/entities/youtube_song.dart';

class MetadataMatchingService {
  final Isar _isar;
  final AppDatabase _db;
  final InnerTubeService _innerTube;

  MetadataMatchingService(this._isar, this._db, this._innerTube);

  /// Отримує інформацію про трек (спочатку перевіряє Isar, потім повертає оригінал).
  /// Gets track info (checks Isar first, then returns original).
  Future<LocalTrackOverride?> getTrackOverride(String filePath) async {
    return await _isar.localTrackOverrides.getByFilePath(filePath);
  }

  /// Спостерігає за змінами (для реактивного UI).
  /// Watch for changes (for reactive UI).
  Stream<LocalTrackOverride?> watchTrackOverride(String filePath) {
    return _isar.localTrackOverrides
        .filter()
        .filePathEqualTo(filePath)
        .watch(fireImmediately: true)
        .map((event) => event.firstOrNull);
  }

  /// Автоматичний пошук тегів для локального файлу.
  /// Auto-match tags for a local file.
  Future<LocalTrackOverride?> autoMatchTags(
      String filePath, String rawTitle) async {
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
  Future<LocalTrackOverride> saveOverride({
    required String filePath,
    required String youtubeId,
    required String title,
    required String artist,
    required String thumbnailUrl,
  }) async {
    // Check for existing override to preserve ID (important for watchers)
    final existing = await _isar.localTrackOverrides.getByFilePath(filePath);
    final override = existing ?? LocalTrackOverride();

    override
      ..filePath = filePath
      ..youtubeId = youtubeId
      ..correctTitle = title
      ..correctArtist = artist
      ..thumbnailUrl = thumbnailUrl
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.localTrackOverrides.put(override);
    });

    debugPrint(
        '[MetadataMatcher] Saved override for: $title (ID: ${override.id})');
    return override;
  }

  String _cleanFilename(String filePath, String rawTitle) {
    // Якщо rawTitle вже виглядає нормально, використовуємо його
    if (rawTitle != "Unknown" && !rawTitle.contains(".mp3")) {
      return rawTitle;
    }

    String filename = p.basenameWithoutExtension(filePath);

    // Видаляємо цифри на початку (01. Song -> Song)
    filename = filename.replaceAll(RegExp(r'^\d+\s*[\.-]?\s*'), '');

    // Замінюємо підкреслення на пробіли
    filename = filename.replaceAll('_', ' ');

    // Видаляємо зайві пробіли
    return filename.trim();
  }

  bool _isSimilar(String query, YouTubeSong song) {
    final lowerQuery = query.toLowerCase();
    final lowerTitle = song.title.toLowerCase();

    // Проста перевірка: чи містяться слова запиту в назві
    // Simple check: does title contain query words
    return lowerTitle.contains(lowerQuery) || lowerQuery.contains(lowerTitle);
  }

  Stream<String> scanEntireLibrary() async* {
    try {
      final tracks = await _db.select(_db.tracks).get();
      int processed = 0;

      for (var track in tracks) {
        // Skip if override exists
        final existing = await getTrackOverride(track.path);
        if (existing != null) continue;

        // Heuristic: consider track "dirty" if Unknown or contains extension
        bool isDirty = track.artist == "<unknown>" ||
            track.title.contains(".mp3") ||
            track.artist == "Unknown Artist";

        if (isDirty) {
          yield "Processing: ${p.basename(track.path)}";
          await autoMatchTags(track.path, track.title);
          // Delay to avoid rate limiting
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
