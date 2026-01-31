import 'package:flutter_test/flutter_test.dart';
import 'package:oxide_player/src/core/models/lyrics_model.dart';

void main() {
  group('LyricsLine', () {
    test('creates with required fields', () {
      final line = LyricsLine(
        time: const Duration(minutes: 1, seconds: 30),
        text: 'Test lyrics line',
      );

      expect(line.time, equals(const Duration(minutes: 1, seconds: 30)));
      expect(line.text, equals('Test lyrics line'));
    });

    test('toString returns formatted string', () {
      final line = LyricsLine(
        time: const Duration(minutes: 2, seconds: 15, milliseconds: 500),
        text: 'Hello world',
      );

      final str = line.toString();
      expect(str, contains('Hello world'));
    });
  });

  group('LyricsModel', () {
    test('creates with all required fields', () {
      final lyrics = LyricsModel(
        id: 1,
        trackName: 'Test Song',
        artistName: 'Test Artist',
        albumName: 'Test Album',
        duration: 180.0,
        instrumental: false,
        plainLyrics: 'Plain lyrics text',
        syncedLyrics: '[00:00.00]Synced lyrics',
        source: 'LRCLIB',
      );

      expect(lyrics.id, equals(1));
      expect(lyrics.trackName, equals('Test Song'));
      expect(lyrics.artistName, equals('Test Artist'));
      expect(lyrics.albumName, equals('Test Album'));
      expect(lyrics.duration, equals(180.0));
      expect(lyrics.instrumental, isFalse);
      expect(lyrics.plainLyrics, equals('Plain lyrics text'));
      expect(lyrics.syncedLyrics, equals('[00:00.00]Synced lyrics'));
      expect(lyrics.source, equals('LRCLIB'));
    });

    test('isSynced returns true when syncedLyrics is not empty', () {
      final syncedLyrics = LyricsModel(
        id: 1,
        trackName: 'Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: 200.0,
        instrumental: false,
        plainLyrics: '',
        syncedLyrics: '[00:00.00]Line one',
      );

      expect(syncedLyrics.isSynced, isTrue);
    });

    test('isSynced returns false when syncedLyrics is empty', () {
      final plainOnly = LyricsModel(
        id: 1,
        trackName: 'Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: 200.0,
        instrumental: false,
        plainLyrics: 'Just plain lyrics',
        syncedLyrics: '',
      );

      expect(plainOnly.isSynced, isFalse);
    });

    test('parsedSyncedLyrics parses [mm:ss.xx] format correctly', () {
      final lyrics = LyricsModel(
        id: 1,
        trackName: 'Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: 200.0,
        instrumental: false,
        plainLyrics: '',
        syncedLyrics: '''[00:00.00]First line
[00:05.50]Second line
[00:10.25]Third line
[01:00.00]One minute mark''',
      );

      final parsed = lyrics.parsedSyncedLyrics;

      expect(parsed.length, equals(4));

      // First line at 0:00.000
      expect(parsed[0].time, equals(Duration.zero));
      expect(parsed[0].text, equals('First line'));

      // Second line at 0:05.500
      expect(parsed[1].time, equals(const Duration(seconds: 5, milliseconds: 500)));
      expect(parsed[1].text, equals('Second line'));

      // Third line at 0:10.250
      expect(parsed[2].time, equals(const Duration(seconds: 10, milliseconds: 250)));
      expect(parsed[2].text, equals('Third line'));

      // Fourth line at 1:00.000
      expect(parsed[3].time, equals(const Duration(minutes: 1)));
      expect(parsed[3].text, equals('One minute mark'));
    });

    test('parsedSyncedLyrics parses [mm:ss.xxx] format correctly', () {
      final lyrics = LyricsModel(
        id: 1,
        trackName: 'Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: 200.0,
        instrumental: false,
        plainLyrics: '',
        syncedLyrics: '''[00:15.123]Milliseconds format
[02:30.456]Another line''',
      );

      final parsed = lyrics.parsedSyncedLyrics;

      expect(parsed.length, equals(2));

      // First line at 0:15.123
      expect(parsed[0].time, equals(const Duration(seconds: 15, milliseconds: 123)));
      expect(parsed[0].text, equals('Milliseconds format'));

      // Second line at 2:30.456
      expect(parsed[1].time, equals(const Duration(minutes: 2, seconds: 30, milliseconds: 456)));
      expect(parsed[1].text, equals('Another line'));
    });

    test('parsedSyncedLyrics handles empty lines', () {
      final lyrics = LyricsModel(
        id: 1,
        trackName: 'Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: 200.0,
        instrumental: false,
        plainLyrics: '',
        syncedLyrics: '''[00:00.00]Intro
[00:10.00]
[00:15.00]After pause''',
      );

      final parsed = lyrics.parsedSyncedLyrics;

      expect(parsed.length, equals(3));
      expect(parsed[1].text, isEmpty);
      expect(parsed[2].text, equals('After pause'));
    });

    test('parsedSyncedLyrics returns empty list for non-synced lyrics', () {
      final lyrics = LyricsModel(
        id: 1,
        trackName: 'Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: 200.0,
        instrumental: false,
        plainLyrics: 'Only plain lyrics',
        syncedLyrics: '',
      );

      final parsed = lyrics.parsedSyncedLyrics;
      expect(parsed, isEmpty);
    });

    test('parsedSyncedLyrics caches results', () {
      final lyrics = LyricsModel(
        id: 1,
        trackName: 'Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: 200.0,
        instrumental: false,
        plainLyrics: '',
        syncedLyrics: '[00:00.00]Test',
      );

      final first = lyrics.parsedSyncedLyrics;
      final second = lyrics.parsedSyncedLyrics;

      // Should return the same cached instance
      expect(identical(first, second), isTrue);
    });

    test('parsedSyncedLyrics handles Ukrainian text correctly', () {
      final lyrics = LyricsModel(
        id: 1,
        trackName: 'Українська Пісня',
        artistName: 'Виконавець',
        albumName: 'Альбом',
        duration: 200.0,
        instrumental: false,
        plainLyrics: '',
        syncedLyrics: '''[00:00.00]Привіт світе
[00:05.00]Як справи?
[00:10.00]Все добре!''',
      );

      final parsed = lyrics.parsedSyncedLyrics;

      expect(parsed.length, equals(3));
      expect(parsed[0].text, equals('Привіт світе'));
      expect(parsed[1].text, equals('Як справи?'));
      expect(parsed[2].text, equals('Все добре!'));
    });

    test('parsedSyncedLyrics handles Japanese text correctly', () {
      final lyrics = LyricsModel(
        id: 1,
        trackName: 'Japanese Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: 200.0,
        instrumental: false,
        plainLyrics: '',
        syncedLyrics: '''[00:00.00]こんにちは
[00:05.00]世界''',
      );

      final parsed = lyrics.parsedSyncedLyrics;

      expect(parsed.length, equals(2));
      expect(parsed[0].text, equals('こんにちは'));
      expect(parsed[1].text, equals('世界'));
    });

    group('fromJson', () {
      test('creates model from complete JSON', () {
        final json = {
          'id': 123,
          'trackName': 'JSON Song',
          'artistName': 'JSON Artist',
          'albumName': 'JSON Album',
          'duration': 240.5,
          'instrumental': true,
          'plainLyrics': 'Plain text',
          'syncedLyrics': '[00:00.00]Synced text',
          'source': 'Genius',
        };

        final lyrics = LyricsModel.fromJson(json);

        expect(lyrics.id, equals(123));
        expect(lyrics.trackName, equals('JSON Song'));
        expect(lyrics.artistName, equals('JSON Artist'));
        expect(lyrics.albumName, equals('JSON Album'));
        expect(lyrics.duration, equals(240.5));
        expect(lyrics.instrumental, isTrue);
        expect(lyrics.plainLyrics, equals('Plain text'));
        expect(lyrics.syncedLyrics, equals('[00:00.00]Synced text'));
        expect(lyrics.source, equals('Genius'));
      });

      test('creates model with defaults for missing fields', () {
        final json = <String, dynamic>{};

        final lyrics = LyricsModel.fromJson(json);

        expect(lyrics.id, equals(0));
        expect(lyrics.trackName, equals(''));
        expect(lyrics.artistName, equals(''));
        expect(lyrics.albumName, equals(''));
        expect(lyrics.duration, equals(0.0));
        expect(lyrics.instrumental, isFalse);
        expect(lyrics.plainLyrics, equals(''));
        expect(lyrics.syncedLyrics, equals(''));
        expect(lyrics.source, equals('Unknown'));
      });

      test('handles integer duration as double', () {
        final json = {
          'id': 1,
          'trackName': 'Song',
          'artistName': 'Artist',
          'albumName': 'Album',
          'duration': 180, // Integer, not double
          'instrumental': false,
          'plainLyrics': '',
          'syncedLyrics': '',
        };

        final lyrics = LyricsModel.fromJson(json);

        expect(lyrics.duration, equals(180.0));
        expect(lyrics.duration, isA<double>());
      });
    });
  });

  group('LyricsModel - Edge Cases', () {
    test('handles very long duration parsing', () {
      final lyrics = LyricsModel(
        id: 1,
        trackName: 'Long Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: 7200.0, // 2 hours
        instrumental: false,
        plainLyrics: '',
        syncedLyrics: '''[59:59.99]Almost end
[99:59.99]Very long mark''',
      );

      final parsed = lyrics.parsedSyncedLyrics;

      expect(parsed.length, equals(2));
      expect(
        parsed[0].time,
        equals(const Duration(minutes: 59, seconds: 59, milliseconds: 990)),
      );
      expect(
        parsed[1].time,
        equals(const Duration(minutes: 99, seconds: 59, milliseconds: 990)),
      );
    });

    test('handles malformed lines gracefully', () {
      final lyrics = LyricsModel(
        id: 1,
        trackName: 'Mixed Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: 200.0,
        instrumental: false,
        plainLyrics: '',
        syncedLyrics: '''[00:00.00]Valid line
Not a valid timestamp
[invalid]Also invalid
[00:10.00]Another valid line''',
      );

      final parsed = lyrics.parsedSyncedLyrics;

      // Should only parse valid lines
      expect(parsed.length, equals(2));
      expect(parsed[0].text, equals('Valid line'));
      expect(parsed[1].text, equals('Another valid line'));
    });

    test('handles special characters in lyrics', () {
      final lyrics = LyricsModel(
        id: 1,
        trackName: 'Special Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: 200.0,
        instrumental: false,
        plainLyrics: '',
        syncedLyrics: '''[00:00.00]Line with "quotes"
[00:05.00]Line with 'apostrophe'
[00:10.00]Line with <brackets>
[00:15.00]Line with special: !@#\$%^&*()''',
      );

      final parsed = lyrics.parsedSyncedLyrics;

      expect(parsed.length, equals(4));
      expect(parsed[0].text, equals('Line with "quotes"'));
      expect(parsed[1].text, equals("Line with 'apostrophe'"));
      expect(parsed[2].text, equals('Line with <brackets>'));
    });

    test('handles whitespace in lyrics lines', () {
      final lyrics = LyricsModel(
        id: 1,
        trackName: 'Whitespace Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: 200.0,
        instrumental: false,
        plainLyrics: '',
        syncedLyrics: '''[00:00.00]   Leading spaces
[00:05.00]Trailing spaces   
[00:10.00]   Both   ''',
      );

      final parsed = lyrics.parsedSyncedLyrics;

      expect(parsed.length, equals(3));
      // The parser should trim the text
      expect(parsed[0].text, equals('Leading spaces'));
      expect(parsed[1].text, equals('Trailing spaces'));
      expect(parsed[2].text, equals('Both'));
    });
  });
}
