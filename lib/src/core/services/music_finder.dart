import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/datasources/app_database.dart';

class MusicFinder {
  final AppDatabase _db;

  MusicFinder(this._db);

  /// Scans a selected folder and updates the DB
  Future<void> pickFolderAndScan() async {
    // Request storage permissions if not already granted (redundant if PermissionGate works, but safe)
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        // Handle audio permission for Android 13+
        var audioStatus = await Permission.audio.status;
        if (!audioStatus.isGranted) {
          await Permission.audio.request();
        }
      }
    }

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      final dir = Directory(selectedDirectory);
      if (await dir.exists()) {
        await _scanDirectory(dir);
      }
    }
  }

  Future<void> _scanDirectory(Directory dir) async {
    try {
      final List<FileSystemEntity> entities = dir.listSync(recursive: true);

      for (var entity in entities) {
        if (entity is File && _isAudioFile(entity.path)) {
          await _processFile(entity);
        }
      }
    } catch (e) {
      print("Error scanning directory: $e");
    }
  }

  bool _isAudioFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['mp3', 'flac', 'm4a', 'wav', 'ogg'].contains(ext);
  }

  Future<void> _processFile(File file) async {
    Metadata? metadata;
    try {
      metadata = await MetadataGod.readMetadata(file: file.path);
    } catch (e) {
      print("Error reading metadata for ${file.path}: $e");
    }

    final trackCompanion = TracksCompanion(
      path: drift.Value(file.path),
      title: drift.Value(metadata?.title ?? file.path.split('/').last),
      artist: drift.Value(metadata?.artist ?? 'Unknown Artist'),
      album: drift.Value(metadata?.album ?? 'Unknown Album'),
      duration: drift.Value(metadata?.durationMs?.toInt() ?? 0),
      folderPath: drift.Value(file.parent.path),
      artworkUri: drift.Value(null), // Avoid artwork crashes for now
    );

    try {
      await _db.into(_db.tracks).insertOnConflictUpdate(trackCompanion);
      print("Added to DB: ${file.path}");
    } catch (e) {
      print("DB Insert Error: $e");
    }
  }
}
