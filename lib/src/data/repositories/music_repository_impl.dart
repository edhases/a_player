import 'package:get_it/get_it.dart';
import '../../domain/repositories/music_repository.dart';
import '../../core/services/innertube_service.dart';
import '../../core/services/music_finder.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/youtube_song.dart';
import '../../data/datasources/app_database.dart';

class MusicRepositoryImpl implements MusicRepository {
  final InnerTubeService _innerTube;
  final MusicFinder _musicFinder;

  MusicRepositoryImpl({InnerTubeService? innerTube, MusicFinder? musicFinder})
      : _innerTube = innerTube ?? GetIt.I<InnerTubeService>(),
        _musicFinder = musicFinder ?? GetIt.I<MusicFinder>();

  @override
  Future<Result<List<Map<String, dynamic>>>> getHomeFeed() async {
    return await _innerTube.getHomeData();
  }

  @override
  Future<List<Track>> getRecentLocalTracks({int limit = 10}) async {
    return await _musicFinder.getRecentTracks(limit: limit);
  }

  @override
  Future<Result<List<YouTubeSong>>> search(String query) async {
    return await _innerTube.search(query);
  }

  @override
  Future<List<Map<String, dynamic>>> getLibraryPlaylists() async {
    return await _innerTube.getLibraryPlaylists();
  }
}
