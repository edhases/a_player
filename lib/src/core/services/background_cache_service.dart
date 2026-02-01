import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../data/datasources/app_database.dart';
import '../../domain/entities/youtube_song.dart';
import 'cache_service.dart';
import 'youtube_helper.dart';

/// Service for background caching of songs with persistent queue
class BackgroundCacheService {
  final CacheService _cacheService;
  final YouTubeHelper _ytHelper;
  final AppDatabase _db;

  BackgroundCacheService({
    required CacheService cacheService,
    required YouTubeHelper ytHelper,
    required AppDatabase db,
  })  : _cacheService = cacheService,
        _ytHelper = ytHelper,
        _db = db;

  // Current caching state
  bool _isCaching = false;
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _failedTasks = 0;
  String _currentSongTitle = '';

  // Stream controller for progress updates
  final _progressController = StreamController<CacheProgress>.broadcast();
  Stream<CacheProgress> get progressStream => _progressController.stream;

  bool get isCaching => _isCaching;
  int get totalTasks => _totalTasks;
  int get completedTasks => _completedTasks;
  int get failedTasks => _failedTasks;
  String get currentSongTitle => _currentSongTitle;

  /// Resume caching for any pending tracks from previous session
  /// Call this on app startup
  Future<void> resumePendingCaching() async {
    final pendingTracks = await (_db.select(_db.youTubeTracks)
          ..where((t) => t.pendingCache.equals(true))
          ..where((t) => t.downloadPath.isNull()))
        .get();

    if (pendingTracks.isEmpty) {
      debugPrint('[BackgroundCache] No pending tracks to resume');
      return;
    }

    debugPrint(
        '[BackgroundCache] Resuming ${pendingTracks.length} pending tracks');

    final songs = pendingTracks
        .map((t) => YouTubeSong(
              videoId: t.videoId,
              title: t.title,
              artist: t.artist,
              thumbnailUrl: t.thumbnailUrl,
              duration: t.duration,
            ))
        .toList();

    // Start caching (don't re-mark as pending, already marked)
    _startCaching(songs, markPending: false);
  }

  /// Queue songs for background caching
  /// Returns immediately, caching happens in background
  Future<void> queueForCaching(List<YouTubeSong> songs) async {
    if (songs.isEmpty) return;

    // Filter out already cached songs
    final songsToCache = <YouTubeSong>[];
    for (final song in songs) {
      final isCached = await _cacheService.isCached(song.videoId);
      if (!isCached) {
        songsToCache.add(song);
      }
    }

    if (songsToCache.isEmpty) {
      debugPrint('[BackgroundCache] All songs already cached');
      return;
    }

    debugPrint(
        '[BackgroundCache] Queuing ${songsToCache.length} songs for caching');

    // Mark songs as pending in database (persistent queue)
    for (final song in songsToCache) {
      await (_db.update(_db.youTubeTracks)
            ..where((t) => t.videoId.equals(song.videoId)))
          .write(const YouTubeTracksCompanion(pendingCache: Value(true)));
    }

    _startCaching(songsToCache, markPending: true);
  }

  void _startCaching(List<YouTubeSong> songs, {required bool markPending}) {
    _totalTasks = songs.length;
    _completedTasks = 0;
    _failedTasks = 0;
    _isCaching = true;
    _notifyProgress();

    // Start caching in background (don't await)
    _processCacheQueue(songs);
  }

  Future<void> _processCacheQueue(List<YouTubeSong> songs) async {
    for (final song in songs) {
      if (!_isCaching) break; // Allow cancellation

      _currentSongTitle = song.title;
      _notifyProgress();

      try {
        debugPrint('[BackgroundCache] Caching: ${song.title}');

        final audioData = await _ytHelper.getAudioUrlWithAgent(song.videoId);
        if (audioData != null) {
          await _cacheService.cacheTrack(
            videoId: song.videoId,
            url: audioData['url']!,
            title: song.title,
            artist: song.artist,
            thumbnailUrl: song.thumbnailUrl,
            container: audioData['container'],
          );

          // Mark as cached - clear pending flag
          await (_db.update(_db.youTubeTracks)
                ..where((t) => t.videoId.equals(song.videoId)))
              .write(const YouTubeTracksCompanion(pendingCache: Value(false)));

          _completedTasks++;
          debugPrint('[BackgroundCache] Cached: ${song.title}');
        } else {
          _failedTasks++;
          debugPrint('[BackgroundCache] Failed to get URL for: ${song.title}');
          // Keep pendingCache=true so it will retry on next app start
        }
      } catch (e) {
        _failedTasks++;
        debugPrint('[BackgroundCache] Error caching ${song.title}: $e');
        // Keep pendingCache=true so it will retry on next app start
      }

      _notifyProgress();
    }

    _isCaching = false;
    _currentSongTitle = '';
    _notifyProgress();

    debugPrint(
        '[BackgroundCache] Finished. Cached: $_completedTasks, Failed: $_failedTasks');
  }

  void _notifyProgress() {
    _progressController.add(CacheProgress(
      isCaching: _isCaching,
      total: _totalTasks,
      completed: _completedTasks,
      failed: _failedTasks,
      currentSong: _currentSongTitle,
    ));
  }

  /// Cancel ongoing caching
  void cancelCaching() {
    _isCaching = false;
    debugPrint('[BackgroundCache] Caching cancelled');
  }

  /// Clear pending cache flag for a specific song
  Future<void> clearPendingCache(String videoId) async {
    await (_db.update(_db.youTubeTracks)
          ..where((t) => t.videoId.equals(videoId)))
        .write(const YouTubeTracksCompanion(pendingCache: Value(false)));
  }

  /// Clear all pending cache flags
  Future<void> clearAllPendingCache() async {
    await (_db.update(_db.youTubeTracks)
          ..where((t) => t.pendingCache.equals(true)))
        .write(const YouTubeTracksCompanion(pendingCache: Value(false)));
    debugPrint('[BackgroundCache] Cleared all pending cache flags');
  }

  void dispose() {
    _progressController.close();
  }
}

/// Progress data for cache operations
class CacheProgress {
  final bool isCaching;
  final int total;
  final int completed;
  final int failed;
  final String currentSong;

  CacheProgress({
    required this.isCaching,
    required this.total,
    required this.completed,
    required this.failed,
    required this.currentSong,
  });

  int get remaining => total - completed - failed;
  double get progress => total > 0 ? (completed + failed) / total : 0;
}
