import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oxide_player/src/core/services/ksoft_service.dart';

void main() {
  group('KSoftService', () {
    test('isConfigured returns false when token is empty', () {
      final service = KSoftService(apiToken: '');
      expect(service.isConfigured, false);
    });

    test('isConfigured returns true when token is set', () {
      final service = KSoftService(apiToken: 'test_token');
      expect(service.isConfigured, true);
    });

    test('searchLyrics returns null when not configured', () async {
      final service = KSoftService(apiToken: '');
      final result = await service.searchLyrics(query: 'test');
      expect(result, isNull);
    });

    test('searchLyrics parses response correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test_token');
        expect(request.url.queryParameters['q'], 'test query');

        return http.Response(
          json.encode({
            'total': 1,
            'took': 10,
            'data': [
              {
                'id': '123',
                'name': 'Test Song',
                'artist': 'Test Artist',
                'artist_id': 456,
                'album': 'Test Album',
                'album_year': '2024',
                'lyrics': 'Test lyrics here',
                'popularity': 100,
                'singalong': [
                  {
                    'lrc_timestamp': '[00:00.00]',
                    'milliseconds': '0',
                    'duration': '1000',
                    'line': 'First line'
                  },
                  {
                    'lrc_timestamp': '[00:01.00]',
                    'milliseconds': '1000',
                    'duration': '2000',
                    'line': 'Second line'
                  },
                ],
              }
            ],
          }),
          200,
        );
      });

      final service = KSoftService(apiToken: 'test_token', client: mockClient);
      final result = await service.searchLyrics(query: 'test query');

      expect(result, isNotNull);
      expect(result!.id, '123');
      expect(result.name, 'Test Song');
      expect(result.artist, 'Test Artist');
      expect(result.artistId, 456);
      expect(result.album, 'Test Album');
      expect(result.lyrics, 'Test lyrics here');
      expect(result.hasSyncedLyrics, true);
    });

    test('searchLyrics returns null on 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'total': 0, 'data': []}),
          200,
        );
      });

      final service = KSoftService(apiToken: 'test_token', client: mockClient);
      final result = await service.searchLyrics(query: 'nonexistent');

      expect(result, isNull);
    });

    test('searchLyrics returns null on 429 rate limit', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Rate limited', 429);
      });

      final service = KSoftService(apiToken: 'test_token', client: mockClient);
      final result = await service.searchLyrics(query: 'test');

      expect(result, isNull);
    });

    test('getRecommendations returns empty list when not configured', () async {
      final service = KSoftService(apiToken: '');
      final result = await service.getRecommendations(videoIds: ['test123']);
      expect(result, isEmpty);
    });

    test('getRecommendations returns empty list for empty videoIds', () async {
      final service = KSoftService(apiToken: 'test_token');
      final result = await service.getRecommendations(videoIds: []);
      expect(result, isEmpty);
    });

    test('getRecommendations parses response correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');

        return http.Response(
          json.encode({
            'provider': 'youtube_ids',
            'total': 2,
            'tracks': [
              {
                'name': 'Recommended Song 1',
                'youtube': {
                  'id': 'rec123',
                  'link': 'https://youtube.com/watch?v=rec123',
                  'title': 'Recommended Song 1',
                  'thumbnail': 'https://example.com/thumb1.jpg',
                },
                'spotify': {
                  'id': 'spotify123',
                  'name': 'Recommended Song 1',
                  'album': {'album_art': 'https://example.com/art1.jpg'},
                },
              },
              {
                'name': 'Recommended Song 2',
                'youtube': {
                  'id': 'rec456',
                  'link': 'https://youtube.com/watch?v=rec456',
                  'title': 'Recommended Song 2',
                  'thumbnail': 'https://example.com/thumb2.jpg',
                },
              },
            ],
          }),
          200,
        );
      });

      final service = KSoftService(apiToken: 'test_token', client: mockClient);
      final result =
          await service.getRecommendations(videoIds: ['video1', 'video2']);

      expect(result.length, 2);
      expect(result[0].name, 'Recommended Song 1');
      expect(result[0].youtubeId, 'rec123');
      expect(result[0].spotifyId, 'spotify123');
      expect(result[1].youtubeId, 'rec456');
    });
  });

  group('KSoftLyricsResult', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': '999',
        'name': 'Test Track',
        'artist': 'Test Artist',
        'artist_id': 123,
        'album': 'Test Album',
        'album_year': '2023',
        'lyrics': 'Plain lyrics text',
        'album_art': 'https://example.com/art.jpg',
        'popularity': 500,
        'singalong': [
          {
            'lrc_timestamp': '[00:05.00]',
            'milliseconds': '5000',
            'duration': '3000',
            'line': 'Synced line'
          },
        ],
        'meta': {
          'spotify': {'track': 'sp_track', 'album': 'sp_album'},
          'other': {'bpm': 120.5, 'gain': -6.0},
        },
      };

      final result = KSoftLyricsResult.fromJson(json);

      expect(result.id, '999');
      expect(result.name, 'Test Track');
      expect(result.artist, 'Test Artist');
      expect(result.artistId, 123);
      expect(result.album, 'Test Album');
      expect(result.albumYear, '2023');
      expect(result.lyrics, 'Plain lyrics text');
      expect(result.albumArt, 'https://example.com/art.jpg');
      expect(result.popularity, 500);
      expect(result.hasSyncedLyrics, true);
      expect(result.meta, isNotNull);
      expect(result.meta!.bpm, 120.5);
      expect(result.meta!.gain, -6.0);
    });

    test('syncedLyrics generates LRC format', () {
      final result = KSoftLyricsResult(
        id: '1',
        name: 'Test',
        artist: 'Artist',
        artistId: 1,
        lyrics: 'Plain',
        singalong: [
          KSoftSingalongLine(
            lrcTimestamp: '[00:00.00]',
            milliseconds: 0,
            line: 'First line',
          ),
          KSoftSingalongLine(
            lrcTimestamp: '[00:05.50]',
            milliseconds: 5500,
            line: 'Second line',
          ),
        ],
      );

      final lrc = result.syncedLyrics;
      expect(lrc, isNotNull);
      expect(lrc, contains('[00:00.00] First line'));
      expect(lrc, contains('[00:05.50] Second line'));
    });

    test('hasSyncedLyrics returns false for empty singalong', () {
      final result = KSoftLyricsResult(
        id: '1',
        name: 'Test',
        artist: 'Artist',
        artistId: 1,
        lyrics: 'Plain',
        singalong: [],
      );

      expect(result.hasSyncedLyrics, false);
      expect(result.syncedLyrics, isNull);
    });
  });

  group('KSoftRecommendation', () {
    test('fromJson parses YouTube and Spotify data', () {
      final json = {
        'name': 'Rec Track',
        'youtube': {
          'id': 'yt123',
          'link': 'https://youtube.com/watch?v=yt123',
          'title': 'YT Title',
          'thumbnail': 'https://i.ytimg.com/vi/yt123/mqdefault.jpg',
        },
        'spotify': {
          'id': 'sp456',
          'name': 'SP Name',
          'album': {'album_art': 'https://spotify.com/art.jpg'},
        },
      };

      final rec = KSoftRecommendation.fromJson(json);

      expect(rec.name, 'Rec Track');
      expect(rec.youtubeId, 'yt123');
      expect(rec.youtubeLink, 'https://youtube.com/watch?v=yt123');
      expect(rec.youtubeTitle, 'YT Title');
      expect(rec.youtubeThumbnail, 'https://i.ytimg.com/vi/yt123/mqdefault.jpg');
      expect(rec.spotifyId, 'sp456');
      expect(rec.spotifyName, 'SP Name');
      expect(rec.spotifyAlbumArt, 'https://spotify.com/art.jpg');
    });

    test('fromJson handles missing optional fields', () {
      final json = {'name': 'Simple Track'};

      final rec = KSoftRecommendation.fromJson(json);

      expect(rec.name, 'Simple Track');
      expect(rec.youtubeId, isNull);
      expect(rec.spotifyId, isNull);
    });
  });

  group('KSoftMeta', () {
    test('fromJson parses all metadata', () {
      final json = {
        'spotify': {
          'artists': ['art1', 'art2'],
          'track': 'track_id',
          'album': 'album_id',
        },
        'deezer': {
          'artists': [123, 456],
          'track': 789,
          'album': 101,
        },
        'other': {
          'bpm': 128.0,
          'gain': -8.5,
        },
      };

      final meta = KSoftMeta.fromJson(json);

      expect(meta.spotifyArtists, ['art1', 'art2']);
      expect(meta.spotifyTrack, 'track_id');
      expect(meta.spotifyAlbum, 'album_id');
      expect(meta.deezerArtists, ['123', '456']);
      expect(meta.deezerTrack, '789');
      expect(meta.deezerAlbum, '101');
      expect(meta.bpm, 128.0);
      expect(meta.gain, -8.5);
    });
  });

  group('KSoftArtistInfo', () {
    test('fromJson parses artist with albums and tracks', () {
      final json = {
        'id': 12345,
        'name': 'Famous Artist',
        'albums': [
          {'id': 1, 'name': 'Album 1', 'year': 2020},
          {'id': 2, 'name': 'Album 2', 'year': 2022},
        ],
        'tracks': [
          {'id': 100, 'name': 'Song 1'},
          {'id': 101, 'name': 'Song 2'},
        ],
      };

      final artist = KSoftArtistInfo.fromJson(json);

      expect(artist.id, 12345);
      expect(artist.name, 'Famous Artist');
      expect(artist.albums.length, 2);
      expect(artist.albums[0].name, 'Album 1');
      expect(artist.albums[1].year, 2022);
      expect(artist.tracks.length, 2);
      expect(artist.tracks[0].name, 'Song 1');
    });
  });

  group('KSoftTrackInfo', () {
    test('fromJson parses track with lyrics and albums', () {
      final json = {
        'name': 'Great Song',
        'artist': {'id': 999, 'name': 'Cool Artist'},
        'lyrics': 'These are the lyrics...',
        'albums': [
          {'id': 50, 'name': 'First Album', 'year': 2021},
        ],
      };

      final track = KSoftTrackInfo.fromJson(json);

      expect(track.name, 'Great Song');
      expect(track.artistId, 999);
      expect(track.artistName, 'Cool Artist');
      expect(track.lyrics, 'These are the lyrics...');
      expect(track.albums.length, 1);
      expect(track.albums[0].year, 2021);
    });
  });
}
