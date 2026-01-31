import 'package:flutter/foundation.dart';

import '../innertube/innertube.dart';

/// Handles reporting playback history to YouTube Music.
///
/// Tracks when songs have been played for 30+ seconds and reports
/// them to YouTube for history/recommendations.
class PlaybackHistoryReporter {
  final InnerTubeService _innerTubeService;

  // Track reported videos to avoid duplicates
  final Set<String> _reportedVideoIds = {};
  int? _lastReportedIndex;

  PlaybackHistoryReporter({
    required InnerTubeService innerTubeService,
  }) : _innerTubeService = innerTubeService;

  /// Report playback for a YouTube track.
  ///
  /// Call this after 30+ seconds of playback.
  /// Will skip if already reported in this session.
  void reportPlayback({
    required int? currentIndex,
    required String? videoId,
    required String? title,
    required bool? isCached,
  }) {
    if (currentIndex == null || videoId == null) return;

    // Don't report same track twice in this session
    if (_lastReportedIndex == currentIndex) return;
    if (_reportedVideoIds.contains(videoId)) return;

    debugPrint(
        '[PlaybackHistoryReporter] Reporting: $videoId ($title), Cached: ${isCached ?? false}');

    _lastReportedIndex = currentIndex;
    _reportedVideoIds.add(videoId);

    // Fire-and-forget reporting
    _innerTubeService.getPlaybackTrackingUrl(videoId).then((trackingUrl) {
      if (trackingUrl != null) {
        _innerTubeService.reportPlayback(trackingUrl);
      }
    }).catchError((e) {
      debugPrint('[PlaybackHistoryReporter] Error reporting: $e');
    });
  }

  /// Reset reported state (e.g., for new session)
  void reset() {
    _reportedVideoIds.clear();
    _lastReportedIndex = null;
  }

  /// Check if a video has been reported
  bool hasBeenReported(String videoId) => _reportedVideoIds.contains(videoId);
}
