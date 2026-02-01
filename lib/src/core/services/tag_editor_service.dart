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
        if (requestPermission) {
          debugPrint('[TagEditorService] Permission denied');
        }
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
      
      // Check for format mismatches
      final isMislabeled = _isMislabeledFile(extension, realFormat);
      if (isMislabeled != null) {
        debugPrint('[TagEditorService] WARNING: $isMislabeled');
      }
      
      // WebM/Matroska doesn't support standard audio tags via MetadataGod
      if (realFormat == 'WebM/Matroska') {
        debugPrint('[TagEditorService] Skipping tag write: WebM/Matroska format does not support embedded tags via MetadataGod');
        return false;
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

      // 7. WebM / Matroska (EBML header: 0x1A 0x45 0xDF 0xA3)
      if (bytes[0] == 0x1A &&
          bytes[1] == 0x45 &&
          bytes[2] == 0xDF &&
          bytes[3] == 0xA3) {
        return 'WebM/Matroska';
      }

      // 8. OPUS in OGG container (check for 'OpusHead' after OGG header)
      // Already covered by OGG check above

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

  /// Returns a warning message if the file extension doesn't match the real format.
  /// Returns null if the file is correctly labeled.
  String? _isMislabeledFile(String extension, String realFormat) {
    // Map of expected formats for each extension
    const expectedFormats = {
      '.mp3': ['MP3 (ID3v2)', 'MP3 (Raw Frames)'],
      '.m4a': ['MP4/M4A'],
      '.mp4': ['MP4/M4A'],
      '.flac': ['FLAC'],
      '.ogg': ['OGG'],
      '.opus': ['OGG'], // Opus is usually in OGG container
      '.wav': ['WAV/RIFF'],
      '.webm': ['WebM/Matroska'],
      '.mkv': ['WebM/Matroska'],
    };

    final expected = expectedFormats[extension];
    if (expected == null) return null; // Unknown extension, can't validate

    if (!expected.contains(realFormat)) {
      return 'File has $extension extension but is actually $realFormat format. Tags may not be written correctly.';
    }

    return null;
  }
}
