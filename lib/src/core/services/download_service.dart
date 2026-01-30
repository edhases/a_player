import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../domain/entities/youtube_song.dart';
import 'youtube_helper.dart';

/// Service for downloading YouTube tracks with metadata
class DownloadService {
  final YouTubeHelper _ytHelper;
  final OnAudioQuery _audioQuery = OnAudioQuery();

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

  /// Download artwork from URL as bytes
  Future<Uint8List?> _downloadArtwork(String url) async {
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

  /// Save YouTube track to device as audio with metadata
  /// Returns the file path if successful, null otherwise
  /// Note: Uses container format from YouTube (webm for Opus, m4a for AAC)
  Future<String?> saveToDevice(
    YouTubeSong song, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('[DownloadService] Starting download: ${song.title}');

      // Get audio URL with container info
      final audioData = await _ytHelper.getAudioUrlWithAgent(song.videoId);
      if (audioData == null) {
        debugPrint('[DownloadService] Could not get audio URL');
        return null;
      }

      final audioUrl = audioData['url']!;
      final container = audioData['container'] ?? 'mp4'; // Default to mp4/m4a

      onProgress?.call(0.1);

      // Determine file extension based on container
      // webm = Opus audio, mp4 = AAC audio
      final extension = (container.toLowerCase() == 'webm') ? 'webm' : 'm4a';

      // Create temp file for download
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${song.videoId}.$extension');

      // Download audio stream
      debugPrint('[DownloadService] Downloading audio stream ($container)...');
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
      final finalPath = '${musicDir.path}/$safeName.$extension';

      // Copy to music folder
      await tempFile.copy(finalPath);
      await tempFile.delete();

      onProgress?.call(0.8);

      // Embed metadata tags into m4a files using metadata_god
      // Note: webm files don't support tags (would need Vorbis comments which aren't supported)
      if (extension == 'm4a') {
        try {
          // Download artwork for embedding
          Picture? picture;
          if (song.thumbnailUrl.isNotEmpty) {
            final artworkBytes = await _downloadArtwork(song.thumbnailUrl);
            if (artworkBytes != null) {
              picture = Picture(
                data: artworkBytes,
                mimeType: 'image/jpeg',
              );
            }
          }

          final metadata = Metadata(
            title: song.title,
            artist: song.artist,
            picture: picture,
          );
          await MetadataGod.writeMetadata(file: finalPath, metadata: metadata);
          debugPrint('[DownloadService] Embedded tags into m4a: ${song.title}');
        } catch (e) {
          debugPrint('[DownloadService] Tag embedding failed (non-fatal): $e');
        }
      } else {
        debugPrint('[DownloadService] Saved as $extension (tags not supported for webm)');
      }

      // Notify MediaStore so the file appears in library after scan
      try {
        final scanned = await _audioQuery.scanMedia(finalPath);
        debugPrint('[DownloadService] MediaStore scan: $scanned');
      } catch (e) {
        debugPrint('[DownloadService] MediaStore scan error (non-fatal): $e');
      }

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
