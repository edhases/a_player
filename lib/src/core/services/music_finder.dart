import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:drift/drift.dart';
import '../../data/datasources/app_database.dart';

/// A simple, serializable data class to pass data back from the isolate.
class TrackInfo {
  final String path;
  final String title;
  final String? artist;
  final String? album;
  final int duration;

  TrackInfo({
    required this.path,
    required this.title,
    this.artist,
    this.album,
    required this.duration,
  });
}

/// This is the top-level function that will run in the isolate.
Future<List<TrackInfo>> _scanInIsolate(String path) async {
  final List<TrackInfo> trackInfos = [];
  final dir = Directory(path);

  try {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && (entity.path.endsWith('.mp3') || entity.path.endsWith('.flac'))) {
        try {
          final metadata = await MetadataGod.readMetadata(file: entity.path);
          trackInfos.add(TrackInfo(
            path: entity.path,
            title: metadata.title ?? entity.path.split('/').last,
            artist: metadata.artist,
            album: metadata.album,
            duration: metadata.durationMs?.toInt() ?? 0,
          ));
        } catch (e) {
          // Skip file if metadata read fails
        }
      }
    }
  } catch (e) {
    // Handle errors like permission denied
  }

  return trackInfos;
}

class MusicFinder {
  final AppDatabase _db;
  final ValueNotifier<bool> isScanning = ValueNotifier(false);

  MusicFinder(this._db);

  Future<void> pickFolderAndScan() async {
    if (isScanning.value) return;

    try {
      isScanning.value = true;
      final String? path = await FilePicker.platform.getDirectoryPath();

      if (path != null) {
        // Run the heavy lifting in an isolate
        final trackInfos = await compute(_scanInIsolate, path);

        // Perform the database insertion on the main thread
        if (trackInfos.isNotEmpty) {
          final trackCompanions = trackInfos.map((info) => TracksCompanion.insert(
            path: info.path,
            title: info.title,
            artist: Value(info.artist),
            album: Value(info.album),
            duration: info.duration,
            folderPath: Value(File(info.path).parent.path),
          )).toList();

          await _db.batch((batch) {
            batch.insertAll(_db.tracks, trackCompanions, mode: InsertMode.replace);
          });
        }
      }
    } catch (e) {
      debugPrint("Error during scanning process: $e");
    } finally {
      isScanning.value = false;
    }
  }
}
