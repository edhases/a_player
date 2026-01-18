import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:audiotagger/audiotagger.dart'; // Removed: incompatible with Flutter 3.29+
// import 'package:audiotagger/models/tag.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';

import '../../domain/entities/youtube_song.dart';
import 'youtube_helper.dart';

/// Service for downloading YouTube tracks as MP3 with ID3 metadata
class DownloadService {
  final YouTubeHelper _ytHelper;
  // final Audiotagger _tagger = Audiotagger(); // Removed

  DownloadService({YouTubeHelper? ytHelper})
      : _ytHelper = ytHelper ?? GetIt.I<YouTubeHelper>();

  /// Get the music download directory
  Future<Directory> _getMusicDirectory() async {
    // Save to public Music folder on Android
    final musicDir = Directory('/storage/emulated/0/Music/OxidePlayer');
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir;
  }

  /// Download artwork from URL as bytes (kept for future use)
  Future<List<int>?> _downloadArtwork(String url) async {
    if (url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('[DownloadService] Error downloading artwork: $e');
    }
    return null;
  }

  /// Save YouTube track to device as MP3 with metadata
  /// Returns the file path if successful, null otherwise
  Future<String?> saveToDevice(
    YouTubeSong song, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('[DownloadService] Starting download: ${song.title}');

      // Get audio URL
      final audioUrl = await _ytHelper.getAudioUrl(song.videoId);
      if (audioUrl == null) {
        debugPrint('[DownloadService] Could not get audio URL');
        return null;
      }

      onProgress?.call(0.1);

      // Create temp file for download
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${song.videoId}.m4a');

      // Download audio stream
      debugPrint('[DownloadService] Downloading audio stream...');
      final response = await http.get(Uri.parse(audioUrl));
      if (response.statusCode != 200) {
        debugPrint('[DownloadService] Download failed: ${response.statusCode}');
        return null;
      }
      await tempFile.writeAsBytes(response.bodyBytes);

      onProgress?.call(0.6);

      // Prepare final file path
      final musicDir = await _getMusicDirectory();
      final safeName = song.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final finalPath = '${musicDir.path}/$safeName.m4a';

      // Copy to music folder
      await tempFile.copy(finalPath);
      await tempFile.delete();

      onProgress?.call(0.8);

      // TODO: ID3 tagging disabled - audiotagger is incompatible with Flutter 3.29+
      // Consider using ffmpeg_kit_flutter or a native platform channel for tagging.
      debugPrint(
          '[DownloadService] ID3 tagging skipped (library incompatible)');

      onProgress?.call(1.0);

      debugPrint('[DownloadService] Saved to: $finalPath');
      return finalPath;
    } catch (e) {
      debugPrint('[DownloadService] Error: $e');
      return null;
    }
  }

  /// Check if a song is already downloaded
  Future<bool> isDownloaded(String videoId) async {
    try {
      final musicDir = await _getMusicDirectory();
      final files = await musicDir.list().toList();
      return files.any((f) => f.path.contains(videoId));
    } catch (e) {
      return false;
    }
  }
}
