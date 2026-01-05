import 'package:drift/drift.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'dart:developer';

class MusicFinder {
  final AppDatabase _database;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  MusicFinder(this._database);

  Future<void> startScan() async {
    try {
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      if (songs.isEmpty) {
        log('No songs found on the device.');
        return;
      }

      final tracks = songs
          .map((song) {
            // Skip short audio files (likely ringtones or notifications)
            if (song.duration == null || song.duration! < 5000) {
              return null;
            }
            // Ensure path exists
            if (song.data.isEmpty) {
              return null;
            }

            return TracksCompanion.insert(
              path: song.data,
              title: song.title,
              artist: Value(song.artist),
              album: Value(song.album),
              duration: song.duration ?? 0,
              folderPath: song.data.substring(0, song.data.lastIndexOf('/')),
              artworkUri: Value(song.uri),
            );
          })
          .whereType<TracksCompanion>()
          .toList();

      if (tracks.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAllOnConflictUpdate(_database.tracks, tracks);
        });
        log('Successfully scanned and inserted ${tracks.length} tracks.');
      }
    } catch (e, stacktrace) {
      log('Error during music scan: $e');
      log(stacktrace.toString());
      // Optionally, rethrow or handle the error in the UI
    }
  }
}
