import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import '../../domain/repositories/music_repository.dart';
import '../../core/services/innertube/innertube.dart';
import '../../core/services/music_finder.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/youtube_song.dart';
import '../../domain/entities/local_track.dart';
import '../../domain/entities/local_album.dart';
import '../../domain/entities/local_artist.dart';
import '../../domain/entities/local_radio_station.dart';
import '../../domain/entities/local_track_override.dart';
import '../datasources/app_database.dart';

/// Implementation of [MusicRepository] that bridges domain layer with data layer.
/// 
/// This class handles all database access and converts Drift models to domain entities,
/// keeping the presentation layer decoupled from the data layer.
class MusicRepositoryImpl implements MusicRepository {
  final InnerTubeService _innerTube;
  final MusicFinder _musicFinder;
  final AppDatabase _db;

  MusicRepositoryImpl({
    InnerTubeService? innerTube,
    MusicFinder? musicFinder,
    AppDatabase? db,
  })  : _innerTube = innerTube ?? GetIt.I<InnerTubeService>(),
        _musicFinder = musicFinder ?? GetIt.I<MusicFinder>(),
        _db = db ?? GetIt.I<AppDatabase>();

  // === CONVERTERS ===

  /// Maps Drift Track entity to domain LocalTrack
  LocalTrack _trackToLocalTrack(Track track) => LocalTrack(
        path: track.path,
        title: track.title,
        artist: track.artist,
        album: track.album,
        duration: track.duration,
        folderPath: track.folderPath,
        artworkUri: track.artworkUri,
        isFavorite: track.isFavorite,
        mediaStoreId: track.mediaStoreId,
        lastPlayed: track.lastPlayed,
        isExcluded: track.isExcluded,
      );

  /// Maps Drift AlbumWithArtwork to domain LocalAlbum
  LocalAlbum _albumToLocalAlbum(AlbumWithArtwork album) => LocalAlbum(
        title: album.title,
        artist: album.artist,
        artworkPath: album.artworkPath,
        mediaStoreId: album.mediaStoreId,
      );

  /// Maps Drift Artist to domain LocalArtist
  LocalArtist _artistToLocalArtist(Artist artist) => LocalArtist(
        name: artist.name,
      );

  /// Maps Drift RadioStation to domain LocalRadioStation
  LocalRadioStation _radioStationToLocal(RadioStation station) =>
      LocalRadioStation(
        id: station.id,
        name: station.name,
        streamUrl: station.streamUrl,
        imageUrl: station.imageUrl,
      );

  /// Maps Drift TrackOverride to domain LocalTrackOverride
  LocalTrackOverride _trackOverrideToLocal(TrackOverride override) =>
      LocalTrackOverride(
        filePath: override.filePath,
        correctTitle: override.correctTitle ?? '',
        correctArtist: override.correctArtist ?? '',
        thumbnailUrl: override.thumbnailUrl,
        youtubeId: override.youtubeId,
      );

  /// Maps Drift YouTubeTrack to domain YouTubeSong
  YouTubeSong _youtubeTrackToSong(YouTubeTrack track) => YouTubeSong(
        videoId: track.videoId,
        title: track.title,
        artist: track.artist,
        thumbnailUrl: track.thumbnailUrl,
        duration: track.duration ~/ 1000, // Convert ms to seconds
      );

  // === HOME FEED ===

  @override
  Future<Result<List<Map<String, dynamic>>>> getHomeFeed() async {
    try {
      final shelves = await _innerTube.getHomeData();
      final data = shelves.map((shelf) => {
        'title': shelf.title,
        'items': shelf.items,
        'browseId': shelf.browseId,
        'params': shelf.params,
      }).toList();
      return Result.success(data);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  // === LOCAL TRACKS ===

  @override
  Future<List<LocalTrack>> getRecentLocalTracks({int limit = 10}) async {
    final driftTracks = await _musicFinder.getRecentTracks(limit: limit);
    return driftTracks.map(_trackToLocalTrack).toList();
  }

  @override
  Future<List<LocalTrack>> getAllLocalTracks() async {
    final tracks = await _db.getFilteredTracks();
    return tracks.map(_trackToLocalTrack).toList();
  }

  @override
  Future<List<LocalTrack>> getFavoriteTracks() async {
    final tracks = await _db.watchFavoriteTracks().first;
    return tracks.map(_trackToLocalTrack).toList();
  }

  @override
  Future<List<LocalTrack>> getRandomTracks({int limit = 20}) async {
    final tracks = await _db.getRandomTracks(limit: limit);
    return tracks.map(_trackToLocalTrack).toList();
  }

  @override
  Future<List<LocalTrack>> getTracksByFolder(String folderPath) async {
    final tracks = await _db.getTracksByFolder(folderPath);
    return tracks.map(_trackToLocalTrack).toList();
  }

  @override
  Future<List<LocalTrack>> getTracksByAlbum(String albumTitle) async {
    final tracks = await _db.getTracksByAlbum(albumTitle);
    return tracks.map(_trackToLocalTrack).toList();
  }

  @override
  Future<List<LocalTrack>> getTracksByArtist(String artistName) async {
    final tracks = await _db.getTracksByArtist(artistName);
    return tracks.map(_trackToLocalTrack).toList();
  }

  @override
  Stream<List<LocalTrack>> watchFavoriteTracks() {
    return _db.watchFavoriteTracks().map(
        (tracks) => tracks.map(_trackToLocalTrack).toList());
  }

  @override
  Stream<List<LocalTrack>> watchAllTracks() {
    return _db.watchFilteredTracks().map(
        (tracks) => tracks.map(_trackToLocalTrack).toList());
  }

  @override
  Future<void> toggleTrackFavorite(String path, bool isFavorite) async {
    await _db.toggleFavorite(path);
  }

  @override
  Future<LocalTrack?> getTrackByPath(String path) async {
    final tracks = await _db.getFilteredTracks();
    final track = tracks.where((t) => t.path == path).firstOrNull;
    return track != null ? _trackToLocalTrack(track) : null;
  }

  // === TRACK OVERRIDES ===

  @override
  Future<LocalTrackOverride?> getTrackOverride(String filePath) async {
    final override = await (_db.select(_db.trackOverrides)
          ..where((t) => t.filePath.equals(filePath)))
        .getSingleOrNull();
    return override != null ? _trackOverrideToLocal(override) : null;
  }

  @override
  Future<void> saveTrackOverride(LocalTrackOverride override) async {
    await _db.into(_db.trackOverrides).insertOnConflictUpdate(
          TrackOverridesCompanion.insert(
            filePath: override.filePath,
            correctTitle: Value(override.correctTitle),
            correctArtist: Value(override.correctArtist),
            thumbnailUrl: Value(override.thumbnailUrl),
            youtubeId: Value(override.youtubeId),
            updatedAt: DateTime.now(),
          ),
        );
  }

  // === ALBUMS ===

  @override
  Future<List<LocalAlbum>> getAllAlbums() async {
    final albums = await _db.getAllAlbums();
    return albums.map(_albumToLocalAlbum).toList();
  }

  @override
  Future<LocalAlbum?> getAlbumByTitle(String title) async {
    final albums = await _db.getAllAlbums();
    final album = albums.where((a) => a.title == title).firstOrNull;
    return album != null ? _albumToLocalAlbum(album) : null;
  }

  @override
  Stream<List<LocalAlbum>> watchAllAlbums() {
    // AppDatabase doesn't have a watch method for albums, so we create one
    // by watching all tracks and deriving albums
    return _db.watchFilteredTracks().asyncMap((_) async {
      final albums = await _db.getAllAlbums();
      return albums.map(_albumToLocalAlbum).toList();
    });
  }

  // === ARTISTS ===

  @override
  Future<List<LocalArtist>> getAllArtists() async {
    final artists = await _db.getAllArtists();
    return artists.map(_artistToLocalArtist).toList();
  }

  @override
  Future<LocalArtist?> getArtistByName(String name) async {
    final artists = await _db.getAllArtists();
    final artist = artists.where((a) => a.name == name).firstOrNull;
    return artist != null ? _artistToLocalArtist(artist) : null;
  }

  @override
  Stream<List<LocalArtist>> watchAllArtists() {
    return _db.watchFilteredTracks().asyncMap((_) async {
      final artists = await _db.getAllArtists();
      return artists.map(_artistToLocalArtist).toList();
    });
  }

  // === FOLDERS ===

  @override
  Future<List<String>> getAllFolders() async {
    return await _db.getAllFolders();
  }

  @override
  Stream<List<String>> watchAllFolders() {
    return _db.watchFilteredTracks().asyncMap((_) async {
      return await _db.getAllFolders();
    });
  }

  // === RADIO STATIONS ===

  @override
  Future<List<LocalRadioStation>> getAllRadioStations() async {
    final stations = await _db.getAllRadioStations();
    return stations.map(_radioStationToLocal).toList();
  }

  @override
  Future<void> addRadioStation(LocalRadioStation station) async {
    await _db.addRadioStation(
      station.name,
      station.streamUrl,
      imageUrl: station.imageUrl,
    );
  }

  @override
  Future<void> deleteRadioStation(int id) async {
    await _db.deleteRadioStation(id);
  }

  @override
  Stream<List<LocalRadioStation>> watchRadioStations() {
    return _db.watchRadioStations().map(
        (stations) => stations.map(_radioStationToLocal).toList());
  }

  // === YOUTUBE/ONLINE ===

  @override
  Future<Result<List<YouTubeSong>>> search(String query) async {
    try {
      final results = await _innerTube.search(query);
      return Result.success(results);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLibraryPlaylists() async {
    final playlists = await _innerTube.getLibraryPlaylists();
    return playlists.map((p) => {
      'id': p.id,
      'title': p.title,
      'thumbnailUrl': p.thumbnailUrl,
      'trackCount': p.trackCount,
      'author': p.author,
    }).toList();
  }

  @override
  Future<List<YouTubeSong>> getYouTubeFavorites() async {
    final tracks = await (_db.select(_db.youTubeTracks)
          ..where((t) => t.isFavorite.equals(true))
          ..orderBy([(t) => OrderingTerm(
              expression: t.likedAt, mode: OrderingMode.desc)]))
        .get();
    return tracks.map(_youtubeTrackToSong).toList();
  }

  @override
  Stream<List<YouTubeSong>> watchYouTubeFavorites() {
    return (_db.select(_db.youTubeTracks)
          ..where((t) => t.isFavorite.equals(true))
          ..orderBy([(t) => OrderingTerm(
              expression: t.likedAt, mode: OrderingMode.desc)]))
        .watch()
        .map((tracks) => tracks.map(_youtubeTrackToSong).toList());
  }

  // === PLAYBACK HISTORY ===

  @override
  Future<List<LocalTrack>> getPlaybackHistory({int limit = 50}) async {
    final tracks = await _db.getRecentTracks(limit: limit);
    return tracks.map(_trackToLocalTrack).toList();
  }

  @override
  Future<void> addToPlaybackHistory(String trackPath) async {
    await _db.markLocalTrackAsPlayed(trackPath);
  }
}
