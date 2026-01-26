import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import 'youtube_helper.dart';

class PrefetchManager {
  final YouTubeHelper _ytHelper;
  final CacheService _cacheService;

  List<MediaItem> _queue = [];
  int _currentIndex = 0;
  bool _isDisposed = false;

  // Track the current prefetch job to allow cancellation
  // We use a simple counter/token approach to invalidate old jobs
  int _jobToken = 0;

  PrefetchManager(this._ytHelper, this._cacheService);

  void updateQueue(List<MediaItem> queue) {
    if (_isDisposed) return;
    _queue = queue;
    _restartPrefetch();
  }

  void updateIndex(int index) {
    if (_isDisposed) return;
    if (_currentIndex == index) return;
    _currentIndex = index;
    _restartPrefetch();
  }

  void dispose() {
    _isDisposed = true;
    _jobToken++; // Cancel any running jobs
  }

  void _restartPrefetch() {
    _jobToken++; // Invalidate previous run
    final currentToken = _jobToken;

    // Start new sequential chain
    // Use Timer.run to avoid synchronous blocking in the update loop
    Timer.run(() => _runSequentialPrefetch(currentToken));
  }

  Future<void> _runSequentialPrefetch(int token) async {
    // Audit Requirement: Active -> Next -> ... -> End
    // Process entire queue sequentially starting from current index

    // Safety break: don't prefetch more than 50 items ahead to save memory if queue is huge
    final maxAhead = 50;

    for (int i = 0; i < maxAhead; i++) {
      final index = _currentIndex + i;

      if (_isDisposed || token != _jobToken) return;
      if (index >= _queue.length) break;

      try {
        await _prefetchOne(_queue[index], token);
      } catch (e) {
        debugPrint('[PrefetchManager] Error prefetching index $index: $e');
        // Continue to next item even if one fails
      }
    }
  }

  Future<void> _prefetchOne(MediaItem item, int token) async {
    // 1. Check if cancelled
    if (_isDisposed || token != _jobToken) return;

    // 2. Skip local or radio
    if (item.extras?['isOnline'] != true) return;
    if (item.extras?['isRadio'] == true) return;

    final videoId = item.extras?['videoId'] as String?;
    if (videoId == null) return;

    // 3. Check disk cache (CacheService)
    // If it's fully downloaded, we don't need to resolve URL
    final isCachedOnDisk = await _cacheService.isCached(videoId);
    if (isCachedOnDisk) {
      // debugPrint('[PrefetchManager] Skipped $videoId (Disk Hit)');
      return;
    }

    // 4. Check memory cache (YouTubeHelper internal)
    // We can't check it directly without exposing it, but calling getAudioUrl
    // is efficient if it's already there.

    // 5. Perform Fetch
    if (token != _jobToken) return;
    debugPrint('[PrefetchManager] Prefetching sequence: ${item.title}');

    // getAudioUrl will handle caching internally in YouTubeHelper
    await _ytHelper.getAudioUrl(videoId);
  }
}
