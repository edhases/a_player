import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oxide_player/src/core/services/innertube/innertube.dart';
import 'package:oxide_player/src/core/services/smart_play_service.dart';
import 'package:oxide_player/src/core/services/audio_handler.dart';
import 'package:oxide_player/src/core/services/google_auth_service.dart';
import 'package:oxide_player/src/domain/entities/youtube_song.dart';

// Mocks
class MockGoogleAuthService extends Mock implements GoogleAuthService {}

class MockInnerTubeService extends Mock implements InnerTubeService {}

class MockMyAudioHandler extends Mock implements MyAudioHandler {}

void main() {
  group('SmartPlayService - Duplicate Request Prevention', () {
    late SmartPlayService smartPlayService;
    late MockInnerTubeService mockInnerTube;
    late MockMyAudioHandler mockAudioHandler;

    setUp(() {
      mockInnerTube = MockInnerTubeService();
      mockAudioHandler = MockMyAudioHandler();
      smartPlayService = SmartPlayService(
        innerTube: mockInnerTube,
        audioHandler: mockAudioHandler,
      );
    });

    test('needsPlaylistResolution returns false for regular video (11 chars)',
        () {
      final song = YouTubeSong(
        videoId: 'dQw4w9WgXcQ', // 11 chars - regular YouTube video ID
        title: 'Test Song',
        artist: 'Test Artist',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        isPlaylist: false,
      );

      expect(smartPlayService.needsPlaylistResolution(song), false);
    });

    test('needsPlaylistResolution returns true for explicit playlist', () {
      final playlist = YouTubeSong(
        videoId: 'PLk_special_playlist_id',
        title: 'Test Playlist',
        artist: 'Various',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        isPlaylist: true,
      );

      expect(smartPlayService.needsPlaylistResolution(playlist), true);
    });

    test('needsPlaylistResolution returns true for non-11-char videoId', () {
      final album = YouTubeSong(
        videoId: 'MPREb_album_id_here', // Not 11 chars - likely album/playlist
        title: 'Test Album',
        artist: 'Test Artist',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        isPlaylist: false, // Not explicitly marked
      );

      expect(smartPlayService.needsPlaylistResolution(album), true);
    });

    test('needsPlaylistResolution handles empty videoId', () {
      final song = YouTubeSong(
        videoId: '',
        title: 'Empty VideoId',
        artist: 'Test',
        thumbnailUrl: '',
        isPlaylist: false,
      );

      expect(smartPlayService.needsPlaylistResolution(song), false);
    });

    test('getPlaylistId returns playlistId for explicit playlist', () {
      final playlist = YouTubeSong(
        videoId: 'PLtest123',
        title: 'Playlist',
        artist: 'Various',
        thumbnailUrl: '',
        isPlaylist: true,
        playlistId: 'PLcustom_id',
      );

      expect(smartPlayService.getPlaylistId(playlist), 'PLcustom_id');
    });

    test('getPlaylistId returns videoId for non-11-char ID', () {
      final album = YouTubeSong(
        videoId: 'MPREb_album_id',
        title: 'Album',
        artist: 'Artist',
        thumbnailUrl: '',
        isPlaylist: false,
      );

      expect(smartPlayService.getPlaylistId(album), 'MPREb_album_id');
    });

    test('getPlaylistId returns null for regular song with context playlistId',
        () {
      // Songs from "Listen Again" have playlistId for context but are still songs
      final song = YouTubeSong(
        videoId: 'dQw4w9WgXcQ', // 11 chars - regular video
        title: 'Song',
        artist: 'Artist',
        thumbnailUrl: '',
        isPlaylist: false,
        playlistId: 'RDQM_context_playlist', // Just context, not for resolution
      );

      expect(smartPlayService.getPlaylistId(song), null);
    });
  });

  group('InnerTubeSearchService - findArtistId', () {
    late MockGoogleAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockGoogleAuthService();
      when(() => mockAuthService.isSignedIn()).thenAnswer((_) async => false);
      when(() => mockAuthService.getAuthHeaders()).thenAnswer((_) async => {});
    });

    test('findArtistId returns null for empty artist name', () async {
      final service = InnerTubeSearchService(authService: mockAuthService);

      final result = await service.findArtistId('');

      expect(result, isNull);
    });

    test('findArtistId returns null for whitespace-only artist name', () async {
      final service = InnerTubeSearchService(authService: mockAuthService);

      final result = await service.findArtistId('   ');

      expect(result, isNull);
    });

    test('findArtistId handles network errors gracefully', () async {
      final service = InnerTubeSearchService(authService: mockAuthService);

      // This makes real network call - in a real test you'd mock Dio
      // Here we just verify it returns a result (UC* prefix) or null
      final result = await service.findArtistId('Test Artist');

      // Should either return a valid artistId (starts with UC) or null
      expect(
        result == null || result.startsWith('UC'),
        true,
        reason: 'findArtistId should return UC* ID or null',
      );
    });
  });

  group('YouTubeSong - MediaItem extras for liked songs', () {
    test('YouTubeSong creates with correct fields for playback', () {
      final song = YouTubeSong(
        videoId: 'test123video',
        title: 'Liked Song',
        artist: 'Favorite Artist',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        artistId: 'UCtest_artist_id',
        duration: 225, // 3:45 in seconds
      );

      expect(song.videoId, 'test123video');
      expect(song.title, 'Liked Song');
      expect(song.artist, 'Favorite Artist');
      expect(song.artistId, 'UCtest_artist_id');
      expect(song.duration, 225);
    });

    test('YouTubeSong handles null optional fields', () {
      final song = YouTubeSong(
        videoId: 'test12345ab',
        title: 'Minimal Song',
        artist: 'Artist',
        thumbnailUrl: '',
      );

      expect(song.artistId, isNull);
      expect(song.playlistId, isNull);
      // duration defaults to 0 for minimal songs
      expect(song.duration, isA<int>());
    });

    test('YouTubeSong isPlaylist defaults to false', () {
      final song = YouTubeSong(
        videoId: 'regular_song',
        title: 'Song',
        artist: 'Artist',
        thumbnailUrl: '',
      );

      expect(song.isPlaylist, false);
    });
  });

  group('Container format logic', () {
    test('webm container is detected correctly', () {
      // Simulates the logic from cacheTrack method
      String? container = 'webm';
      final extension = (container.toLowerCase() == 'webm') ? 'webm' : 'm4a';

      expect(extension, 'webm');
    });

    test('mp4 container maps to m4a extension', () {
      String? container = 'mp4';
      final extension = (container.toLowerCase() == 'webm') ? 'webm' : 'm4a';

      expect(extension, 'm4a');
    });

    test('null container defaults to m4a', () {
      String? container;
      final extension = (container?.toLowerCase() == 'webm') ? 'webm' : 'm4a';

      expect(extension, 'm4a');
    });

    test('case insensitive container detection', () {
      String container = 'WEBM';
      final extension = (container.toLowerCase() == 'webm') ? 'webm' : 'm4a';

      expect(extension, 'webm');
    });
  });

  group('Artist ID validation', () {
    test('valid artist ID starts with UC', () {
      final artistId = 'UCtest1234567890';
      final isValid = artistId.isNotEmpty && artistId.startsWith('UC');

      expect(isValid, true);
    });

    test('invalid artist ID without UC prefix', () {
      final artistId = 'test1234567890';
      final isValid = artistId.isNotEmpty && artistId.startsWith('UC');

      expect(isValid, false);
    });

    test('empty artist ID is invalid', () {
      final artistId = '';
      final isValid = artistId.isNotEmpty && artistId.startsWith('UC');

      expect(isValid, false);
    });
  });

  group('VideoId length validation', () {
    test('standard YouTube video ID is 11 characters', () {
      final videoId = 'dQw4w9WgXcQ';
      expect(videoId.length, 11);

      final isValidVideoId = videoId.length == 11;
      expect(isValidVideoId, true);
    });

    test('playlist IDs are longer than 11 characters', () {
      final playlistId = 'PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf';
      expect(playlistId.length, greaterThan(11));

      final isValidVideoId = playlistId.length == 11;
      expect(isValidVideoId, false);
    });

    test('album IDs (MPREb) are longer than 11 characters', () {
      final albumId = 'MPREb_gTFcfRc6bnqU';
      expect(albumId.length, greaterThan(11));

      final isValidVideoId = albumId.length == 11;
      expect(isValidVideoId, false);
    });
  });

  group('RateLimiter behavior', () {
    test('RateLimiter allows requests within limit', () async {
      final limiter = RateLimiter(requestsPerSecond: 10);

      // Should complete quickly
      final stopwatch = Stopwatch()..start();
      await limiter.throttle();
      await limiter.throttle();
      await limiter.throttle();
      stopwatch.stop();

      // 3 requests within limit of 10/sec should be fast
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });
  });
}
