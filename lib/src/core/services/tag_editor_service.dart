import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:permission_handler/permission_handler.dart';

class TagEditorService {
  /// Writes metadata to the audio file at [path].
  /// Returns true if successful.
  Future<bool> writeTags({
    required String path,
    required String title,
    required String artist,
    required String album,
    String? artworkPath,
    bool requestPermission = false,
  }) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('[TagEditorService] File not found: $path');
        return false;
      }

      // Ensure storage permissions
      if (!await _hasPermission(requestPermission)) {
        if (requestPermission)
          debugPrint('[TagEditorService] Permission denied');
        return false;
      }

      final metadata = Metadata(
        title: title,
        artist: artist,
        album: album,
        // artwork: artworkPath != null ? Picture(mimeType: ..., data: ...) : null,
      );

      debugPrint(
          '[TagEditorService] Writing tags to $path: $title / $artist (via MetadataGod)');

      await MetadataGod.writeMetadata(file: path, metadata: metadata);

      debugPrint('[TagEditorService] Write successful');
      return true;
    } catch (e) {
      debugPrint('[TagEditorService] Error writing tags: $e');
      return false;
    }
  }

  Future<bool> _hasPermission(bool request) async {
    if (Platform.isAndroid) {
      // Check for MANAGE_EXTERNAL_STORAGE on Android 11+ (R)
      if (await Permission.manageExternalStorage.status.isGranted) {
        return true;
      }

      if (request &&
          await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }

      // Fallback for older Android (WRITE_EXTERNAL_STORAGE)
      if (await Permission.storage.isGranted) return true;
      if (request && await Permission.storage.request().isGranted) return true;

      return false;
    }
    return true;
  }
}
