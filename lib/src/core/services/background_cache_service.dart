import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/youtube_song.dart';
import 'cache_service.dart';
import 'youtube_helper.dart';

/// Service for background caching of songs
class BackgroundCacheService {
  final CacheService _cacheService;
  final YouTubeHelper _ytHelper;

  BackgroundCacheService({
    required CacheService cacheService,
    required YouTubeHelper ytHelper,
  })  : _cacheService = cacheService,
        _ytHelper = ytHelper;

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

    debugPrint('[BackgroundCache] Queuing ${songsToCache.length} songs for caching');
    
    _totalTasks = songsToCache.length;
    _completedTasks = 0;
    _failedTasks = 0;
    _isCaching = true;
    _notifyProgress();

    // Start caching in background (don't await)
    _processCacheQueue(songsToCache);
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
          _completedTasks++;
          debugPrint('[BackgroundCache] Cached: ${song.title}');
        } else {
          _failedTasks++;
          debugPrint('[BackgroundCache] Failed to get URL for: ${song.title}');
        }
      } catch (e) {
        _failedTasks++;
        debugPrint('[BackgroundCache] Error caching ${song.title}: $e');
      }

      _notifyProgress();
    }

    _isCaching = false;
    _currentSongTitle = '';
    _notifyProgress();
    
    debugPrint('[BackgroundCache] Finished. Cached: $_completedTasks, Failed: $_failedTasks');
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
