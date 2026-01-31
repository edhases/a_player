/// Constants for InnerTube API
class InnerTubeConstants {
  InnerTubeConstants._();

  /// Base URL for YouTube Music API
  static const String baseUrl = 'https://music.youtube.com/youtubei/v1';

  /// Web API key
  static const String webApiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';

  /// Android Music API key
  static const String androidApiKey = 'AIzaSyAOghZGza2MQSZkY_zfZ370N-PUdXEo8AI';

  /// User agent for web requests
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  /// YouTube Music URL
  static const String musicUrl = 'https://music.youtube.com';

  /// YouTube URL
  static const String youtubeUrl = 'https://www.youtube.com';

  /// Thumbnail URL template
  static String thumbnailUrl(String videoId, {String quality = 'maxresdefault'}) =>
      'https://i.ytimg.com/vi/$videoId/$quality.jpg';

  /// High quality thumbnail
  static String hqThumbnail(String videoId) =>
      thumbnailUrl(videoId, quality: 'hqdefault');

  /// Standard quality thumbnail
  static String sdThumbnail(String videoId) =>
      thumbnailUrl(videoId, quality: 'sddefault');
}
