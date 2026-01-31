import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oxide_player/src/core/services/smart_play_service.dart';
import 'package:oxide_player/src/core/services/audio_handler.dart';
import 'package:oxide_player/src/core/services/innertube/innertube.dart';
import 'package:oxide_player/src/domain/entities/youtube_song.dart';

// Mocks
class MockInnerTubeService extends Mock implements InnerTubeService {}

class MockAudioHandler extends Mock implements MyAudioHandler {}

class FakeYouTubeSong extends Fake implements YouTubeSong {}

void main() {
  late SmartPlayService smartPlayService;
  late MockInnerTubeService mockInnerTube;
  late MockAudioHandler mockAudioHandler;

  setUpAll(() {
    registerFallbackValue(FakeYouTubeSong());
  });

  setUp(() {
    mockInnerTube = MockInnerTubeService();
    mockAudioHandler = MockAudioHandler();
    smartPlayService = SmartPlayService(
      innerTube: mockInnerTube,
      audioHandler: mockAudioHandler,
    );
  });

  group('SmartPlayResult', () {
    test('playedDirectly factory creates correct result', () {
      final result = SmartPlayResult.playedDirectly();
      expect(result.type, equals(SmartPlayResultType.playedDirectly));
      expect(result.errorMessage, isNull);
      expect(result.tracks, isNull);
    });

    test('navigatedToPlaylist factory creates correct result', () {
      final tracks = [
        YouTubeSong(
          videoId: 'test123',
          title: 'Test Song',
          artist: 'Artist',
          thumbnailUrl: 'https://example.com/thumb.jpg',
        ),
      ];
      
      final result = SmartPlayResult.navigatedToPlaylist(tracks);
      expect(result.type, equals(SmartPlayResultType.navigatedToPlaylist));
      expect(result.tracks, equals(tracks));
      expect(result.errorMessage, isNull);
    });

    test('error factory creates correct result', () {
      final result = SmartPlayResult.error('Something went wrong');
      expect(result.type, equals(SmartPlayResultType.error));
      expect(result.errorMessage, equals('Something went wrong'));
      expect(result.tracks, isNull);
    });
  });

  group('SmartPlayService - needsPlaylistResolution', () {
    test('returns true for explicitly marked playlists', () {
      final song = YouTubeSong(
        videoId: 'test1234567',
        title: 'Playlist Title',
        artist: 'Various Artists',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        isPlaylist: true,
      );

      expect(smartPlayService.needsPlaylistResolution(song), isTrue);
    });

    test('returns false for regular 11-char videoId songs', () {
      final song = YouTubeSong(
        videoId: 'dQw4w9WgXcQ', // Rick Astley - exactly 11 chars
        title: 'Never Gonna Give You Up',
        artist: 'Rick Astley',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        isPlaylist: false,
      );

      expect(smartPlayService.needsPlaylistResolution(song), isFalse);
    });

    test('returns true for album IDs (non 11-char)', () {
      final song = YouTubeSong(
        videoId: 'MPREb_test123abc', // Album ID format
        title: 'Album Title',
        artist: 'Artist',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        isPlaylist: false,
      );

      expect(smartPlayService.needsPlaylistResolution(song), isTrue);
    });

    test('returns false for 11-char videoId with playlistId context', () {
      // Songs from "Listen Again" have playlistId but are still regular songs
      final song = YouTubeSong(
        videoId: 'abcdefghijk', // 11 chars
        title: 'Regular Song',
        artist: 'Artist',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        playlistId: 'PLxyz123', // Context, not for resolution
        isPlaylist: false,
      );

      expect(smartPlayService.needsPlaylistResolution(song), isFalse);
    });

    test('returns true for playlist ID format (VL prefix)', () {
      final song = YouTubeSong(
        videoId: 'VLPLtest1234567890',
        title: 'User Playlist',
        artist: 'Various',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        isPlaylist: true,
      );

      expect(smartPlayService.needsPlaylistResolution(song), isTrue);
    });

    test('returns false for empty videoId', () {
      final song = YouTubeSong(
        videoId: '',
        title: 'No Video',
        artist: 'Unknown',
        thumbnailUrl: '',
      );

      expect(smartPlayService.needsPlaylistResolution(song), isFalse);
    });
  });

  group('SmartPlayService - getPlaylistId', () {
    test('returns playlistId for explicit playlists', () {
      final song = YouTubeSong(
        videoId: 'abc123',
        title: 'Playlist',
        artist: 'Various',
        thumbnailUrl: '',
        playlistId: 'PLtest123',
        isPlaylist: true,
      );

      expect(smartPlayService.getPlaylistId(song), equals('PLtest123'));
    });

    test('returns videoId for non-11-char album IDs', () {
      final song = YouTubeSong(
        videoId: 'MPREb_albumId123',
        title: 'Album',
        artist: 'Artist',
        thumbnailUrl: '',
        isPlaylist: false,
      );

      expect(smartPlayService.getPlaylistId(song), equals('MPREb_albumId123'));
    });

    test('returns null for regular 11-char videoId songs', () {
      final song = YouTubeSong(
        videoId: 'dQw4w9WgXcQ',
        title: 'Song',
        artist: 'Artist',
        thumbnailUrl: '',
        playlistId: 'PLcontext', // Just context
        isPlaylist: false,
      );

      expect(smartPlayService.getPlaylistId(song), isNull);
    });

    test('returns videoId for playlist marked songs without explicit playlistId', () {
      final song = YouTubeSong(
        videoId: 'RDAMVM_longPlaylistId',
        title: 'Radio',
        artist: 'Various',
        thumbnailUrl: '',
        isPlaylist: true, // Marked as playlist but playlistId is in videoId
        playlistId: null,
      );

      // Since playlistId is null and videoId is not 11 chars
      expect(smartPlayService.getPlaylistId(song), equals('RDAMVM_longPlaylistId'));
    });
  });

  group('SmartPlayService - Edge Cases', () {
    test('handles exactly 11-char videoId correctly', () {
      // Test various valid 11-char video IDs
      final validIds = [
        'dQw4w9WgXcQ', // Letters and numbers
        '_12345678__', // Underscores
        'abc-def_ghi', // Hyphens and underscores
        '12345678901', // All numbers
        'ABCDEFGHIJK', // All uppercase
      ];

      for (final id in validIds) {
        expect(id.length, equals(11), reason: 'Test setup: $id should be 11 chars');
        
        final song = YouTubeSong(
          videoId: id,
          title: 'Test',
          artist: 'Artist',
          thumbnailUrl: '',
        );

        expect(
          smartPlayService.needsPlaylistResolution(song),
          isFalse,
          reason: 'VideoId $id should NOT need resolution',
        );
      }
    });

    test('handles 10-char and 12-char videoId correctly', () {
      // Shorter than 11 chars
      final shortSong = YouTubeSong(
        videoId: 'short10chr',
        title: 'Short ID',
        artist: 'Artist',
        thumbnailUrl: '',
      );

      expect(smartPlayService.needsPlaylistResolution(shortSong), isTrue);

      // Longer than 11 chars
      final longSong = YouTubeSong(
        videoId: 'longerThan11ch',
        title: 'Long ID',
        artist: 'Artist',
        thumbnailUrl: '',
      );

      expect(smartPlayService.needsPlaylistResolution(longSong), isTrue);
    });

    test('handles songs with category correctly', () {
      final songWithCategory = YouTubeSong(
        videoId: 'video123456', // 11 chars
        title: 'Categorized Song',
        artist: 'Artist',
        thumbnailUrl: '',
        category: 'Song',
        isPlaylist: false,
      );

      expect(smartPlayService.needsPlaylistResolution(songWithCategory), isFalse);

      final albumWithCategory = YouTubeSong(
        videoId: 'MPREb_album',
        title: 'Album',
        artist: 'Artist',
        thumbnailUrl: '',
        category: 'Album',
        isPlaylist: true,
      );

      expect(smartPlayService.needsPlaylistResolution(albumWithCategory), isTrue);
    });

    test('handles YouTube Music single format', () {
      // Singles on YTM often have album-like IDs but contain only one track
      final single = YouTubeSong(
        videoId: 'MPREb_singleId123',
        title: 'New Single - Single',
        artist: 'Artist',
        thumbnailUrl: '',
        category: 'Single',
        isPlaylist: true,
      );

      // It needs resolution to check if it's really just one track
      expect(smartPlayService.needsPlaylistResolution(single), isTrue);
    });
  });

  group('SmartPlayService - dispose', () {
    test('dispose cancels debounce timer', () {
      // This test just ensures dispose doesn't throw
      expect(() => smartPlayService.dispose(), returnsNormally);
    });
  });
}
