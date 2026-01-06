import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/datasources/app_database.dart';
import 'package:flutter/foundation.dart'; // Required for debugPrint

class MusicFinder {
  final AppDatabase _db;

  MusicFinder(this._db);

  /// Lets the user pick a folder, then scans it for music files.
  Future<void> pickFolderAndScan() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        final dir = Directory(selectedDirectory);
        if (await dir.exists()) {
          // Self-Correction: No need for a separate `_scanDirectory` method.
          // The logic is now fully asynchronous here.
          await _scanDirectoryAndProcess(dir);
        }
      }
    } catch (e) {
      // Catch errors related to the file picker itself (e.g., platform exceptions)
      debugPrint("Error picking folder: $e");
    }
  }

  /// Scans the directory asynchronously and processes files.
  Future<void> _scanDirectoryAndProcess(Directory dir) async {
    try {
      // Self-Correction: Replaced blocking listSync with asynchronous list().
      // This is critical for keeping the UI responsive during scans.
      final stream = dir.list(recursive: true);
      await for (var entity in stream) {
        if (entity is File && _isAudioFile(entity.path)) {
          // Process each file without blocking the main loop.
          await _processFile(entity);
        }
      }
    } catch (e) {
      debugPrint("Error scanning directory: $e");
    }
  }

  bool _isAudioFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    // A more comprehensive list of common audio formats.
    return ['mp3', 'flac', 'm4a', 'wav', 'ogg', 'aac', 'wma', 'ape', 'opus'].contains(ext);
  }

  Future<void> _processFile(File file) async {
    Metadata? metadata;
    try {
      metadata = await MetadataGod.readMetadata(file: file.path);
    } catch (e) {
      debugPrint("Error reading metadata for ${file.path}: $e");
      // Don't stop processing, just skip this file.
      return;
    }

    final trackCompanion = TracksCompanion(
      path: drift.Value(file.path),
      title: drift.Value(metadata.title ?? file.path.split('/').last),
      artist: drift.Value(metadata.artist),
      album: drift.Value(metadata.album),
      duration: drift.Value(metadata.durationMs?.toInt() ?? 0),
      folderPath: drift.Value(file.parent.path),
    );

    try {
      // Use insertOnConflictUpdate to add new tracks or update existing ones.
      await _db.into(_db.tracks).insertOnConflictUpdate(trackCompanion);
    } catch (e) {
      debugPrint("DB Insert/Update Error for ${file.path}: $e");
    }
  }
}
