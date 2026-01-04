import 'package:drift/drift.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:flutter/foundation.dart';

class MusicFinder {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AppDatabase _database;

  MusicFinder(this._database);

  Future<void> startScan() async {
    // This is the entry point for the isolate.
    return compute(_scan, _database);
  }

  static Future<void> _scan(AppDatabase database) async {
    final audioQuery = OnAudioQuery();
    final songs = await audioQuery.querySongs(
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    for (final song in songs) {
      final track = TracksCompanion.insert(
        path: song.data,
        title: song.title,
        artist: Value(song.artist),
        album: Value(song.album),
        durationMs: song.duration ?? 0,
        folderPath: song.data.substring(0, song.data.lastIndexOf('/')),
        artworkUri: Value(song.uri),
        addedAt: DateTime.now(),
      );
      // This will insert or update the track if it already exists.
      await database.into(database.tracks).insertOnConflictUpdate(track);
    }
  }
}
