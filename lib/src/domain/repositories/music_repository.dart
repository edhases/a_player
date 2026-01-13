import '../entities/youtube_song.dart';
import '../../core/utils/result.dart';
import '../../data/datasources/app_database.dart'; // Using Drift class for now

abstract class MusicRepository {
  Future<Result<List<Map<String, dynamic>>>> getHomeFeed();
  Future<List<Track>> getRecentLocalTracks({int limit = 10});
  Future<Result<List<YouTubeSong>>> search(String query);
  Future<List<Map<String, dynamic>>> getLibraryPlaylists();
}
