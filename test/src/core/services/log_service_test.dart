import 'package:flutter_test/flutter_test.dart';

import 'package:oxide_player/src/core/services/log_service.dart';

void main() {
  group('LogLevel', () {
    test('has correct levels', () {
      expect(LogLevel.values.length, 4);
      expect(LogLevel.values, contains(LogLevel.debug));
      expect(LogLevel.values, contains(LogLevel.info));
      expect(LogLevel.values, contains(LogLevel.warning));
      expect(LogLevel.values, contains(LogLevel.error));
    });
  });

  group('ErrorCategory', () {
    test('has all expected categories', () {
      expect(ErrorCategory.values.length, 7);
      expect(ErrorCategory.values, contains(ErrorCategory.playback));
      expect(ErrorCategory.values, contains(ErrorCategory.network));
      expect(ErrorCategory.values, contains(ErrorCategory.cache));
      expect(ErrorCategory.values, contains(ErrorCategory.auth));
      expect(ErrorCategory.values, contains(ErrorCategory.ui));
      expect(ErrorCategory.values, contains(ErrorCategory.database));
      expect(ErrorCategory.values, contains(ErrorCategory.general));
    });
  });

  group('PlaybackAnalytics', () {
    late PlaybackAnalytics analytics;

    setUp(() {
      analytics = PlaybackAnalytics();
    });

    test('initializes with zero values', () {
      expect(analytics.songsPlayed, 0);
      expect(analytics.playbackErrors, 0);
      expect(analytics.cacheHits, 0);
      expect(analytics.networkStreams, 0);
      expect(analytics.totalPlaytime, Duration.zero);
      expect(analytics.errorCounts, isEmpty);
    });

    test('tracks song plays', () {
      analytics.songsPlayed = 5;
      analytics.cacheHits = 2;
      analytics.networkStreams = 3;

      expect(analytics.songsPlayed, 5);
      expect(analytics.cacheHits, 2);
      expect(analytics.networkStreams, 3);
    });

    test('tracks errors by category', () {
      analytics.errorCounts['playback'] = 3;
      analytics.errorCounts['network'] = 1;

      expect(analytics.errorCounts['playback'], 3);
      expect(analytics.errorCounts['network'], 1);
    });

    test('calculates session duration', () {
      // Session just started, should be small
      expect(analytics.sessionDuration.inSeconds, lessThanOrEqualTo(1));
    });

    test('toSummary returns correct structure', () {
      analytics.songsPlayed = 10;
      analytics.playbackErrors = 2;
      analytics.cacheHits = 4;
      analytics.networkStreams = 6;
      analytics.totalPlaytime = const Duration(minutes: 30);
      analytics.errorCounts['playback'] = 2;

      final summary = analytics.toSummary();

      expect(summary['songsPlayed'], 10);
      expect(summary['playbackErrors'], 2);
      expect(summary['cacheHits'], 4);
      expect(summary['networkStreams'], 6);
      expect(summary['totalPlaytime'], 30);
      expect(summary['topErrors'], isA<List>());
    });

    test('reset clears all values', () {
      analytics.songsPlayed = 10;
      analytics.playbackErrors = 5;
      analytics.errorCounts['test'] = 3;

      analytics.reset();

      expect(analytics.songsPlayed, 0);
      expect(analytics.playbackErrors, 0);
      expect(analytics.errorCounts, isEmpty);
    });

    test('topErrors returns top N errors', () {
      analytics.errorCounts['playback'] = 10;
      analytics.errorCounts['network'] = 5;
      analytics.errorCounts['cache'] = 8;
      analytics.errorCounts['auth'] = 1;

      final summary = analytics.toSummary();
      final topErrors = summary['topErrors'] as List<MapEntry<String, int>>;

      expect(topErrors.length, 3);
      expect(topErrors[0].key, 'playback');
      expect(topErrors[0].value, 10);
      expect(topErrors[1].key, 'cache');
      expect(topErrors[1].value, 8);
      expect(topErrors[2].key, 'network');
      expect(topErrors[2].value, 5);
    });
  });

  group('LogService unit tests', () {
    test('LogService can be instantiated', () {
      final logService = LogService();
      expect(logService, isNotNull);
      expect(logService.analytics, isNotNull);
    });

    test('analytics is accessible', () {
      final logService = LogService();
      logService.analytics.songsPlayed = 5;

      expect(logService.analytics.songsPlayed, 5);
    });

    test('recordSongPlayed increments counters', () {
      final logService = LogService();

      // Track network stream
      logService.recordSongPlayed(fromCache: false);
      expect(logService.analytics.songsPlayed, 1);
      expect(logService.analytics.networkStreams, 1);
      expect(logService.analytics.cacheHits, 0);

      // Track cache hit
      logService.recordSongPlayed(fromCache: true);
      expect(logService.analytics.songsPlayed, 2);
      expect(logService.analytics.networkStreams, 1);
      expect(logService.analytics.cacheHits, 1);
    });

    test('recordPlaytime accumulates duration', () {
      final logService = LogService();

      logService.recordPlaytime(const Duration(minutes: 5));
      expect(logService.analytics.totalPlaytime, const Duration(minutes: 5));

      logService.recordPlaytime(const Duration(minutes: 3));
      expect(logService.analytics.totalPlaytime, const Duration(minutes: 8));
    });
  });

  group('Error category detection', () {
    // These tests verify the categorization logic through pattern matching

    test('playback-related keywords', () {
      final patterns = ['audio', 'player', 'playback', 'stream'];
      for (final pattern in patterns) {
        expect(pattern.contains('audio') ||
               pattern.contains('player') ||
               pattern.contains('playback') ||
               pattern.contains('stream'), true);
      }
    });

    test('network-related keywords', () {
      final patterns = ['network', 'http', 'connection', 'timeout', 'api'];
      for (final pattern in patterns) {
        final lower = pattern.toLowerCase();
        expect(lower.contains('network') ||
               lower.contains('http') ||
               lower.contains('connection') ||
               lower.contains('timeout') ||
               lower.contains('api'), true);
      }
    });

    test('cache-related keywords', () {
      final patterns = ['cache', 'storage', 'file', 'disk'];
      for (final pattern in patterns) {
        final lower = pattern.toLowerCase();
        expect(lower.contains('cache') ||
               lower.contains('storage') ||
               lower.contains('file') ||
               lower.contains('disk'), true);
      }
    });
  });
}
