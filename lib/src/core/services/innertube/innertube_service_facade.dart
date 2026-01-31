import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/youtube_song.dart';
import '../google_auth_service.dart';
import '../settings_service.dart';
import 'innertube_artist_service.dart';
import 'innertube_base.dart';
import 'innertube_home_service.dart';
import 'innertube_lyrics_service.dart';
import 'innertube_parser.dart';
import 'innertube_playlist_service.dart';
import 'innertube_search_service.dart';
import 'innertube_tracking_service.dart';

/// Facade service that provides backward compatibility with the original InnerTubeService.
///
/// This class delegates to the modular services while maintaining the original API.
/// New code should prefer using the individual services directly for better separation
/// of concerns.
class InnerTubeService {
  final GoogleAuthService _authService;
  final RateLimiter _rateLimiter;
  final Logger _logger;
  final InnerTubeParser _parser;

  // Modular services
  late final InnerTubeSearchService _searchService;
  late final InnerTubeHomeService _homeService;
  late final InnerTubePlaylistService _playlistService;
  late final InnerTubeArtistService _artistService;
  late final InnerTubeLyricsService _lyricsService;
  late final InnerTubeTrackingService _trackingService;

  InnerTubeService({
    GoogleAuthService? googleAuthService,
    // ignore: unused_element_parameter - kept for backward compatibility
    Object? db,
    required SettingsService settingsService,
    RateLimiter? rateLimiter,
    Logger? logger,
    Dio? dio,
  })  : _authService = googleAuthService ?? GetIt.I<GoogleAuthService>(),
        _rateLimiter = rateLimiter ?? RateLimiter(),
        _logger = logger ?? Logger(printer: PrettyPrinter(methodCount: 0)),
        _parser = InnerTubeParser() {
    // Initialize modular services with shared dependencies
    _searchService = InnerTubeSearchService(
      authService: _authService,
      rateLimiter: _rateLimiter,
      logger: _logger,
      dio: dio,
      parser: _parser,
    );

    _homeService = InnerTubeHomeService(
      authService: _authService,
      rateLimiter: _rateLimiter,
      logger: _logger,
      dio: dio,
      parser: _parser,
    );

    _playlistService = InnerTubePlaylistService(
      authService: _authService,
      rateLimiter: _rateLimiter,
      logger: _logger,
      dio: dio,
      parser: _parser,
    );

    _artistService = InnerTubeArtistService(
      authService: _authService,
      rateLimiter: _rateLimiter,
      logger: _logger,
      dio: dio,
      parser: _parser,
    );

    _lyricsService = InnerTubeLyricsService(
      authService: _authService,
      rateLimiter: _rateLimiter,
      logger: _logger,
      dio: dio,
      parser: _parser,
    );

    _trackingService = InnerTubeTrackingService(
      authService: _authService,
      rateLimiter: _rateLimiter,
      logger: _logger,
      dio: dio,
      parser: _parser,
    );
  }

  // ============ Search ============

  /// Search YouTube Music
  Future<List<YouTubeSong>> search(
    String query, {
    String filter = 'songs',
    int limit = 20,
  }) =>
      _searchService.search(query, filter: filter, limit: limit);

  /// Get search suggestions
  Future<List<String>> getSearchSuggestions(String query) =>
      _searchService.getSearchSuggestions(query);

  /// Find artist ID by name
  Future<String?> findArtistId(String artistName) =>
      _searchService.findArtistId(artistName);

  // ============ Home ============

  /// Get home feed data
  Future<List<HomeShelf>> getHomeData() => _homeService.getHomeData();

  /// Get charts
  Future<List<HomeShelf>> getCharts() => _homeService.getCharts();

  /// Get new releases
  Future<List<HomeShelf>> getNewReleases() => _homeService.getNewReleases();

  // ============ Playlists ============

  /// Get playlist tracks
  Future<List<YouTubeSong>> getPlaylistTracks(String playlistId) =>
      _playlistService.getPlaylistTracks(playlistId);

  /// Get album tracks
  Future<List<YouTubeSong>> getAlbumTracks(String albumId) =>
      _playlistService.getAlbumTracks(albumId);

  /// Get library playlists
  Future<List<YouTubePlaylist>> getLibraryPlaylists() =>
      _playlistService.getLibraryPlaylists();

  /// Get liked songs
  Future<List<YouTubeSong>> getYouTubeLikedSongs() =>
      _playlistService.getLikedSongs();

  /// Rate a song
  Future<bool> rateSong(String videoId, String rating) =>
      _playlistService.rateSong(videoId, rating);

  // ============ Artists ============

  /// Get artist info
  Future<YouTubeArtist?> getArtistInfo(String browseId) =>
      _artistService.getArtistInfo(browseId);

  /// Get artist top tracks
  Future<List<YouTubeSong>> getArtistTopTracks(String browseId) =>
      _artistService.getArtistTopTracks(browseId);

  /// Get artist albums
  Future<List<YouTubeSong>> getArtistAlbums(String browseId) =>
      _artistService.getArtistAlbums(browseId);

  /// Get radio tracks
  Future<List<YouTubeSong>> getRadioTracks(String videoId) =>
      _artistService.getRadioTracks(videoId);

  // ============ Lyrics ============

  /// Get lyrics for a video
  Future<Map<String, dynamic>?> getLyrics(String videoId) async {
    final result = await _lyricsService.getLyrics(videoId);
    return result?.toMap();
  }

  /// Check if lyrics are available
  Future<bool> hasLyrics(String videoId) => _lyricsService.hasLyrics(videoId);

  // ============ Tracking ============

  /// Get playback tracking URL for a video
  Future<String?> getPlaybackTrackingUrl(String videoId) =>
      _trackingService.getPlaybackTrackingUrl(videoId);

  /// Report playback to YouTube history
  Future<bool> reportPlayback(String trackingUrl) =>
      _trackingService.reportPlayback(trackingUrl);

  // ============ Auth ============

  /// Check if signed in
  Future<bool> isSignedIn() => _authService.isSignedIn();

  /// Sign out
  Future<void> logout() => _authService.signOut();

  // ============ Dispose ============

  /// Dispose all services
  void dispose() {
    _searchService.dispose();
    _homeService.dispose();
    _playlistService.dispose();
    _artistService.dispose();
    _lyricsService.dispose();
    _trackingService.dispose();
  }
}
