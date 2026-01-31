import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audio_service/audio_service.dart';

import 'package:oxide_player/src/core/services/audio/audio.dart';
import 'package:oxide_player/src/core/services/innertube/innertube.dart';
import 'package:oxide_player/src/domain/entities/youtube_song.dart';

// Mocks
class MockInnerTubeService extends Mock implements InnerTubeService {}

void main() {
  group('PlaybackHistoryReporter', () {
    late MockInnerTubeService mockInnerTube;
    late PlaybackHistoryReporter reporter;

    setUp(() {
      mockInnerTube = MockInnerTubeService();
      reporter = PlaybackHistoryReporter(innerTubeService: mockInnerTube);
    });

    test('reports playback for valid video', () {
      when(() => mockInnerTube.getPlaybackTrackingUrl(any()))
          .thenAnswer((_) async => 'https://tracking.url');
      when(() => mockInnerTube.reportPlayback(any()))
          .thenAnswer((_) async => true);

      reporter.reportPlayback(
        currentIndex: 0,
        videoId: 'test123',
        title: 'Test Song',
        isCached: false,
      );

      // Fire-and-forget, so we verify async call was made
      verify(() => mockInnerTube.getPlaybackTrackingUrl('test123')).called(1);
    });

    test('skips reporting if videoId is null', () {
      reporter.reportPlayback(
        currentIndex: 0,
        videoId: null,
        title: 'Test Song',
        isCached: false,
      );

      verifyNever(() => mockInnerTube.getPlaybackTrackingUrl(any()));
    });

    test('skips reporting if currentIndex is null', () {
      reporter.reportPlayback(
        currentIndex: null,
        videoId: 'test123',
        title: 'Test Song',
        isCached: false,
      );

      verifyNever(() => mockInnerTube.getPlaybackTrackingUrl(any()));
    });

    test('does not report same video twice', () {
      when(() => mockInnerTube.getPlaybackTrackingUrl(any()))
          .thenAnswer((_) async => 'https://tracking.url');
      when(() => mockInnerTube.reportPlayback(any()))
          .thenAnswer((_) async => true);

      reporter.reportPlayback(
        currentIndex: 0,
        videoId: 'test123',
        title: 'Test Song',
        isCached: false,
      );

      reporter.reportPlayback(
        currentIndex: 1, // Different index
        videoId: 'test123', // Same video ID
        title: 'Test Song',
        isCached: false,
      );

      // Should only be called once
      verify(() => mockInnerTube.getPlaybackTrackingUrl('test123')).called(1);
    });

    test('does not report same index twice', () {
      when(() => mockInnerTube.getPlaybackTrackingUrl(any()))
          .thenAnswer((_) async => 'https://tracking.url');
      when(() => mockInnerTube.reportPlayback(any()))
          .thenAnswer((_) async => true);

      reporter.reportPlayback(
        currentIndex: 0,
        videoId: 'test123',
        title: 'Test Song',
        isCached: false,
      );

      reporter.reportPlayback(
        currentIndex: 0, // Same index
        videoId: 'test456', // Different video (edge case)
        title: 'Test Song 2',
        isCached: false,
      );

      // Should only be called once (first one)
      verify(() => mockInnerTube.getPlaybackTrackingUrl(any())).called(1);
    });

    test('reset clears reported state', () {
      when(() => mockInnerTube.getPlaybackTrackingUrl(any()))
          .thenAnswer((_) async => 'https://tracking.url');
      when(() => mockInnerTube.reportPlayback(any()))
          .thenAnswer((_) async => true);

      reporter.reportPlayback(
        currentIndex: 0,
        videoId: 'test123',
        title: 'Test Song',
        isCached: false,
      );

      reporter.reset();

      reporter.reportPlayback(
        currentIndex: 0,
        videoId: 'test123',
        title: 'Test Song',
        isCached: false,
      );

      // Should be called twice after reset
      verify(() => mockInnerTube.getPlaybackTrackingUrl('test123')).called(2);
    });

    test('hasBeenReported returns correct state', () {
      when(() => mockInnerTube.getPlaybackTrackingUrl(any()))
          .thenAnswer((_) async => 'https://tracking.url');
      when(() => mockInnerTube.reportPlayback(any()))
          .thenAnswer((_) async => true);

      expect(reporter.hasBeenReported('test123'), isFalse);

      reporter.reportPlayback(
        currentIndex: 0,
        videoId: 'test123',
        title: 'Test Song',
        isCached: false,
      );

      expect(reporter.hasBeenReported('test123'), isTrue);
      expect(reporter.hasBeenReported('other'), isFalse);
    });
  });

  group('RadioQueueLoader', () {
    late MockInnerTubeService mockInnerTube;
    late List<MediaItem> addedItems;
    late RadioQueueLoader loader;

    setUp(() {
      mockInnerTube = MockInnerTubeService();
      addedItems = [];
      loader = RadioQueueLoader(
        innerTubeService: mockInnerTube,
        addToQueue: (items) async {
          addedItems.addAll(items);
        },
      );
    });

    test('checkAndLoadMore skips if loop enabled', () async {
      await loader.checkAndLoadMore(
        currentQueue: [
          MediaItem(id: 'test1', title: 'Test', album: ''),
        ],
        currentIndex: 0,
        loopEnabled: true,
      );

      verifyNever(() => mockInnerTube.getRadioTracks(any()));
    });

    test('checkAndLoadMore skips if not near end', () async {
      final queue = List.generate(
        10,
        (i) => MediaItem(
          id: 'test$i',
          title: 'Test $i',
          album: '',
          extras: {'isOnline': true},
        ),
      );

      await loader.checkAndLoadMore(
        currentQueue: queue,
        currentIndex: 3, // Not near end (needs to be >= 7 for 10-item queue)
        loopEnabled: false,
      );

      verifyNever(() => mockInnerTube.getRadioTracks(any()));
    });

    test('checkAndLoadMore loads when near end', () async {
      when(() => mockInnerTube.getRadioTracks(any()))
          .thenAnswer((_) async => []);

      final queue = List.generate(
        10,
        (i) => MediaItem(
          id: 'test$i',
          title: 'Test $i',
          album: '',
          extras: {'isOnline': true},
        ),
      );

      await loader.checkAndLoadMore(
        currentQueue: queue,
        currentIndex: 8, // Near end (>= 7)
        loopEnabled: false,
      );

      verify(() => mockInnerTube.getRadioTracks('test9')).called(1);
    });

    test('loadRadioQueue deduplicates tracks', () async {
      when(() => mockInnerTube.getRadioTracks(any())).thenAnswer((_) async => [
            YouTubeSong(
              videoId: 'existing1',
              title: 'Existing Track',
              artist: 'Artist',
              thumbnailUrl: '',
            ),
            YouTubeSong(
              videoId: 'new1',
              title: 'New Track',
              artist: 'Artist',
              thumbnailUrl: '',
            ),
          ]);

      final existingQueue = [
        MediaItem(id: 'existing1', title: 'Existing', album: ''),
      ];

      await loader.loadRadioQueue(
        videoId: 'seed',
        currentQueue: existingQueue,
      );

      // Only the new track should be added
      expect(addedItems.length, 1);
      expect(addedItems.first.extras?['videoId'], 'new1');
    });

    test('loadRadioQueue respects maxTracks', () async {
      when(() => mockInnerTube.getRadioTracks(any())).thenAnswer((_) async =>
          List.generate(
              50,
              (i) => YouTubeSong(
                    videoId: 'track$i',
                    title: 'Track $i',
                    artist: 'Artist',
                    thumbnailUrl: '',
                  )));

      await loader.loadRadioQueue(
        videoId: 'seed',
        currentQueue: [],
        maxTracks: 10,
      );

      expect(addedItems.length, 10);
    });

    test('checkAndLoadMore debounces repeated calls for same video', () async {
      when(() => mockInnerTube.getRadioTracks(any()))
          .thenAnswer((_) async => []);

      final queue = [
        MediaItem(
          id: 'test1',
          title: 'Test',
          album: '',
          extras: {'isOnline': true},
        ),
      ];

      // First call should load
      await loader.checkAndLoadMore(
        currentQueue: queue,
        currentIndex: 0,
        loopEnabled: false,
      );

      // Second call should be debounced
      await loader.checkAndLoadMore(
        currentQueue: queue,
        currentIndex: 0,
        loopEnabled: false,
      );

      // Should only be called once
      verify(() => mockInnerTube.getRadioTracks('test1')).called(1);
    });

    test('reset clears debounce state', () async {
      when(() => mockInnerTube.getRadioTracks(any()))
          .thenAnswer((_) async => []);

      final queue = [
        MediaItem(
          id: 'test1',
          title: 'Test',
          album: '',
          extras: {'isOnline': true},
        ),
      ];

      // First call
      await loader.checkAndLoadMore(
        currentQueue: queue,
        currentIndex: 0,
        loopEnabled: false,
      );

      // Reset debounce
      loader.reset();

      // Should load again after reset
      await loader.checkAndLoadMore(
        currentQueue: queue,
        currentIndex: 0,
        loopEnabled: false,
      );

      verify(() => mockInnerTube.getRadioTracks('test1')).called(2);
    });
  });
}
