import 'dart:async';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/datasources/app_database.dart';
// Removed Isar models
import '../../domain/entities/youtube_song.dart';
import '../../domain/entities/home_section.dart';
import 'innertube/innertube.dart';
// LocalizationService removed
import 'settings_service.dart';
import '../utils/localization.dart';

class RecommendationService {
  final YoutubeExplode _yt;
  final InnerTubeService _innerTube;
  final AppDatabase _db;
  final SettingsService?
      _settingsService; // Optional for now to avoid breaking changes if not ready

  RecommendationService(this._yt, this._innerTube, this._db,
      {SettingsService? settingsService})
      : _settingsService = settingsService;

  /// Ініціалізація сервісу (Isar initialization removed).
  /// Initialize service.
  Future<void> init() async {
    // No specific initialization needed for Drift here, usually done in main or lazily
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
    // 1. Update/Insert metadata in YouTubeTracks table
    await _db.into(_db.youTubeTracks).insertOnConflictUpdate(
          YouTubeTracksCompanion.insert(
            videoId: videoId,
            title: title,
            artist: artist,
            thumbnailUrl: thumbnailUrl,
            duration: 0, // We might update this later if known
            cachedAt: DateTime.now(),
            lastPlayed: Value(DateTime.now()),
          ),
        );

    // 2. Add to PlaybackLog
    await _db.into(_db.playbackLog).insert(
          PlaybackLogCompanion.insert(
            videoId: videoId,
            playedAt: DateTime.now(),
          ),
        );
  }

  /// Основний метод для отримання персоналізованої стрічки ("For You").
  /// Main method to get personalized feed.
  Future<List<HomeSection>> getPersonalizedFeed() async {
    try {
      AppLocalizations? loc;
      if (_settingsService != null) {
        final langCode = _settingsService?.loadString('language_code') ?? 'en';
        // We need to load localizations manually since we are in a service
        // This is a bit of a hack, but better than depending on a Provider
        loc = await const AppLocalizationsDelegate().load(Locale(langCode));
      }

      // Fetch Liked Songs (Favorites) from Drift
      final likedTracks = await (_db.select(_db.youTubeTracks)
            ..where((t) => t.isFavorite.equals(true))
            ..orderBy([
              (t) =>
                  OrderingTerm(expression: t.likedAt, mode: OrderingMode.desc)
            ])
            ..limit(10))
          .get();

      HomeSection? likedSection;
      if (likedTracks.isNotEmpty) {
        final songs = likedTracks.map((l) {
          // Heuristic: If ID contains slash and doesn't look like a standard YouTube ID (11 chars), assume it's a local path.
          String vId = l.videoId;
          if (vId.length != 11 && vId.contains(RegExp(r'[/\\]'))) {
            // Add prefix so HomeFeedScreen handles it as local track
            if (!vId.startsWith('local:')) {
              vId = 'local:$vId';
            }
          }

          return YouTubeSong(
              videoId: vId,
              title: l.title,
              artist: l.artist,
              thumbnailUrl: l.thumbnailUrl,
              duration: l.duration,
              category: "Liked");
        }).toList();

        likedSection = HomeSection(
            title: loc?.likedSongs ?? "Liked Songs",
            songs: songs,
            type: SectionType.horizontal);
      }

      // 1. Try to get personalized home data from InnerTube
      final homeShelves = await _innerTube.getHomeData();
      if (homeShelves.isNotEmpty) {
        final List<HomeSection> sections = [];

        if (likedSection != null) {
          sections.add(likedSection);
        }

        for (var shelf in homeShelves) {
          final title = shelf.title;
          final songs = shelf.items;

          if (songs.isEmpty) continue;

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

          // Try to match known English titles to localized strings
          String displayTitle = title;
          if (loc != null) {
            final lower = title.toLowerCase();
            if (lower == 'made for you' || lower.contains('made for you')) {
              displayTitle = loc.madeForYou;
            } else if (lower == 'quick picks') {
              displayTitle = loc.quickPicks;
            } else if (lower == 'listen again') {
              displayTitle = loc.listenAgain;
            } else if (lower == 'recommended' ||
                lower.contains('recommended')) {
              displayTitle = loc.recommendedForYou;
            }
          }

          sections
              .add(HomeSection(title: displayTitle, songs: songs, type: type));
        }

        return sections;
      }

      // 2. Fallback to Listen History + Related (Old Logic adapted)
      // Крок А: Отримання історії

      // Join PlaybackLog with YouTubeTracks to get metadata
      final historyQuery = _db.select(_db.playbackLog).join([
        innerJoin(_db.youTubeTracks,
            _db.youTubeTracks.videoId.equalsExp(_db.playbackLog.videoId))
      ])
        ..orderBy([
          OrderingTerm(
              expression: _db.playbackLog.playedAt, mode: OrderingMode.desc)
        ])
        ..limit(10);

      final historyRows = await historyQuery.get();

      // Крок B: "Холодний старт"
      if (historyRows.isEmpty) {
        final trending = await _fetchTrendingMusic();
        return [
          HomeSection(
              title: loc?.trendingNow ?? "Trending Now",
              songs: trending,
              type: SectionType.grid // Tiles for trending
              )
        ];
      }

      // Крок C: Алгоритм рекомендацій
      final historyItems = historyRows.map((row) {
        final track = row.readTable(_db.youTubeTracks);
        return YouTubeSong(
          videoId: track.videoId,
          title: track.title,
          artist: track.artist,
          thumbnailUrl: track.thumbnailUrl,
          duration: track.duration,
        );
      }).toList();

      final futures = historyItems
          .take(5)
          .map((item) => _safeGetRelatedVideos(item.videoId));
      final results = await Future.wait(futures);

      final allRelated = results.expand((i) => i).toList();

      final historyIds = historyItems.map((e) => e.videoId).toSet();
      final seenIds = <String>{};
      final List<YouTubeSong> recommendedSongs = [];

      // History Section
      final List<YouTubeSong> historySongs = historyItems;

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
      // Uses the new SearchClient.search() API instead of deprecated getVideos()
      final searchResults = await _yt.search.search("Global Top Songs");

      final List<YouTubeSong> songs = [];

      int count = 0;
      for (final video in searchResults) {
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
    // _db is managed by GetIt usually, so no need to close specifically unless we own it
  }
}
