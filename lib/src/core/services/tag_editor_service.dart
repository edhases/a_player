import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;

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

      debugPrint('[TagEditorService] Pre-checking format for $path...');
      final realFormat = await _detectRealFormat(path);
      debugPrint('[TagEditorService] Detected format: $realFormat');

      final extension = p.extension(path).toLowerCase();
      if (extension == '.mp3' && realFormat == 'MP4/M4A') {
        debugPrint(
            '[TagEditorService] WARNING: File $path is mislabeled! It is actually an MP4/M4A file but has .mp3 extension. Writing tags might fail.');
      }

      debugPrint(
          '[TagEditorService] Writing tags to $path: $title / $artist (via MetadataGod)');

      await MetadataGod.writeMetadata(file: path, metadata: metadata);

      debugPrint('[TagEditorService] Write successful for $path');
      return true;
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('format that does not support it')) {
        debugPrint(
            '[TagEditorService] Skipping tag write: Format mismatch or not supported for $path');
      } else {
        debugPrint('[TagEditorService] Error writing tags to $path: $e');
      }
      return false;
    }
  }

  /// Допоміжний метод для визначення справжнього формату файлу за сигнатурою (Magic Number)
  /// Helper method to detect real file format by magic numbers
  Future<String> _detectRealFormat(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return 'Unknown (File not found)';

      final randomAccessFile = await file.open(mode: FileMode.read);
      final bytes = await randomAccessFile.read(32); // Read first 32 bytes
      await randomAccessFile.close();

      if (bytes.length < 4) return 'Unknown (Too small)';

      // 1. MP3 (ID3v2 tag starts with 'ID3')
      if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
        return 'MP3 (ID3v2)';
      }

      // 2. MP3 (Raw frames usually start with 0xFF 0xFB/0xF3/0xF2)
      if (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
        return 'MP3 (Raw Frames)';
      }

      // 3. MP4 / M4A (Contains 'ftyp' at offset 4)
      if (bytes.length >= 8 &&
          bytes[4] == 0x66 && // f
          bytes[5] == 0x74 && // t
          bytes[6] == 0x79 && // y
          bytes[7] == 0x70) {
        // p
        return 'MP4/M4A';
      }

      // 4. FLAC ('fLaC')
      if (bytes[0] == 0x66 &&
          bytes[1] == 0x4C &&
          bytes[2] == 0x61 &&
          bytes[3] == 0x43) {
        return 'FLAC';
      }

      // 5. OGG ('OggS')
      if (bytes[0] == 0x4F &&
          bytes[1] == 0x67 &&
          bytes[2] == 0x67 &&
          bytes[3] == 0x53) {
        return 'OGG';
      }

      // 6. WAV ('RIFF' ... 'WAVE')
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46) {
        return 'WAV/RIFF';
      }

      return 'Unknown (Signature: ${bytes.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')})';
    } catch (e) {
      return 'Error detecting: $e';
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
