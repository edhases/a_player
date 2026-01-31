import 'dart:math';

import 'package:flutter/foundation.dart';

import 'innertube_base.dart';

/// Service for YouTube Music playback tracking and history reporting
class InnerTubeTrackingService extends InnerTubeBase {
  InnerTubeTrackingService({
    required super.authService,
    super.rateLimiter,
    super.logger,
    super.dio,
    super.parser,
  });

  /// Get the playback tracking URL for a video
  /// This URL is used to report playback to YouTube history
  Future<String?> getPlaybackTrackingUrl(String videoId) async {
    try {
      debugPrint('[InnerTubeTracking] getPlaybackTrackingUrl for $videoId');

      final body = {
        ...webContextBody(),
        'video_id': videoId,
        'playbackContext': {
          'contentPlaybackContext': {
            'signatureTimestamp': _getSignatureTimestamp(),
          }
        },
      };

      final response = await postRequest('/player', body);

      // Extract playbackTracking.videostatsPlaybackUrl.baseUrl
      final playbackTracking =
          response['playbackTracking'] as Map<String, dynamic>?;
      if (playbackTracking == null) {
        debugPrint('[InnerTubeTracking] No playbackTracking in response');
        return null;
      }

      final videostatsPlaybackUrl =
          playbackTracking['videostatsPlaybackUrl'] as Map<String, dynamic>?;
      final trackingUrl = videostatsPlaybackUrl?['baseUrl'] as String?;

      if (trackingUrl != null) {
        debugPrint('[InnerTubeTracking] Got tracking URL');
      }
      return trackingUrl;
    } catch (e) {
      debugPrint('[InnerTubeTracking] getPlaybackTrackingUrl error: $e');
      return null;
    }
  }

  /// Get signature timestamp (days since epoch) for player requests
  int _getSignatureTimestamp() {
    final now = DateTime.now();
    final epoch = DateTime(1970, 1, 1);
    return now.difference(epoch).inDays - 1;
  }

  /// Report playback to YouTube history
  /// Should be called after ~30 seconds of playback
  Future<bool> reportPlayback(String trackingUrl) async {
    try {
      final cpn = _generateCpn();
      final uri = Uri.parse(trackingUrl).replace(queryParameters: {
        ...Uri.parse(trackingUrl).queryParameters,
        'ver': '2',
        'c': 'WEB_REMIX',
        'cpn': cpn,
      });

      debugPrint('[InnerTubeTracking] Reporting playback with cpn=$cpn');

      await addAuthHeaders();

      // GET request to the tracking URL
      final response = await dio.getUri(uri);

      // 204 No Content = success, 200 also acceptable
      final success = response.statusCode == 204 || response.statusCode == 200;
      debugPrint(
          '[InnerTubeTracking] reportPlayback result: ${response.statusCode}, success=$success');
      return success;
    } catch (e) {
      debugPrint('[InnerTubeTracking] reportPlayback error: $e');
      return false;
    }
  }

  /// Generate random CPN (Client Playback Nonce) for tracking
  String _generateCpn() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_';
    final random = Random();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)])
        .join();
  }
}
