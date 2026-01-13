import '../../../domain/entities/youtube_song.dart';

class RendererParser {
  static List<YouTubeSong> extractSongs(List<dynamic> items) {
    final results = <YouTubeSong>[];

    for (final item in items) {
      final mrlir = item['musicResponsiveListItemRenderer'];
      if (mrlir != null) {
        final song = _parseSingleSong(mrlir);
        if (song != null) results.add(song);
      }
    }

    return results;
  }

  static YouTubeSong? _parseSingleSong(Map<String, dynamic> mrlir) {
    try {
      final title = mrlir['flexColumns']?[0]
                  ['musicResponsiveListItemFlexColumnRenderer']['text']?['runs']
              ?[0]?['text'] ??
          mrlir['title']?['runs']?[0]?['text'];

      if (title == null) return null;

      String artist = "Unknown";
      final flexCol1 =
          mrlir['flexColumns']?[1]['musicResponsiveListItemFlexColumnRenderer'];
      if (flexCol1 != null) {
        final runs = flexCol1['text']?['runs'] as List?;
        if (runs != null && runs.isNotEmpty) artist = runs[0]['text'];
      } else {
        artist = mrlir['subtitle']?['runs']?[0]?['text'] ?? "Unknown";
      }

      String? videoId;
      final playButton = mrlir['overlay']?['musicItemThumbnailOverlayRenderer']
          ?['content']?['musicPlayButtonRenderer'];
      videoId = playButton?['playNavigationEndpoint']?['watchEndpoint']
              ?['videoId'] ??
          mrlir['navigationEndpoint']?['watchEndpoint']?['videoId'] ??
          mrlir['onTap']?['watchEndpoint']?['videoId'];

      if (videoId == null) return null;

      final thumbnails = (mrlir['thumbnail']?['musicThumbnailRenderer'] ??
              mrlir['thumbnailRenderer']
                  ?['musicThumbnailRenderer'])?['thumbnail']?['thumbnails']
          as List?;
      String thumbUrl = '';
      if (thumbnails != null && thumbnails.isNotEmpty) {
        thumbUrl = thumbnails.last['url'];
      }

      return YouTubeSong(
        videoId: videoId,
        title: title,
        artist: artist,
        thumbnailUrl: thumbUrl,
      );
    } catch (e) {
      return null;
    }
  }
}
