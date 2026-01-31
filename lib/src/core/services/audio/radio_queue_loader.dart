import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import '../innertube/innertube.dart';
import '../ksoft_service.dart';
import '../../utils/media_item_adapter.dart';
import '../../../domain/entities/youtube_song.dart';

/// Handles loading radio/recommendation tracks to extend the queue.
///
/// Responsibilities:
/// - Load radio tracks based on current song
/// - Deduplicate tracks already in queue
/// - Add tracks to queue when approaching end
class RadioQueueLoader {
  final InnerTubeService _innerTubeService;
  final KSoftService? _ksoftService;
  final Future<void> Function(List<MediaItem>) _addToQueue;

  bool _isLoading = false;
  String? _lastLoadedVideoId;
  DateTime? _lastLoadTime;

  RadioQueueLoader({
    required InnerTubeService innerTubeService,
    required Future<void> Function(List<MediaItem>) addToQueue,
    KSoftService? ksoftService,
  })  : _innerTubeService = innerTubeService,
        _addToQueue = addToQueue,
        _ksoftService = ksoftService;

  /// Check if we should load more radio tracks and do so if needed.
  ///
  /// Call this when approaching the end of the queue.
  Future<void> checkAndLoadMore({
    required List<MediaItem> currentQueue,
    required int currentIndex,
    required bool loopEnabled,
  }) async {
    // Synchronous guard - must be first!
    if (_isLoading) {
      debugPrint('[RadioQueueLoader] Already loading, skipping');
      return;
    }
    
    if (loopEnabled) return;
    if (currentQueue.isEmpty) return;

    // Check if we're near the end (within 3 tracks)
    if (currentIndex < currentQueue.length - 3) return;

    final lastItem = currentQueue.last;

    // Only auto-load if the last item is a YouTube song
    if (lastItem.extras?['isOnline'] != true && lastItem.id.length != 11) {
      return;
    }
    
    // Debounce: don't load same video within 30 seconds
    final now = DateTime.now();
    if (_lastLoadedVideoId == lastItem.id && _lastLoadTime != null) {
      if (now.difference(_lastLoadTime!) < const Duration(seconds: 30)) {
        debugPrint('[RadioQueueLoader] Debouncing, recently loaded for ${lastItem.id}');
        return;
      }
    }

    // Set loading flag synchronously before any async operation
    _isLoading = true;
    _lastLoadedVideoId = lastItem.id;
    _lastLoadTime = now;
    
    try {
      debugPrint(
          '[RadioQueueLoader] Approaching end of queue. Loading more tracks...');
      await loadRadioQueue(
        videoId: lastItem.id,
        currentQueue: currentQueue,
      );
    } catch (e) {
      debugPrint('[RadioQueueLoader] Auto-load failed: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Load radio tracks for a specific video ID.
  ///
  /// [videoId] - The video to get recommendations for
  /// [currentQueue] - Current queue to deduplicate against
  /// [maxTracks] - Maximum number of tracks to add (default 25)
  Future<void> loadRadioQueue({
    required String videoId,
    required List<MediaItem> currentQueue,
    int maxTracks = 25,
  }) async {
    try {
      debugPrint('[RadioQueueLoader] Loading radio queue for $videoId...');
      var radioTracks = await _innerTubeService.getRadioTracks(videoId);

      // Fallback to KSoft.Si if InnerTube returns empty
      if (radioTracks.isEmpty && _ksoftService != null && _ksoftService!.isConfigured) {
        debugPrint('[RadioQueueLoader] InnerTube empty, trying KSoft.Si...');
        radioTracks = await _getKSoftRecommendations(currentQueue);
      }

      if (radioTracks.isEmpty) {
        debugPrint('[RadioQueueLoader] No radio tracks found');
        return;
      }

      // Deduplicate
      final currentIds = currentQueue.map((m) => m.id).toSet();
      final tracksToAdd = radioTracks
          .where((t) => !currentIds.contains(t.videoId))
          .take(maxTracks)
          .toList();

      if (tracksToAdd.isNotEmpty) {
        final mediaItems = tracksToAdd
            .map((t) => MediaItemAdapter.fromYouTubeSong(t))
            .toList();

        debugPrint(
            '[RadioQueueLoader] Adding ${mediaItems.length} radio tracks');
        await _addToQueue(mediaItems);
      }
    } catch (e) {
      debugPrint('[RadioQueueLoader] Error loading radio queue: $e');
    }
  }

  /// Get recommendations from KSoft.Si based on recent queue items
  Future<List<YouTubeSong>> _getKSoftRecommendations(List<MediaItem> currentQueue) async {
    if (_ksoftService == null || !_ksoftService!.isConfigured) return [];

    try {
      // Get last 5 video IDs from queue for better recommendations
      final recentVideoIds = currentQueue
          .where((m) => m.extras?['isOnline'] == true || m.id.length == 11)
          .take(5)
          .map((m) => m.id)
          .toList();

      if (recentVideoIds.isEmpty) return [];

      debugPrint('[RadioQueueLoader] Getting KSoft recommendations for ${recentVideoIds.length} tracks');
      final recommendations = await _ksoftService!.getRecommendations(
        videoIds: recentVideoIds,
        limit: 5,
      );

      // Convert to YouTubeSong
      return recommendations
          .where((r) => r.youtubeId != null && r.youtubeId!.isNotEmpty)
          .map((r) => YouTubeSong(
                videoId: r.youtubeId!,
                title: r.name,
                artist: '', // KSoft doesn't always provide artist separately
                thumbnailUrl: r.youtubeThumbnail ?? r.spotifyAlbumArt ?? '',
              ))
          .toList();
    } catch (e) {
      debugPrint('[RadioQueueLoader] KSoft recommendations error: $e');
      return [];
    }
  }

  /// Reset debounce state when starting a new playback session
  void reset() {
    _lastLoadedVideoId = null;
    _lastLoadTime = null;
    _isLoading = false;
  }
}
