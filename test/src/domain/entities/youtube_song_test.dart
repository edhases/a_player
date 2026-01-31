import 'package:flutter_test/flutter_test.dart';

import 'package:oxide_player/src/domain/entities/youtube_song.dart';

void main() {
  group('YouTubeSong', () {
    test('creates with required fields', () {
      final song = YouTubeSong(
        videoId: 'abc123',
        title: 'Test Song',
        artist: 'Test Artist',
        thumbnailUrl: 'https://example.com/thumb.jpg',
      );

      expect(song.videoId, 'abc123');
      expect(song.title, 'Test Song');
      expect(song.artist, 'Test Artist');
      expect(song.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(song.isPlaylist, false);
      expect(song.duration, 0);
    });

    test('creates with all optional fields', () {
      final song = YouTubeSong(
        videoId: 'xyz789',
        title: 'Full Song',
        artist: 'Full Artist',
        thumbnailUrl: 'https://example.com/full.jpg',
        duration: 180,
        artistId: 'artist123',
        playlistId: 'playlist456',
        isPlaylist: true,
        category: 'Rock',
      );

      expect(song.videoId, 'xyz789');
      expect(song.duration, 180);
      expect(song.artistId, 'artist123');
      expect(song.playlistId, 'playlist456');
      expect(song.isPlaylist, true);
      expect(song.category, 'Rock');
    });

    test('copyWith creates new instance with updated fields', () {
      final original = YouTubeSong(
        videoId: 'orig123',
        title: 'Original',
        artist: 'Original Artist',
        thumbnailUrl: 'https://example.com/orig.jpg',
      );

      final copied = original.copyWith(
        title: 'Updated Title',
        duration: 200,
      );

      // Original unchanged
      expect(original.title, 'Original');
      expect(original.duration, 0);

      // Copy has new values
      expect(copied.title, 'Updated Title');
      expect(copied.duration, 200);

      // Copy retains original values for unchanged fields
      expect(copied.videoId, 'orig123');
      expect(copied.artist, 'Original Artist');
    });

    test('equality based on videoId', () {
      final song1 = YouTubeSong(
        videoId: 'same123',
        title: 'Song 1',
        artist: 'Artist 1',
        thumbnailUrl: 'https://example.com/1.jpg',
      );

      final song2 = YouTubeSong(
        videoId: 'same123',
        title: 'Song 2 Different',
        artist: 'Artist 2 Different',
        thumbnailUrl: 'https://example.com/2.jpg',
      );

      final song3 = YouTubeSong(
        videoId: 'different456',
        title: 'Song 1',
        artist: 'Artist 1',
        thumbnailUrl: 'https://example.com/1.jpg',
      );

      expect(song1 == song2, isTrue); // Same videoId
      expect(song1 == song3, isFalse); // Different videoId
    });

    test('hashCode based on videoId', () {
      final song1 = YouTubeSong(
        videoId: 'hash123',
        title: 'Song 1',
        artist: 'Artist',
        thumbnailUrl: '',
      );

      final song2 = YouTubeSong(
        videoId: 'hash123',
        title: 'Different',
        artist: 'Different',
        thumbnailUrl: '',
      );

      expect(song1.hashCode, song2.hashCode);
    });

    test('toMap returns correct structure', () {
      final song = YouTubeSong(
        videoId: 'map123',
        title: 'Map Song',
        artist: 'Map Artist',
        thumbnailUrl: 'https://example.com/map.jpg',
        duration: 240,
        artistId: 'artist789',
        category: 'Pop',
      );

      final map = song.toMap();

      expect(map['videoId'], 'map123');
      expect(map['title'], 'Map Song');
      expect(map['artist'], 'Map Artist');
      expect(map['thumbnailUrl'], 'https://example.com/map.jpg');
      expect(map['duration'], 240);
      expect(map['artistId'], 'artist789');
      expect(map['category'], 'Pop');
    });

    test('fromMap creates correct instance', () {
      final map = {
        'videoId': 'frommap',
        'title': 'From Map',
        'artist': 'Map Artist',
        'thumbnailUrl': 'https://example.com/frommap.jpg',
        'duration': 300,
        'isPlaylist': true,
        'playlistId': 'pl123',
      };

      final song = YouTubeSong.fromMap(map);

      expect(song.videoId, 'frommap');
      expect(song.title, 'From Map');
      expect(song.artist, 'Map Artist');
      expect(song.duration, 300);
      expect(song.isPlaylist, true);
      expect(song.playlistId, 'pl123');
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'videoId': 'minimal',
        'title': 'Minimal',
        'artist': 'Artist',
        'thumbnailUrl': '',
      };

      final song = YouTubeSong.fromMap(map);

      expect(song.videoId, 'minimal');
      expect(song.duration, 0);
      expect(song.artistId, isNull);
      expect(song.isPlaylist, false);
    });

    test('durationFormatted returns correct format', () {
      final song = YouTubeSong(
        videoId: 'dur123',
        title: 'Duration Test',
        artist: 'Artist',
        thumbnailUrl: '',
        duration: 185, // 3:05
      );

      expect(song.durationFormatted, '3:05');
    });

    test('durationFormatted handles hours', () {
      final song = YouTubeSong(
        videoId: 'hour123',
        title: 'Hour Test',
        artist: 'Artist',
        thumbnailUrl: '',
        duration: 3665, // 1:01:05
      );

      expect(song.durationFormatted, '1:01:05');
    });

    test('durationFormatted handles null duration', () {
      final song = YouTubeSong(
        videoId: 'null123',
        title: 'Null Duration',
        artist: 'Artist',
        thumbnailUrl: '',
      );

      expect(song.durationFormatted, '0:00');
    });
  });
}
