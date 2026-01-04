import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MusicFinder {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AppDatabase _database;

  MusicFinder(this._database);

  Future<void> startScan() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'db.sqlite');
    // This is the entry point for the isolate.
    return compute(_scan, {'dbPath': dbPath, 'token': RootIsolateToken.instance});
  }

  static Future<void> _scan(Map<String, dynamic> args) async {
    final dbPath = args['dbPath'] as String;
    final token = args['token'] as RootIsolateToken?;
    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }
    final database = AppDatabase.forIsolate(NativeDatabase(File(dbPath)));
    final audioQuery = OnAudioQuery();
    final songs = await audioQuery.querySongs(
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    await database.batch((batch) {
      for (final song in songs) {
        try {
          final track = TracksCompanion.insert(
            path: song.data,
            title: song.title,
            artist: Value(song.artist),
            album: Value(song.album),
            durationMs: song.duration ?? 0,
            folderPath: song.data.substring(0, song.data.lastIndexOf('/')),
            artworkUri: Value(song.uri),
            addedAt: DateTime.now(),
            sourceType: const Value('local'),
          );
          batch.insert(database.tracks, track,
              onConflict: DoUpdate((old) => track, target: [database.tracks.path]));
        } catch (e) {
          debugPrint('Error processing song ${song.title}: $e');
        }
      }
    });
    await database.close();
  }
}
