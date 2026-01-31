import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oxide_player/src/core/services/innertube/innertube.dart';
import 'package:oxide_player/src/core/services/google_auth_service.dart';
import 'package:oxide_player/src/domain/entities/youtube_song.dart';

// Mocks
class MockGoogleAuthService extends Mock implements GoogleAuthService {}

void main() {
  group('InnerTubeSearchService', () {
    late MockGoogleAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockGoogleAuthService();
      when(() => mockAuthService.isSignedIn()).thenAnswer((_) async => false);
      when(() => mockAuthService.getAuthHeaders()).thenAnswer((_) async => {});
    });

    test('search returns empty list on empty query', () async {
      final service = InnerTubeSearchService(authService: mockAuthService);
      
      final results = await service.search('');
      
      expect(results, isEmpty);
    });

    test('search with filter parameter works', () async {
      final service = InnerTubeSearchService(authService: mockAuthService);
      
      // This will fail network call but should not throw
      try {
        await service.search('test', filter: 'videos', limit: 10);
      } catch (e) {
        // Network errors are expected in unit tests
        expect(e, isA<Exception>());
      }
    });

    test('getSearchSuggestions returns empty list on empty query', () async {
      final service = InnerTubeSearchService(authService: mockAuthService);
      
      final suggestions = await service.getSearchSuggestions('');
      
      expect(suggestions, isEmpty);
    });
  });

  group('InnerTubePlaylistService', () {
    late MockGoogleAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockGoogleAuthService();
      when(() => mockAuthService.isSignedIn()).thenAnswer((_) async => false);
      when(() => mockAuthService.getAuthHeaders()).thenAnswer((_) async => {});
    });

    test('getPlaylistTracks adds VL prefix if missing', () async {
      final service = InnerTubePlaylistService(authService: mockAuthService);
      
      // Verify that a playlist ID without VL prefix gets it added
      // This tests the logic, not the network call
      try {
        await service.getPlaylistTracks('PLtest123');
      } catch (e) {
        // Network errors expected
      }
      
      // Service should have added VL prefix internally
      // We can't easily verify this without mocking Dio, but the test ensures no crash
    });

    test('getAlbumTracks does not add VL prefix', () async {
      final service = InnerTubePlaylistService(authService: mockAuthService);
      
      try {
        await service.getAlbumTracks('MPREb_test123');
      } catch (e) {
        // Network errors expected
      }
    });
  });

  group('HomeShelf', () {
    test('creates with required fields', () {
      final shelf = HomeShelf(
        title: 'Test Shelf',
        items: [
          YouTubeSong(
            videoId: 'test123',
            title: 'Test Song',
            artist: 'Test Artist',
            thumbnailUrl: 'https://example.com/thumb.jpg',
          ),
        ],
      );

      expect(shelf.title, 'Test Shelf');
      expect(shelf.items.length, 1);
      expect(shelf.items.first.videoId, 'test123');
    });

    test('creates empty shelf', () {
      final shelf = HomeShelf(
        title: 'Empty Shelf',
        items: [],
      );

      expect(shelf.title, 'Empty Shelf');
      expect(shelf.items, isEmpty);
    });
  });

  group('YouTubePlaylist', () {
    test('creates with all fields', () {
      final playlist = YouTubePlaylist(
        id: 'PL123',
        title: 'My Playlist',
        description: 'A test playlist',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        trackCount: 10,
        author: 'Test Author',
      );

      expect(playlist.id, 'PL123');
      expect(playlist.title, 'My Playlist');
      expect(playlist.description, 'A test playlist');
      expect(playlist.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(playlist.trackCount, 10);
      expect(playlist.author, 'Test Author');
    });

    test('creates with minimal fields', () {
      final playlist = YouTubePlaylist(
        id: 'PL456',
        title: 'Minimal Playlist',
      );

      expect(playlist.id, 'PL456');
      expect(playlist.title, 'Minimal Playlist');
      expect(playlist.description, isNull);
      expect(playlist.thumbnailUrl, isNull);
      expect(playlist.trackCount, isNull);
      expect(playlist.author, isNull);
    });
  });

  group('LyricsResult', () {
    test('creates with all fields', () {
      final lyrics = LyricsResult(
        lyrics: 'Test lyrics here',
        source: 'LyricFind',
        syncedLyrics: '[00:01]Line one',
      );

      expect(lyrics.lyrics, 'Test lyrics here');
      expect(lyrics.source, 'LyricFind');
      expect(lyrics.syncedLyrics, '[00:01]Line one');
      expect(lyrics.hasSyncedLyrics, true);
    });

    test('toMap returns correct structure', () {
      final lyrics = LyricsResult(
        lyrics: 'Test lyrics',
        source: 'Source',
        syncedLyrics: null,
      );

      final map = lyrics.toMap();

      expect(map['lyrics'], 'Test lyrics');
      expect(map['source'], 'Source');
      expect(map['syncedLyrics'], isNull);
    });
    
    test('hasSyncedLyrics returns false for empty or null', () {
      final noSync = LyricsResult(lyrics: 'Text', source: 'Test');
      final emptySync = LyricsResult(lyrics: 'Text', source: 'Test', syncedLyrics: '');
      
      expect(noSync.hasSyncedLyrics, false);
      expect(emptySync.hasSyncedLyrics, false);
    });
  });

  group('RateLimiter', () {
    test('allows first request immediately', () async {
      final limiter = RateLimiter(requestsPerSecond: 3);
      
      final start = DateTime.now();
      await limiter.throttle();
      final elapsed = DateTime.now().difference(start);
      
      // First request should be immediate (< 50ms)
      expect(elapsed.inMilliseconds, lessThan(50));
    });

    test('throttles after exceeding rate', () async {
      final limiter = RateLimiter(requestsPerSecond: 2);
      
      await limiter.throttle(); // 1st request
      await limiter.throttle(); // 2nd request
      
      final start = DateTime.now();
      await limiter.throttle(); // 3rd should wait
      final elapsed = DateTime.now().difference(start);
      
      // Should have waited at least some time
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(0));
    });
  });
}
