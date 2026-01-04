import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:path_provider/path_provider.dart';

class MusicFinder {
  final AppDatabase _database;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  MusicFinder(this._database);

  Future<void> startScan() async {
    final dbPath = await _getDbPath();
    await compute(_scan, dbPath);
  }

  static Future<String> _getDbPath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return '${dbFolder.path}/db.sqlite';
  }
}

Future<void> _scan(String dbPath) async {
  final audioQuery = OnAudioQuery();
  final database = AppDatabase();
  final songs = await audioQuery.querySongs();

  final tracks = songs.map((song) {
    if (song.duration == null || song.duration! < 1000) {
      return null;
    }
    return TracksCompanion.insert(
      path: song.uri ?? '',
      title: song.title,
      artist: Value(song.artist),
      album: Value(song.album),
      duration: song.duration ?? 0,
      folderPath: song.data.substring(0, song.data.lastIndexOf('/')),
    );
  }).whereType<TracksCompanion>().toList();

  if (tracks.isNotEmpty) {
    await database.batch((batch) {
      batch.insertAll(database.tracks, tracks,
          mode: InsertMode.insertOrReplace);
    });
  }
  await database.close();
}
