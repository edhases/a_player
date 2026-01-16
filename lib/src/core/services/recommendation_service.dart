import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/models/local_track_override.dart';
import '../../data/models/listen_history.dart';
import '../../data/models/liked_song.dart';
import '../../data/models/cached_track.dart';
import '../../domain/entities/youtube_song.dart';
import '../../domain/entities/home_section.dart';
import 'innertube_service.dart';
import 'localization_service.dart';
import '../utils/localization.dart';

class RecommendationService {
  final YoutubeExplode _yt;
  final InnerTubeService _innerTube;
  final LocalizationService?
      _localizationService; // Optional for now to avoid breaking changes if not ready
  Isar? _isar;

  Isar? get isar => _isar;

  RecommendationService(this._yt, this._innerTube,
      {LocalizationService? localizationService})
      : _localizationService = localizationService;

  /// Ініціалізація сервісу та відкриття бази даних Isar.
  /// Initialize service and open Isar database.
  Future<void> init() async {
    if (_isar != null && _isar!.isOpen) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        ListenHistorySchema,
        LocalTrackOverrideSchema,
        LikedSongSchema,
        CachedTrackSchema
      ],
      directory: dir.path,
    );
  }

  /// Додає відео в історію прослуховування.
  /// Add video to listen history.
  /// Якщо відео вже є в історії, оновлює час прослуховування.
  Future<void> addToHistory(Video video) async {
    await _addEntry(
      videoId: video.id.value,
      title: video.title,
      artist: video.author,
      thumbnailUrl: video.thumbnails.highResUrl,
    );
  }

  Future<void> addToHistoryManual({
    required String videoId,
    required String title,
    required String artist,
    required String thumbnailUrl,
  }) async {
    await _addEntry(
      videoId: videoId,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
    );
  }

  Future<void> _addEntry({
    required String videoId,
    required String title,
    required String artist,
    required String thumbnailUrl,
  }) async {
    final isar = _isar;
    if (isar == null) return;

    final existing =
        await isar.listenHistorys.filter().videoIdMatches(videoId).findFirst();

    await isar.writeTxn(() async {
      if (existing != null) {
        existing.timestamp = DateTime.now();
        await isar.listenHistorys.put(existing);
      } else {
        final newEntry = ListenHistory()
          ..videoId = videoId
          ..title = title
          ..artist = artist
          ..thumbnailUrl = thumbnailUrl
          ..timestamp = DateTime.now();
        await isar.listenHistorys.put(newEntry);
      }
    });
  }

  /// Основний метод для отримання персоналізованої стрічки ("For You").
  /// Main method to get personalized feed.
  Future<List<HomeSection>> getPersonalizedFeed() async {
    try {
      final isar = _isar;
      if (isar == null) {
        await init();
      }

      // Fetch Liked Songs (Favorites)
      // Note: We need to import LikedSong model to use it in queries if not implicitly available via isar
      // (It should be imported at top)
      final likedSongs = await isar!.likedSongs
          .where()
          .sortByAddedAtDesc()
          .limit(10)
          .findAll();

      HomeSection? likedSection;
      if (likedSongs.isNotEmpty) {
        final songs = likedSongs
            .map((l) => YouTubeSong(
                videoId: l.videoId,
                title: l.title,
                artist: l.artist,
                thumbnailUrl: l.thumbnailUrl,
                duration: 0,
                category: "Liked"))
            .toList();

        final loc = _localizationService != null
            ? AppLocalizations(_localizationService!.currentLocale)
            : null;

        likedSection = HomeSection(
            title:
                "Liked Songs", // TODO: Localize "Liked Songs" if needed (loc?.likedSongs ?? ...)
            songs: songs,
            type: SectionType.horizontal);
      }

      // 1. Try to get personalized home data from InnerTube
      final homeData = await _innerTube.getHomeData();
      if (homeData.isSuccess && (homeData.data?.isNotEmpty ?? false)) {
        final List<HomeSection> sections = [];

        if (likedSection != null) {
          sections.add(likedSection);
        }

        for (var sectionData in homeData.data!) {
          final title = sectionData['title'] as String? ?? 'Recommended';
          final itemsData = sectionData['items'] as List<dynamic>?;

          if (itemsData == null || itemsData.isEmpty) continue;

          final List<YouTubeSong> songs = [];
          for (var item in itemsData) {
            if (item is YouTubeSong) {
              songs.add(item);
            }
          }

          if (songs.isNotEmpty) {
            // Determine type based on title or content
            SectionType type = SectionType.horizontal;

            final lowerTitle = title.toLowerCase();

            if (lowerTitle.contains('quick picks') ||
                lowerTitle.contains('швидкий вибір') ||
                lowerTitle.contains('start radio')) {
              // Keep Quick Picks as horizontal paged grid
              type = SectionType.horizontal;
            } else if (lowerTitle.contains('listen again') ||
                lowerTitle.contains('знову') ||
                lowerTitle.contains('history')) {
              // History as simple vertical list
              type = SectionType.vertical;
            } else {
              // Everything else (Mixes, Albums, New Releases) as Grid (Tiles)
              type = SectionType.grid;
            }

            sections.add(HomeSection(title: title, songs: songs, type: type));
          }
        }

        return sections;
      }

      // 2. Fallback to Listen History + Related (Old Logic adapted)
      // Крок А: Отримання історії
      final history = await _isar!.listenHistorys
          .where()
          .sortByTimestampDesc()
          .distinctByVideoId()
          .limit(10) // Slightly more history for fallback
          .findAll();

      // Крок B: "Холодний старт"
      if (history.isEmpty) {
        final trending = await _fetchTrendingMusic();
        final loc = _localizationService != null
            ? AppLocalizations(_localizationService!.currentLocale)
            : null;
        return [
          HomeSection(
              title: loc?.trendingNow ?? "Trending Now",
              songs: trending,
              type: SectionType.grid // Tiles for trending
              )
        ];
      }

      // Крок C: Алгоритм рекомендацій
      // ... (Existing logic for fetching related)
      final futures =
          history.take(5).map((item) => _safeGetRelatedVideos(item.videoId));
      final results = await Future.wait(futures);

      final allRelated = results.expand((i) => i).toList();

      final historyIds = history.map((e) => e.videoId).toSet();
      final seenIds = <String>{};
      final List<YouTubeSong> recommendedSongs = [];

      // History Section
      final List<YouTubeSong> historySongs = history
          .map((h) => YouTubeSong(
              videoId: h.videoId,
              title: h.title,
              artist: h.artist,
              thumbnailUrl: h.thumbnailUrl,
              duration: 0, // We might not save duration in history, defaulting
              category: "Song" // Default history items to Song
              ))
          .toList();

      for (var video in allRelated) {
        if (!historyIds.contains(video.id.value) &&
            !seenIds.contains(video.id.value)) {
          if (video.isLive) continue;

          recommendedSongs.add(YouTubeSong(
            videoId: video.id.value,
            title: video.title,
            artist: video.author,
            thumbnailUrl: video.thumbnails.highResUrl,
            duration: video.duration?.inSeconds ?? 0,
          ));
          seenIds.add(video.id.value);
        }
      }

      recommendedSongs.shuffle();

      final loc = _localizationService != null
          ? AppLocalizations(_localizationService!.currentLocale)
          : null;

      return [
        if (likedSection != null) likedSection,
        if (historySongs.isNotEmpty)
          HomeSection(
              title: loc?.listenAgain ?? "Listen Again",
              songs: historySongs,
              type: SectionType.vertical), // List view for history
        if (recommendedSongs.isNotEmpty)
          HomeSection(
              title: loc?.recommendedForYou ?? "Recommended for You",
              songs: recommendedSongs.take(20).toList(),
              type: SectionType.grid // Grid view (Tiles) for recommended
              )
      ];
    } catch (e) {
      debugPrint('Error generating feed: $e');
      return [];
    }
  }

  /// Безпечне отримання схожих відео з обробкою помилок.
  /// Safe fetch of related videos with error handling.
  Future<List<Video>> _safeGetRelatedVideos(String videoId) async {
    try {
      final video = await _yt.videos.get(VideoId(videoId));
      final related = await _yt.videos.getRelatedVideos(video);
      return related?.toList() ?? [];
    } catch (e) {
      debugPrint('Error fetching related videos for $videoId: $e');
      return [];
    }
  }

  /// Отримання трендової музики для холодного старту.
  /// Fetch trending music for cold start.
  Future<List<YouTubeSong>> _fetchTrendingMusic() async {
    try {
      // Search for "Global Top Songs" instead of generic hits to get more tracks
      // Fetch more items to ensure we have enough of both
      final search = await _yt.search.getVideos("Global Top Songs");

      final List<YouTubeSong> songs = [];

      int count = 0;
      for (final video in search) {
        if (count >= 50) break; // Limit processing
        count++;

        if (video.isLive) continue;

        songs.add(YouTubeSong(
            videoId: video.id.value,
            title: video.title,
            artist: video.author,
            thumbnailUrl: video.thumbnails.highResUrl,
            duration: video.duration?.inSeconds ?? 0));
      }

      return songs;
    } catch (e) {
      debugPrint('Error fetching trending music: $e');
      return [];
    }
  }

  /// Закриття бази даних при необхідності.
  /// Close database if needed.
  Future<void> dispose() async {
    await _isar?.close();
  }
}
