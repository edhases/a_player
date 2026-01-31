import '../entities/youtube_song.dart';
import '../entities/local_track.dart';
import '../entities/local_album.dart';
import '../entities/local_artist.dart';
import '../entities/local_radio_station.dart';
import '../entities/local_track_override.dart';
import '../../core/utils/result.dart';

/// Abstract repository interface for music operations.
/// 
/// This interface decouples the presentation layer from the data layer,
/// allowing blocs and screens to work with domain entities instead of
/// Drift models directly.
abstract class MusicRepository {
  // === Home Feed ===
  Future<Result<List<Map<String, dynamic>>>> getHomeFeed();
  
  // === Local Tracks ===
  Future<List<LocalTrack>> getRecentLocalTracks({int limit = 10});
  Future<List<LocalTrack>> getAllLocalTracks();
  Future<List<LocalTrack>> getFavoriteTracks();
  Future<List<LocalTrack>> getRandomTracks({int limit = 20});
  Future<List<LocalTrack>> getTracksByFolder(String folderPath);
  Future<List<LocalTrack>> getTracksByAlbum(String albumTitle);
  Future<List<LocalTrack>> getTracksByArtist(String artistName);
  Stream<List<LocalTrack>> watchFavoriteTracks();
  Stream<List<LocalTrack>> watchAllTracks();
  Future<void> toggleTrackFavorite(String path, bool isFavorite);
  Future<LocalTrack?> getTrackByPath(String path);
  
  // === Track Overrides ===
  Future<LocalTrackOverride?> getTrackOverride(String filePath);
  Future<void> saveTrackOverride(LocalTrackOverride override);
  
  // === Albums ===
  Future<List<LocalAlbum>> getAllAlbums();
  Future<LocalAlbum?> getAlbumByTitle(String title);
  Stream<List<LocalAlbum>> watchAllAlbums();
  
  // === Artists ===
  Future<List<LocalArtist>> getAllArtists();
  Future<LocalArtist?> getArtistByName(String name);
  Stream<List<LocalArtist>> watchAllArtists();
  
  // === Folders ===
  Future<List<String>> getAllFolders();
  Stream<List<String>> watchAllFolders();
  
  // === Radio Stations ===
  Future<List<LocalRadioStation>> getAllRadioStations();
  Future<void> addRadioStation(LocalRadioStation station);
  Future<void> deleteRadioStation(int id);
  Stream<List<LocalRadioStation>> watchRadioStations();
  
  // === YouTube/Online ===
  Future<Result<List<YouTubeSong>>> search(String query);
  Future<List<Map<String, dynamic>>> getLibraryPlaylists();
  Future<List<YouTubeSong>> getYouTubeFavorites();
  Stream<List<YouTubeSong>> watchYouTubeFavorites();
  
  // === Playback History ===
  Future<List<LocalTrack>> getPlaybackHistory({int limit = 50});
  Future<void> addToPlaybackHistory(String trackPath);
}
