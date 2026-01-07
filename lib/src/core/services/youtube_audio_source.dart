import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeHelper {
  final YoutubeExplode _yt;

  YouTubeHelper() : _yt = YoutubeExplode();

  /// Отримує пряме посилання на аудіопотік найкращої якості для вказаного videoId.
  Future<String?> getAudioUrl(String videoId) async {
    try {
      // Отримуємо маніфест потоків
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      
      // Вибираємо тільки аудіо з найвищим бітрейтом (m4a/opus)
      var audioStream = manifest.audioOnly.withHighestBitrate();
      
      // Повертаємо URL. Цей URL дійсний певний час (зазвичай кілька годин).
      return audioStream.url.toString();
    } catch (e) {
      print('Error fetching YouTube audio URL: $e');
      return null;
    }
  }

  /// Отримує метадані (назву, автора, арт) відео, якщо потрібно.
  /// (Зазвичай ми це вже маємо з пошуку, але як backup).
  Future<Video?> getVideoDetails(String videoId) async {
    try {
      return await _yt.videos.get(videoId);
    } catch (e) {
      return null;
    }
  }
  
  void dispose() {
    _yt.close();
  }
}
