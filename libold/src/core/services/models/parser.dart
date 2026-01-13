import 'package:oxide_player/src/domain/entities/youtube_song.dart';
import 'base_renderer.dart';

class RendererParser {
  static YouTubeSong? extractSong(Map<String, dynamic> json) {
    // Try to find MusicResponsiveListItemRenderer structure
    final mrlir = json['musicResponsiveListItemRenderer'];
    if (mrlir == null) return null;

    try {
      final title = _extractText(mrlir['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']
          ?['text']?['runs']);
      
      String artist = "Unknown";
      final artistRuns = mrlir['flexColumns']?[1]?['musicResponsiveListItemFlexColumnRenderer']
          ?['text']?['runs'];
      if (artistRuns is List) {
        artist = _extractArtistFromRuns(artistRuns);
      }

      String? videoId;
      final playButton = mrlir['overlay']?['musicItemThumbnailOverlayRenderer']
          ?['content']?['musicPlayButtonRenderer'];
      videoId = playButton?['playNavigationEndpoint']?['watchEndpoint']?['videoId'];

      final playlistItemData = mrlir['playlistItemData'];
      if (videoId == null && playlistItemData != null && playlistItemData['videoId'] != null) {
        videoId = playlistItemData['videoId'];
      }
      
      if (videoId == null) {
        videoId = mrlir['navigationEndpoint']?['watchEndpoint']?['videoId'];
      }

      final thumbnails = mrlir['thumbnail']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'] as List?;
      String thumbUrl = '';
      if (thumbnails != null && thumbnails.isNotEmpty) {
        // Get highest resolution thumbnail
        thumbUrl = thumbnails.last['url'];
      }

      if (title != null && videoId != null) {
        return YouTubeSong(
          videoId: videoId,
          title: title,
          artist: artist,
          thumbnailUrl: thumbUrl,
        );
      }
    } catch (e) {
      // Parsing failed
    }
    return null;
  }

  static String? _extractText(List? runs) {
    if (runs == null || runs.isEmpty) return null;
    return runs[0]['text'];
  }

  static String _extractArtistFromRuns(List runs) {
    for (var run in runs) {
      final text = run['text'];
      if (text != ' • ' && !text.contains('views') && !text.contains('plays') && !text.contains(':')) { 
        return text;
      }
    }
    return "Unknown";
  }

  static List<YouTubeSong> extractSongs(List contents) {
    final songs = <YouTubeSong>[];
    for (final item in contents) {
      final song = extractSong(item);
      if (song != null) {
        songs.add(song);
      }
    }
    return songs;
  }
}