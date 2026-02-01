import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/cache_service.dart';
import '../../core/services/innertube/innertube.dart';
import '../../core/services/music_finder.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/services/youtube_helper.dart';
import '../../data/datasources/app_database.dart';
import '../../domain/entities/home_section.dart';
import '../../domain/entities/youtube_song.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Test tracking for verification
class TestTracker {
  static final List<String> playedVideoIds = [];
  static final List<String> likedVideoIds = [];
  static final List<String> cachedVideoIds = [];
  static final List<String> searchQueries = [];
  static final List<String> navigatedArtists = [];
  static final List<String> navigatedPlaylists = [];
  static int playCount = 0;
  static int pauseCount = 0;
  static int skipNextCount = 0;
  static int skipPrevCount = 0;
  static int seekCount = 0;
  static int shuffleToggleCount = 0;
  static int repeatToggleCount = 0;

  static void reset() {
    playedVideoIds.clear();
    likedVideoIds.clear();
    cachedVideoIds.clear();
    searchQueries.clear();
    navigatedArtists.clear();
    navigatedPlaylists.clear();
    playCount = 0;
    pauseCount = 0;
    skipNextCount = 0;
    skipPrevCount = 0;
    seekCount = 0;
    shuffleToggleCount = 0;
    repeatToggleCount = 0;
  }

  static void recordPlay(String videoId) {
    playedVideoIds.add(videoId);
    playCount++;
  }

  static void recordLike(String videoId) {
    likedVideoIds.add(videoId);
  }

  static void recordCache(String videoId) {
    cachedVideoIds.add(videoId);
  }

  static void recordSearch(String query) {
    searchQueries.add(query);
  }
}

class FakeInnerTubeService extends InnerTubeService {
  FakeInnerTubeService({required super.settingsService});

  static const _artistId = 'ARTIST_1';
  static const _artistIdUa = 'ARTIST_UA';
  static const _artistIdRock = 'ARTIST_ROCK';
  static const _artistIdElectronic = 'ARTIST_ELECTRONIC';
  static const _playlistId = 'PL_TEST_1';
  static const _playlistIdMix = 'PL_MIX_1';
  static const _albumId = 'ALBUM_TEST_1';

  // Track search query history for testing
  final List<String> searchHistory = [];

  // Configurable delays for testing loading states
  Duration searchDelay = const Duration(milliseconds: 150);
  Duration playlistDelay = const Duration(milliseconds: 100);

  // Failure simulation flags
  bool simulateSearchFailure = false;
  bool simulatePlaylistFailure = false;
  String? failureMessage;

  static final List<YouTubeSong> _searchResults = [
    // Primary test tracks
    YouTubeSong(
      videoId: 'testvideo01',
      title: 'Enimkon',
      artist: 'Test Artist',
      thumbnailUrl: 'https://test.example/thumb/testvideo01.jpg',
      duration: 180,
      artistId: _artistId,
      category: 'Song',
    ),
    YouTubeSong(
      videoId: 'testvideo02',
      title: 'Enimkon Video',
      artist: 'Test Artist',
      thumbnailUrl: 'https://test.example/thumb/testvideo02.jpg',
      duration: 200,
      artistId: _artistId,
      category: 'Video',
    ),
    YouTubeSong(
      videoId: _playlistId,
      title: 'Enimkon Playlist',
      artist: 'Test Artist',
      thumbnailUrl: 'https://test.example/thumb/playlist.jpg',
      duration: 0,
      isPlaylist: true,
      playlistId: _playlistId,
      category: 'Playlist',
      artistId: _artistId,
    ),
    // Ukrainian test track
    YouTubeSong(
      videoId: 'winterheat1',
      title: 'Я зігрію тебе взимку',
      artist: 'Український Артист',
      thumbnailUrl: 'https://test.example/thumb/ua.jpg',
      duration: 210,
      artistId: _artistIdUa,
      category: 'Song',
    ),
    // Edge case: No artist ID
    YouTubeSong(
      videoId: 'noartist01',
      title: 'No Artist ID Song',
      artist: 'Unknown Artist',
      thumbnailUrl: 'https://test.example/thumb/noartist.jpg',
      duration: 150,
      category: 'Song',
    ),
    // Long title test
    YouTubeSong(
      videoId: 'longvideo01',
      title:
          'This Is A Very Long Song Title That Should Be Truncated In The UI With Ellipsis',
      artist: 'Artist With Also Very Long Name That Tests Overflow Handling',
      thumbnailUrl: 'https://test.example/thumb/long.jpg',
      duration: 300,
      artistId: _artistId,
      category: 'Song',
    ),
    // Short duration (edge case)
    YouTubeSong(
      videoId: 'shortvideo',
      title: 'Short Track',
      artist: 'Test Artist',
      thumbnailUrl: 'https://test.example/thumb/short.jpg',
      duration: 15,
      artistId: _artistId,
      category: 'Song',
    ),
    // Very long duration
    YouTubeSong(
      videoId: 'longduration',
      title: 'Extended Mix',
      artist: 'Electronic Artist',
      thumbnailUrl: 'https://test.example/thumb/long_duration.jpg',
      duration: 3600, // 1 hour
      artistId: _artistIdElectronic,
      category: 'Song',
    ),
    // Album entry
    YouTubeSong(
      videoId: _albumId,
      title: 'Test Album',
      artist: 'Rock Artist',
      thumbnailUrl: 'https://test.example/thumb/album.jpg',
      duration: 0,
      isPlaylist: true,
      playlistId: _albumId,
      category: 'Album',
      artistId: _artistIdRock,
    ),
    // Special characters in title
    YouTubeSong(
      videoId: 'specialchars',
      title: 'Song with "Quotes" & <Special> Characters!',
      artist: 'Test & Artist',
      thumbnailUrl: 'https://test.example/thumb/special.jpg',
      duration: 180,
      artistId: _artistId,
      category: 'Song',
    ),
  ];

  // Additional search results for specific queries
  static final Map<String, List<YouTubeSong>> _querySpecificResults = {
    'rock': [
      YouTubeSong(
        videoId: 'rock001',
        title: 'Rock Anthem',
        artist: 'Rock Artist',
        thumbnailUrl: 'https://test.example/thumb/rock1.jpg',
        duration: 240,
        artistId: _artistIdRock,
        category: 'Song',
      ),
      YouTubeSong(
        videoId: 'rock002',
        title: 'Heavy Rock',
        artist: 'Rock Artist',
        thumbnailUrl: 'https://test.example/thumb/rock2.jpg',
        duration: 280,
        artistId: _artistIdRock,
        category: 'Song',
      ),
    ],
    'electronic': [
      YouTubeSong(
        videoId: 'elec001',
        title: 'Electronic Dreams',
        artist: 'Electronic Artist',
        thumbnailUrl: 'https://test.example/thumb/elec1.jpg',
        duration: 360,
        artistId: _artistIdElectronic,
        category: 'Song',
      ),
    ],
    'empty': [], // For testing empty results
  };

  static final List<YouTubeSong> _playlistTracks = [
    YouTubeSong(
      videoId: 'plisttrk01',
      title: 'Playlist Track 1',
      artist: 'Test Artist',
      thumbnailUrl: 'https://test.example/thumb/pl1.jpg',
      duration: 190,
      artistId: _artistId,
    ),
    YouTubeSong(
      videoId: 'plisttrk02',
      title: 'Playlist Track 2',
      artist: 'Test Artist',
      thumbnailUrl: 'https://test.example/thumb/pl2.jpg',
      duration: 175,
      artistId: _artistId,
    ),
    YouTubeSong(
      videoId: 'plisttrk03',
      title: 'Playlist Track 3',
      artist: 'Test Artist',
      thumbnailUrl: 'https://test.example/thumb/pl3.jpg',
      duration: 200,
      artistId: _artistId,
    ),
    YouTubeSong(
      videoId: 'plisttrk04',
      title: 'Playlist Track 4 - Long Name Edition Remix',
      artist: 'Test Artist',
      thumbnailUrl: 'https://test.example/thumb/pl4.jpg',
      duration: 250,
      artistId: _artistId,
    ),
  ];

  static final List<YouTubeSong> _mixPlaylistTracks = [
    YouTubeSong(
      videoId: 'mix001',
      title: 'Mix Track 1',
      artist: 'Various Artists',
      thumbnailUrl: 'https://test.example/thumb/mix1.jpg',
      duration: 210,
      artistId: _artistId,
    ),
    YouTubeSong(
      videoId: 'mix002',
      title: 'Mix Track 2',
      artist: 'Various Artists',
      thumbnailUrl: 'https://test.example/thumb/mix2.jpg',
      duration: 195,
      artistId: _artistIdRock,
    ),
  ];

  static final List<YouTubeSong> _artistTracks = [
    YouTubeSong(
      videoId: 'artisttrk1',
      title: 'Artist Top Track 1',
      artist: 'Test Artist',
      thumbnailUrl: 'https://test.example/thumb/at1.jpg',
      duration: 200,
      artistId: _artistId,
    ),
    YouTubeSong(
      videoId: 'artisttrk2',
      title: 'Artist Top Track 2',
      artist: 'Test Artist',
      thumbnailUrl: 'https://test.example/thumb/at2.jpg',
      duration: 220,
      artistId: _artistId,
    ),
    YouTubeSong(
      videoId: 'artisttrk3',
      title: 'Artist Top Track 3',
      artist: 'Test Artist',
      thumbnailUrl: 'https://test.example/thumb/at3.jpg',
      duration: 185,
      artistId: _artistId,
    ),
  ];

  static final List<YouTubeSong> _artistTracksUa = [
    YouTubeSong(
      videoId: 'artistua01',
      title: 'UA Track 1',
      artist: 'Український Артист',
      thumbnailUrl: 'https://test.example/thumb/ua1.jpg',
      duration: 195,
      artistId: _artistIdUa,
    ),
    YouTubeSong(
      videoId: 'artistua02',
      title: 'UA Track 2 - Народна',
      artist: 'Український Артист',
      thumbnailUrl: 'https://test.example/thumb/ua2.jpg',
      duration: 240,
      artistId: _artistIdUa,
    ),
  ];

  static final List<YouTubeSong> _rockArtistTracks = [
    YouTubeSong(
      videoId: 'rockart01',
      title: 'Rock Album Track 1',
      artist: 'Rock Artist',
      thumbnailUrl: 'https://test.example/thumb/ra1.jpg',
      duration: 260,
      artistId: _artistIdRock,
    ),
    YouTubeSong(
      videoId: 'rockart02',
      title: 'Rock Album Track 2',
      artist: 'Rock Artist',
      thumbnailUrl: 'https://test.example/thumb/ra2.jpg',
      duration: 310,
      artistId: _artistIdRock,
    ),
  ];

  @override
  Future<List<YouTubeSong>> search(String query,
      {String filter = 'songs', int limit = 20}) async {
    searchHistory.add(query);
    TestTracker.recordSearch(query);
    await Future<void>.delayed(searchDelay);

    if (simulateSearchFailure) {
      throw Exception(failureMessage ?? 'Simulated search failure');
    }

    // Check for query-specific results
    final lowerQuery = query.toLowerCase();
    if (_querySpecificResults.containsKey(lowerQuery)) {
      return _querySpecificResults[lowerQuery]!;
    }

    // Filter results by query for more realistic behavior
    final filtered = _searchResults.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery);
    }).toList();

    // If no match, return all results (like actual search does)
    return filtered.isEmpty ? _searchResults : filtered;
  }

  // getSongUrl is not part of facade, kept for test compatibility
  Future<Map<String, String>?> getSongUrl(String videoId) async {
    return {'url': 'https://example.test/audio/$videoId', 'agent': 'TestUA'};
  }

  @override
  Future<List<YouTubeSong>> getPlaylistTracks(String playlistId) async {
    await Future<void>.delayed(playlistDelay);
    if (simulatePlaylistFailure) {
      throw Exception(failureMessage ?? 'Simulated playlist failure');
    }
    if (playlistId == _playlistId) return _playlistTracks;
    if (playlistId == _playlistIdMix) return _mixPlaylistTracks;
    if (playlistId == _albumId) return _rockArtistTracks;
    return _playlistTracks;
  }

  @override
  Future<List<YouTubeSong>> getArtistTopTracks(String browseId) async {
    TestTracker.navigatedArtists.add(browseId);
    if (browseId == _artistIdUa) return _artistTracksUa;
    if (browseId == _artistIdRock) return _rockArtistTracks;
    return _artistTracks;
  }

  @override
  Future<List<YouTubeSong>> getRadioTracks(String videoId) async {
    return [
      YouTubeSong(
        videoId: 'radio001',
        title: 'Radio Track 1',
        artist: 'Radio Artist',
        thumbnailUrl: '',
        duration: 180,
      ),
      YouTubeSong(
        videoId: 'radio002',
        title: 'Radio Track 2',
        artist: 'Radio Artist',
        thumbnailUrl: '',
        duration: 200,
      ),
    ];
  }

  @override
  Future<bool> rateSong(String videoId, String rating) async {
    return true;
  }
}

class FakeRecommendationService extends RecommendationService {
  FakeRecommendationService(
    super.yt,
    super.innerTube,
    super.db, {
    super.settingsService,
  });

  // Allow customization of sections for testing
  static List<HomeSection>? customSections;

  // Track how many times feed was loaded
  static int feedLoadCount = 0;

  static List<HomeSection> buildSections() {
    if (customSections != null) return customSections!;

    return [
      HomeSection(
        title: 'Quick Picks',
        type: SectionType.horizontal,
        songs: [
          YouTubeSong(
            videoId: 'testvideo01',
            title: 'Enimkon',
            artist: 'Test Artist',
            thumbnailUrl: 'https://test.example/thumb/quick1.jpg',
            duration: 180,
            artistId: 'ARTIST_1',
          ),
          YouTubeSong(
            videoId: 'testvideo02',
            title: 'Warm Start',
            artist: 'Test Artist',
            thumbnailUrl: 'https://test.example/thumb/quick2.jpg',
            duration: 200,
            artistId: 'ARTIST_1',
          ),
          YouTubeSong(
            videoId: 'testvideo03',
            title: 'Morning Vibes',
            artist: 'Chill Artist',
            thumbnailUrl: 'https://test.example/thumb/quick3.jpg',
            duration: 230,
            artistId: 'ARTIST_CHILL',
          ),
        ],
      ),
      HomeSection(
        title: 'Made for You',
        type: SectionType.grid,
        songs: [
          YouTubeSong(
            videoId: 'mix0000001',
            title: 'Daily Mix 1',
            artist: 'Various',
            thumbnailUrl: 'https://test.example/thumb/mix1.jpg',
            duration: 0,
            isPlaylist: true,
            playlistId: 'MIX_1',
          ),
          YouTubeSong(
            videoId: 'mix0000002',
            title: 'Daily Mix 2',
            artist: 'Various',
            thumbnailUrl: 'https://test.example/thumb/mix2.jpg',
            duration: 0,
            isPlaylist: true,
            playlistId: 'MIX_2',
          ),
          YouTubeSong(
            videoId: 'supermix',
            title: 'Supermix',
            artist: 'For You',
            thumbnailUrl: 'https://test.example/thumb/supermix.jpg',
            duration: 0,
            isPlaylist: true,
            playlistId: 'SUPERMIX',
          ),
        ],
      ),
      HomeSection(
        title: 'Recommended',
        type: SectionType.grid,
        songs: [
          YouTubeSong(
            videoId: 'reco000001',
            title: 'Recommended Track',
            artist: 'Test Artist',
            thumbnailUrl: 'https://test.example/thumb/reco1.jpg',
            duration: 190,
            artistId: 'ARTIST_1',
          ),
          YouTubeSong(
            videoId: 'reco000002',
            title: 'Discover Weekly Hit',
            artist: 'New Artist',
            thumbnailUrl: 'https://test.example/thumb/reco2.jpg',
            duration: 210,
            artistId: 'ARTIST_NEW',
          ),
        ],
      ),
      HomeSection(
        title: 'Your Library',
        type: SectionType.horizontal,
        songs: [
          YouTubeSong(
            videoId: 'local:test_song.mp3',
            title: 'Local Test Song',
            artist: 'Local Artist',
            thumbnailUrl: '',
            duration: 160,
          ),
        ],
      ),
    ];
  }

  @override
  Future<void> init() async {}

  @override
  Future<List<HomeSection>> getPersonalizedFeed() async {
    feedLoadCount++;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return buildSections();
  }

  @override
  Future<void> addToHistoryManual({
    required String videoId,
    required String title,
    required String artist,
    required String thumbnailUrl,
  }) async {}

  @override
  Future<void> addToHistory(Video video) async {}

  static void reset() {
    customSections = null;
    feedLoadCount = 0;
  }
}

class FakeYouTubeHelper extends YouTubeHelper {
  FakeYouTubeHelper(super.db);

  @override
  Future<String?> getAudioUrl(String videoId) async {
    return 'https://example.test/audio/$videoId';
  }

  @override
  Future<MediaItem> createMediaItem(
    String videoId, {
    String? customTitle,
    String? customArtist,
    Duration? customDuration,
    String? customThumbnail,
    Map<String, dynamic>? extras,
    String? cachedUrl,
  }) async {
    final title = customTitle ?? 'Test Title';
    final artist = customArtist ?? 'Test Artist';
    final duration = customDuration ?? const Duration(seconds: 180);
    final artUri = Uri.parse(customThumbnail ?? '');

    return MediaItem(
      id: videoId,
      album: artist,
      title: title,
      artist: artist,
      duration: duration,
      artUri: artUri.toString().isEmpty ? null : artUri,
      extras: {
        'isOnline': true,
        'videoId': videoId,
        'user_agent': 'TestUA',
        if (cachedUrl != null) 'cachedUrl': cachedUrl,
        ...?extras,
      },
    );
  }
}

class FakeCacheService extends CacheService {
  final Map<String, YouTubeTrack> _cached = {};
  // ignore: unused_field - kept for future test scenarios
  int _maxSize = 500 * 1024 * 1024;

  // Simulate download progress for testing
  bool simulateSlowDownload = false;
  Duration downloadDelay = const Duration(milliseconds: 100);

  // For testing failure scenarios
  bool simulateCacheFailure = false;
  bool simulateNoSpace = false;

  FakeCacheService({required super.db, super.settingsService});

  @override
  Future<void> init() async {}

  @override
  Future<void> setMaxCacheSize(int bytes) async {
    _maxSize = bytes;
  }

  @override
  Future<bool> isCached(String videoId) async {
    return _cached.containsKey(videoId);
  }

  @override
  Future<String?> getCachedFilePath(String videoId) async {
    return _cached[videoId]?.downloadPath;
  }

  @override
  Future<void> cacheTrack({
    required String videoId,
    required String url,
    required String title,
    required String artist,
    required String thumbnailUrl,
    String? container, // webm or mp4
  }) async {
    if (simulateCacheFailure) {
      throw Exception('Simulated cache failure');
    }

    if (simulateSlowDownload) {
      await Future<void>.delayed(downloadDelay);
    }

    TestTracker.recordCache(videoId);

    final extension = (container?.toLowerCase() == 'webm') ? 'webm' : 'm4a';
    final db = GetIt.I<AppDatabase>();
    final track = YouTubeTrack(
      videoId: videoId,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      duration: 0,
      downloadPath: 'cache://$videoId.$extension',
      fileSize: 1024 * 1024,
      lastPlayed: null,
      cachedAt: DateTime.now(),
      isFavorite: false,
      likedAt: null,
      pendingCache: false,
    );

    _cached[videoId] = track;
    await db.into(db.youTubeTracks).insertOnConflictUpdate(
          YouTubeTracksCompanion.insert(
            videoId: videoId,
            title: title,
            artist: artist,
            thumbnailUrl: thumbnailUrl,
            duration: 0,
            cachedAt: DateTime.now(),
            fileSize: Value(track.fileSize),
            downloadPath: Value(track.downloadPath),
          ),
        );
  }

  @override
  Future<void> checkCacheSpace(int newFileSize) async {}

  @override
  Future<bool> hasSufficientSpace(int estimatedSize) async {
    return !simulateNoSpace;
  }

  @override
  Future<void> updateLastPlayed(String videoId) async {}

  @override
  Future<void> clearCache() async {
    _cached.clear();
  }

  @override
  Future<int> getCacheUsage() async {
    return _cached.values
        .fold<int>(0, (sum, t) => sum + (t.fileSize ?? 1024 * 1024));
  }

  @override
  Future<Directory> getCacheDirectory() async {
    return getTemporaryDirectory();
  }

  @override
  Future<List<YouTubeTrack>> getCachedTracks() async {
    return _cached.values.toList();
  }

  @override
  Future<void> deleteCachedTrack(String videoId) async {
    _cached.remove(videoId);
  }

  /// Get all cached video IDs for verification
  List<String> get cachedIds => _cached.keys.toList();

  /// Reset for new test
  void reset() {
    _cached.clear();
    simulateSlowDownload = false;
    simulateCacheFailure = false;
    simulateNoSpace = false;
  }
}

class FakeMusicFinder extends MusicFinder {
  final AppDatabase _db;

  // Track scan count for testing
  static int scanCount = 0;

  // Customizable test tracks
  static List<TracksCompanion>? customTracks;

  FakeMusicFinder(this._db) : super(_db);

  @override
  Future<void> scanAllMusic() async {
    if (isScanning.value) return;
    isScanning.value = true;
    scanStatus.value = 'Scanning Library...';
    scanCount++;

    final tracks = customTracks ??
        [
          TracksCompanion.insert(
            path: 'local:test_song.mp3',
            title: 'Local Test Song',
            artist: const Value('Local Artist'),
            album: const Value('Local Album'),
            duration: 160000,
            folderPath: 'local',
            mediaStoreId: const Value(1),
          ),
          TracksCompanion.insert(
            path: 'local:test_song_2.mp3',
            title: 'Local Test Song 2',
            artist: const Value('Local Artist'),
            album: const Value('Local Album'),
            duration: 180000,
            folderPath: 'local',
            mediaStoreId: const Value(2),
          ),
          TracksCompanion.insert(
            path: 'local:rock_track.mp3',
            title: 'Local Rock Track',
            artist: const Value('Rock Artist'),
            album: const Value('Rock Album'),
            duration: 240000,
            folderPath: 'local/rock',
            mediaStoreId: const Value(3),
          ),
          TracksCompanion.insert(
            path: 'local:electronic_beat.mp3',
            title: 'Electronic Beat',
            artist: const Value('Electronic Artist'),
            album: const Value('Beats Collection'),
            duration: 300000,
            folderPath: 'local/electronic',
            mediaStoreId: const Value(4),
          ),
        ];

    for (final track in tracks) {
      await _db.into(_db.tracks).insertOnConflictUpdate(track);
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));
    isScanning.value = false;
    scanStatus.value = '';
  }

  @override
  Future<bool> checkPermission() async {
    return true;
  }

  static void reset() {
    scanCount = 0;
    customTracks = null;
  }
}

/// Test utilities for integration tests
class TestUtils {
  /// Reset all fake services for a clean test
  static void resetAll() {
    TestTracker.reset();
    FakeRecommendationService.reset();
    FakeMusicFinder.reset();
  }

  /// Verify a specific number of tracks were played
  static bool verifyPlayCount(int expected) {
    return TestTracker.playCount == expected;
  }

  /// Verify a specific video was played
  static bool verifyPlayed(String videoId) {
    return TestTracker.playedVideoIds.contains(videoId);
  }

  /// Verify a search was performed
  static bool verifySearchPerformed(String query) {
    return TestTracker.searchQueries.contains(query);
  }

  /// Verify a track was cached
  static bool verifyCached(String videoId) {
    return TestTracker.cachedVideoIds.contains(videoId);
  }

  /// Verify artist navigation occurred
  static bool verifyArtistNavigated(String artistId) {
    return TestTracker.navigatedArtists.contains(artistId);
  }
}
