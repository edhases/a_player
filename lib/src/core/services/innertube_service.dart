import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/youtube_song.dart';
import 'google_auth_service.dart';
import 'rate_limiter.dart';
import 'package:logger/logger.dart';
import '../utils/result.dart';

import '../../data/datasources/app_database.dart';

class InnerTubeService {
  final Dio _dio;
  final GoogleAuthService _googleAuthService;
  final RateLimiter _rateLimiter = RateLimiter();
  final AppDatabase _db;
  final _logger = Logger(
    printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 50,
        colors: true,
        printEmojis: true,
        printTime: false),
  );

  String? _visitorId;

  // User agents for different clients
  // IMPORTANT: For /browse, use browser-style UAs. YouTube Music app UA is only for /player.
  static const String _webUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const String _androidUserAgent =
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36';
  static const String _tvUserAgent =
      'Mozilla/5.0 (X11; CrOS x86_64 15136.72.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.6045.90 Safari/537.36';

  InnerTubeService({GoogleAuthService? googleAuthService, AppDatabase? db})
      : _googleAuthService = googleAuthService ?? GetIt.I<GoogleAuthService>(),
        _db = db ?? GetIt.I<AppDatabase>(),
        _dio = Dio(BaseOptions(
          baseUrl: 'https://music.youtube.com/youtubei/v1',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Referer': 'https://music.youtube.com/',
            'Content-Type': 'application/json',
            'X-Goog-AuthUser': '0',
            'Origin': 'https://music.youtube.com',
          },
        )) {
    _initializeVisitorId();
    // Add debug logging to see exact request details
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: false, // Keep response body off to avoid clutter
      requestHeader: true,
      error: true,
      logPrint: (obj) => debugPrint('[DIO] $obj'),
    ));
  }

  void _initializeVisitorId() {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final suffix =
        List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    _visitorId = 'CAIS$suffix';
    debugPrint('[InnerTubeService] Generated Visitor ID: $_visitorId');
  }

  /// Universal POST request method with automatic auth header and User-Agent selection
  Future<Map<String, dynamic>> _postRequest(
      String endpoint, Map<String, dynamic> body,
      {bool useAuth = true, String? customUserAgent}) async {
    await _rateLimiter.throttle();

    if (useAuth) {
      await _addAuthHeaders();
    }

    // Add Visitor ID header
    if (_visitorId != null) {
      _dio.options.headers['X-Goog-Visitor-Id'] = _visitorId!;
    }

    // Select User-Agent based on client context if not provided
    String userAgent = customUserAgent ?? _webUserAgent;
    if (customUserAgent == null && body.containsKey('context')) {
      final clientName = body['context']?['client']?['clientName'];
      switch (clientName) {
        case 'WEB_REMIX':
          userAgent = _webUserAgent;
          break;
        case 'ANDROID_MUSIC':
          userAgent = _androidUserAgent;
          break;
        case 'TVHTML5':
          userAgent = _tvUserAgent;
          break;
      }
    }
    _dio.options.headers['User-Agent'] = userAgent;

    try {
      final response = await _dio.post(endpoint, data: body);
      return response.data;
    } catch (e) {
      debugPrint('InnerTube API $endpoint Error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _webContextBody() {
    return {
      "context": {
        "client": {
          "clientName": "WEB_REMIX",
          "clientVersion": "1.20241111.01.00",
          "hl": "en",
          "gl": "US",
          "browserName": "Chrome",
          "browserVersion": "120.0.0.0",
          "screenWidthPoints": 1920,
          "screenHeightPoints": 1080,
          "screenPixelDensity": 1,
          "platform": "DESKTOP"
        }
      }
    };
  }

  Map<String, dynamic> _androidContextBody() {
    return {
      "context": {
        "client": {
          "clientName": "ANDROID_MUSIC",
          "clientVersion": "7.02.51",
          "hl": "en",
          "gl": "US",
          "androidSdkVersion": 33
        }
      }
    };
  }

  Future<Result<List<YouTubeSong>>> search(String query) async {
    await _rateLimiter.throttle();
    await _addAuthHeaders();

    final body = _webContextBody();
    body['query'] = query;
    body['params'] = "EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D";

    try {
      final response = await _dio.post('/search', data: body);
      final results = _parseSearchResults(response.data);
      return Result.success(results);
    } catch (e) {
      _logger.e('InnerTube Search Error', error: e);
      return Result.failure(e.toString());
    }
  }

  /// Returns {'url': string, 'agent': string} on success, null on failure.
  Future<Map<String, String>?> getSongUrl(String videoId) async {
    await _rateLimiter.throttle();
    await _addAuthHeaders();

    // Multi-client strategy for maximum reliability
    final results = await _waitForFirstSuccess<Map<String, String>>([
      _tryAndroidMusic(videoId),
      _tryTVHTML5(videoId),
    ]);

    return results;
  }

  Future<Map<String, String>?> _tryAndroidMusic(String videoId) async {
    const String mobileAgent =
        'com.google.android.apps.youtube.music/6.33.51 (Linux; U; Android 11; US) gzip';
    try {
      debugPrint('[InnerTube] Trying ANDROID_MUSIC for: $videoId');
      final url = await _getStreamUrl(
        videoId,
        _androidContextBody(),
        options: Options(headers: {'User-Agent': mobileAgent}),
      );
      if (url != null) return {'url': url, 'agent': mobileAgent};
    } catch (e) {
      debugPrint('[InnerTube] ANDROID_MUSIC error: $e');
    }
    return null;
  }

  Future<Map<String, String>?> _tryTVHTML5(String videoId) async {
    const String tvAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36';
    try {
      debugPrint('[InnerTube] Trying TVHTML5 for: $videoId');
      final url = await _getStreamUrl(
        videoId,
        _tvHtml5ContextBody(),
        options: Options(headers: {'User-Agent': tvAgent}),
      );
      if (url != null) return {'url': url, 'agent': tvAgent};
    } catch (e) {
      debugPrint('[InnerTube] TVHTML5 error: $e');
    }
    return null;
  }

  Map<String, dynamic> _tvHtml5ContextBody() {
    return {
      "context": {
        "client": {
          "clientName": "TVHTML5",
          "clientVersion": "7.20230405.08.01",
          "hl": "en",
          "gl": "US",
        }
      }
    };
  }

  // Returns the first non-null result from a list of futures
  Future<T?> _waitForFirstSuccess<T>(List<Future<T?>> futures) async {
    final completer = Completer<T?>();
    int completedCount = 0;

    for (final future in futures) {
      future.then((result) {
        if (!completer.isCompleted && result != null) {
          completer.complete(result);
        }
      }).catchError((e) {
        // Ignore errors
      }).whenComplete(() {
        completedCount++;
        if (completedCount == futures.length && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }
    return completer.future;
  }

  Future<String?> _getStreamUrl(
      String videoId, Map<String, dynamic> contextBody,
      {Options? options}) async {
    contextBody['videoId'] = videoId;
    contextBody['playbackContext'] = {
      'contentPlaybackContext': {
        'signatureTimestamp': 20380 // Updated for 2024+
      }
    };

    try {
      final response =
          await _dio.post('/player', data: contextBody, options: options);

      final playabilityStatus = response.data['playabilityStatus'];
      if (playabilityStatus != null && playabilityStatus['status'] != 'OK') {
        debugPrint(
            '[InnerTube] Playability Status: ${playabilityStatus['status']} for $videoId');
        return null;
      }

      final streamingData = response.data['streamingData'];
      if (streamingData == null) return null;

      if (streamingData['adaptiveFormats'] != null) {
        final formats = streamingData['adaptiveFormats'] as List;

        final audioFormats = formats.where((f) {
          final mime = f['mimeType'].toString();
          return mime.contains('audio');
        }).toList();

        if (audioFormats.isEmpty) return null;

        // Sort by bitrate desc
        audioFormats.sort((a, b) {
          final bitA = a['bitrate'] as int? ?? 0;
          final bitB = b['bitrate'] as int? ?? 0;
          return bitB.compareTo(bitA);
        });

        final bestFormat = audioFormats.first;
        if (bestFormat['url'] != null) {
          return bestFormat['url'];
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  Future<Map<String, String>> _addAuthHeaders() async {
    // Get all auth headers from the auth service
    final authHeaders = await _googleAuthService.getAuthHeaders();

    if (authHeaders.containsKey('Cookie')) {
      debugPrint('[InnerTube] Auth: Active session headers applying...');

      // Add ALL headers (Cookie, Authorization, User-Agent, etc.)
      _dio.options.headers.addAll(authHeaders);

      // Ensure Origin is in place (important for SAPISIDHASH)
      _dio.options.headers['Origin'] = 'https://music.youtube.com';
    } else {
      debugPrint(
          '[InnerTube] Auth: No active session. Personalization disabled.');
      _dio.options.headers.remove('Cookie');
      _dio.options.headers.remove('Authorization');
    }

    // Return only the headers we just added to maintain the method signature
    final result = <String, String>{};
    for (final key in authHeaders.keys) {
      if (_dio.options.headers[key] is String) {
        result[key] = _dio.options.headers[key];
      }
    }
    return result;
  }

  Future<void> logout() async {
    debugPrint('[InnerTube] Performing logout (clearing cookies)');
    await _googleAuthService.signOut();
    _dio.options.headers.remove('Cookie');
  }

  List<YouTubeSong> _parseSearchResults(Map<String, dynamic> data) {
    final results = <YouTubeSong>[];

    try {
      var contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs']
          ?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];

      if (contents == null) {
        contents = data['contents']?['sectionListRenderer']?['contents'];
      }

      if (contents == null) {
        contents = data['contents']?['singleColumnSearchResultsRenderer']
                ?['tabs']?[0]?['tabRenderer']?['content']
            ?['sectionListRenderer']?['contents'];
      }

      if (contents == null || contents is! List) {
        return [];
      }

      for (final section in contents) {
        final musicShelf = section['musicShelfRenderer'];
        if (musicShelf != null) {
          final items = musicShelf['contents'];
          if (items is List) {
            for (final item in items) {
              final mrlir = item['musicResponsiveListItemRenderer'];
              if (mrlir != null) {
                try {
                  final title = mrlir['flexColumns'][0]
                          ['musicResponsiveListItemFlexColumnRenderer']['text']
                      ['runs'][0]['text'] as String;

                  final secondaryText = mrlir['flexColumns'][1]
                          ['musicResponsiveListItemFlexColumnRenderer']['text']
                      ['runs'] as List;
                  String artist = "Unknown";
                  if (secondaryText.isNotEmpty) {
                    for (var run in secondaryText) {
                      final text = run['text'];
                      if (text != ' • ' &&
                          !text.contains('views') &&
                          !text.contains('plays') &&
                          !text.contains(':')) {
                        artist = text;
                        break;
                      }
                    }
                  }

                  String? videoId;
                  final playButton = mrlir['overlay']
                          ?['musicItemThumbnailOverlayRenderer']?['content']
                      ?['musicPlayButtonRenderer'];
                  videoId = playButton?['playNavigationEndpoint']
                      ?['watchEndpoint']?['videoId'];

                  final playlistItemData = mrlir['playlistItemData'];
                  if (videoId == null &&
                      playlistItemData != null &&
                      playlistItemData['videoId'] != null) {
                    videoId = playlistItemData['videoId'];
                  }

                  if (videoId == null) {
                    videoId =
                        mrlir['navigationItem']?['watchEndpoint']?['videoId'];
                  }

                  final thumbnails = mrlir['thumbnail']
                          ?['musicThumbnailRenderer']?['thumbnail']
                      ?['thumbnails'] as List?;
                  String thumbUrl = '';
                  if (thumbnails != null && thumbnails.isNotEmpty) {
                    thumbUrl = thumbnails.last['url'];
                  }

                  if (videoId != null) {
                    results.add(YouTubeSong(
                      videoId: videoId,
                      title: title,
                      artist: artist,
                      thumbnailUrl: thumbUrl,
                    ));
                  }
                } catch (e) {}
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Parsing Error: $e');
    }
    return results;
  }

  Future<bool> isLoggedIn() async {
    final cookies = await _googleAuthService.getCookies();
    if (cookies != null && cookies.isNotEmpty) {
      return true;
    }
    // Also check if user is logged in via GoogleAuthService
    return _googleAuthService.isSignedIn();
  }

  Future<Result<List<Map<String, dynamic>>>> getHomeData() async {
    try {
      // Check if user is logged in to determine whether to bypass cache
      bool isLoggedIn = await _googleAuthService.isSignedIn();

      // If logged in, bypass cache to get personalized recommendations
      HomeCacheEntry? cachedEntry;
      if (!isLoggedIn) {
        cachedEntry = await _db.getCachedHomeData();
      }

      if (cachedEntry != null && !isLoggedIn) {
        _logger.i('[InnerTubeService] Using cached home data.');
        try {
          final cachedJson = json.decode(cachedEntry.data);
          if (cachedJson is List) {
            return Result.success(cachedJson.cast<Map<String, dynamic>>());
          }
        } catch (e) {
          _logger.w('Failed to decode cached home data', error: e);
        }
      }

      _logger.i(
          '[InnerTubeService] Fetching fresh home data (cache bypassed for logged-in user).');

      // Use ANDROID_MUSIC context like the legacy implementation
      final body = _androidContextBody();
      body['browseId'] = "FEmusic_home";

      final response = await _postRequest('/browse', body);

      final freshData = _parseHomeData(response);
      if (freshData.isNotEmpty) {
        // Cache the fresh data as sections
        await _db.cacheHomeData(json.encode(freshData));
        return Result.success(freshData);
      } else {
        _logger.w(
            '[InnerTube] ANDROID_MUSIC returned empty home data. Trying WEB_REMIX...');
        return await _getHomeDataWebFallback();
      }
    } catch (e) {
      _logger.e('InnerTube getHomeData Error (ANDROID_MUSIC)', error: e);
      _logger.i('[InnerTube] Trying WEB_REMIX fallback after error...');
      return await _getHomeDataWebFallback();
    }
  }

  Future<Result<List<Map<String, dynamic>>>> _getHomeDataWebFallback() async {
    try {
      final body = _webContextBody();
      body['browseId'] = "FEmusic_home";

      final response = await _postRequest('/browse', body);
      final freshData = _parseHomeData(response);

      if (freshData.isNotEmpty) {
        await _db.cacheHomeData(json.encode(freshData));
        return Result.success(freshData);
      }
      return Result.failure(
          'No home data found (both ANDROID_MUSIC and WEB_REMIX failed)');
    } catch (e) {
      _logger.e('InnerTube getHomeData Error (WEB_REMIX Fallback)', error: e);
      return Result.failure(e.toString());
    }
  }

  List<Map<String, dynamic>> _parseHomeData(Map<String, dynamic> data) {
    final sections = <Map<String, dynamic>>[];
    try {
      dynamic contents;

      // Path 1: Single Column (Common for Mobile/Web Remix)
      contents = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']
          ?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];

      // Path 2: Two Column (Desktop structure)
      if (contents == null) {
        contents = data['contents']?['twoColumnBrowseResultsRenderer']?['tabs']
                ?[0]?['tabRenderer']?['content']?['sectionListRenderer']
            ?['contents'];
      }

      // Path 3: Direct Section List (Rare but possible)
      if (contents == null) {
        contents = data['contents']?['sectionListRenderer']?['contents'];
      }

      if (contents == null || contents is! List) {
        debugPrint(
            '[InnerTube] _parseHomeData: Could not find sectionListRenderer contents. Keys: ${data['contents']?.keys}');
        return [];
      }

      for (var section in contents) {
        // Handle multiple shelf types including musicImmersiveCarouselShelfRenderer
        final shelf = section['musicShelfRenderer'] ??
            section['musicCarouselShelfRenderer'] ??
            section['musicImmersiveCarouselShelfRenderer'] ??
            section['gridRenderer'] ??
            section['musicVisualHeaderRenderer'];

        if (shelf == null) {
          // Try to extract from itemSectionRenderer (common wrapper)
          final itemSection = section['itemSectionRenderer'];
          if (itemSection != null) {
            final innerContents = itemSection['contents'] as List?;
            if (innerContents != null) {
              for (var innerItem in innerContents) {
                final innerShelf = innerItem['musicShelfRenderer'] ??
                    innerItem['musicCarouselShelfRenderer'] ??
                    innerItem['musicImmersiveCarouselShelfRenderer'];
                if (innerShelf != null) {
                  _processShelf(innerShelf, sections);
                }
              }
            }
          }
          continue;
        }

        _processShelf(shelf, sections);
      }
    } catch (e) {
      debugPrint('Error parsing home data: $e');
    }
    debugPrint('[InnerTube] _parseHomeData: Found ${sections.length} sections');
    return sections;
  }

  void _processShelf(
      Map<String, dynamic> shelf, List<Map<String, dynamic>> sections) {
    String title = "Recommended";
    final titleRuns = shelf['title']?['runs'] as List?;
    final headerRuns = shelf['header']?['musicCarouselShelfBasicHeaderRenderer']
        ?['title']?['runs'] as List?;
    final straplineRuns = shelf['straplineTextOne']?['runs'] as List?;

    if (titleRuns != null && titleRuns.isNotEmpty) {
      title = titleRuns[0]['text'];
    } else if (headerRuns != null && headerRuns.isNotEmpty) {
      title = headerRuns[0]['text'];
    } else if (straplineRuns != null && straplineRuns.isNotEmpty) {
      title = straplineRuns[0]['text'];
    }

    final items = <YouTubeSong>[];
    final shelfContents = shelf['contents'] ?? shelf['items'];
    if (shelfContents is List) {
      for (var item in shelfContents) {
        final mrlir = item['musicResponsiveListItemRenderer'] ??
            item['musicTwoColumnItemRenderer'] ??
            item['musicTwoRowItemRenderer'] ??
            item['musicMultiRowListItemRenderer'] ??
            item['musicNavigationButtonRenderer'];
        if (mrlir != null) {
          final song = _parseSingleSong(mrlir);
          if (song != null) items.add(song);
        }
      }
    }

    if (items.isNotEmpty) {
      sections.add({
        'title': title,
        'items': items,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getLibraryPlaylists() async {
    await _rateLimiter.throttle();
    await _addAuthHeaders();
    final body = _webContextBody();
    body['browseId'] = "FEmusic_library_landing";

    try {
      final response = await _dio.post('/browse', data: body);
      return _parseLibraryPlaylists(response.data);
    } catch (e) {
      debugPrint('InnerTube getLibraryPlaylists Error: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _parseLibraryPlaylists(Map<String, dynamic> data) {
    final playlists = <Map<String, dynamic>>[];
    try {
      final sections = data['contents']?['singleColumnBrowseResultsRenderer']
              ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']
          ?['contents'];

      if (sections == null || sections is! List) return [];

      for (var section in sections) {
        final grid =
            section['musicCarouselShelfRenderer'] ?? section['gridRenderer'];
        if (grid == null) continue;

        final items = grid['items'] as List?;
        if (items != null) {
          for (var item in items) {
            final renderer = item['musicTwoColumnItemRenderer'] ??
                item['musicResponsiveListItemRenderer'];
            if (renderer != null) {
              final title = renderer['title']?['runs']?[0]?['text'];
              final browseId = renderer['navigationEndpoint']?['browseEndpoint']
                  ?['browseId'];
              final type = renderer['navigationEndpoint']?['browseEndpoint']
                      ?['browseEndpointContextSupportedConfigs']
                  ?['browseEndpointContextMusicConfig']?['pageType'];

              if (title != null &&
                  browseId != null &&
                  type == 'MUSIC_PAGE_TYPE_PLAYLIST') {
                final thumbnails = (renderer['thumbnailRenderer'] ??
                        renderer['thumbnail'])?['musicThumbnailRenderer']
                    ?['thumbnail']?['thumbnails'] as List?;
                playlists.add({
                  'title': title,
                  'playlistId': browseId,
                  'thumbnail': thumbnails?.last['url'] ?? '',
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing library playlists: $e');
    }
    return playlists;
  }

  Future<List<YouTubeSong>> getPlaylistTracks(String playlistId) async {
    await _rateLimiter.throttle();
    await _addAuthHeaders();
    final body = _webContextBody();
    body['browseId'] = playlistId;

    try {
      final response = await _dio.post('/browse', data: body);
      return _parsePlaylistTracks(response.data);
    } catch (e) {
      debugPrint('InnerTube getPlaylistTracks Error: $e');
      return [];
    }
  }

  List<YouTubeSong> _parsePlaylistTracks(Map<String, dynamic> data) {
    final tracks = <YouTubeSong>[];
    try {
      final contents = data['contents']?['singleColumnBrowseResultsRenderer']
              ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']
          ?['contents']?[0]?['musicPlaylistShelfRenderer']?['contents'];

      if (contents == null || contents is! List) return [];

      for (var item in contents) {
        final mrlir = item['musicResponsiveListItemRenderer'];
        if (mrlir != null) {
          final song = _parseSingleSong(mrlir);
          if (song != null) tracks.add(song);
        }
      }
    } catch (e) {
      debugPrint('Error parsing playlist tracks: $e');
    }
    return tracks;
  }

  YouTubeSong? _parseSingleSong(Map<String, dynamic> mrlir) {
    try {
      // Try multiple title extraction paths
      String? title = mrlir['flexColumns']?[0]
              ?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']
          ?[0]?['text'];

      // Title from musicTwoRowItemRenderer/musicTwoColumnItemRenderer
      title ??= mrlir['title']?['runs']?[0]?['text'];

      // Title from navigationEndpoint context
      title ??=
          mrlir['navigationEndpoint']?['watchEndpoint']?['videoId'] != null
              ? 'Unknown Title'
              : null;

      if (title == null) return null;

      // Extract artist with multiple fallbacks
      String artist = "Unknown";
      final flexCol1 = mrlir['flexColumns']?[1]
          ?['musicResponsiveListItemFlexColumnRenderer'];
      if (flexCol1 != null) {
        final runs = flexCol1['text']?['runs'] as List?;
        if (runs != null && runs.isNotEmpty) {
          // Find the first run that's not a separator or type label
          artist = _extractArtistFromRuns(runs);
        }
      } else {
        // Try subtitle for musicTwoRowItemRenderer
        final subtitleRuns = mrlir['subtitle']?['runs'] as List?;
        if (subtitleRuns != null && subtitleRuns.isNotEmpty) {
          artist = _extractArtistFromRuns(subtitleRuns);
        }
      }

      // Extract videoId with multiple paths
      String? videoId;

      // Path 1: Overlay play button
      final playButton = mrlir['overlay']?['musicItemThumbnailOverlayRenderer']
          ?['content']?['musicPlayButtonRenderer'];
      videoId =
          playButton?['playNavigationEndpoint']?['watchEndpoint']?['videoId'];

      // Path 2: Direct navigationEndpoint
      videoId ??= mrlir['navigationEndpoint']?['watchEndpoint']?['videoId'];

      // Path 3: onTap
      videoId ??= mrlir['onTap']?['watchEndpoint']?['videoId'];

      // Path 4: playlistItemData
      videoId ??= mrlir['playlistItemData']?['videoId'];

      if (videoId == null) return null;

      // Extract thumbnail with multiple paths
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
      debugPrint('[InnerTube] _parseSingleSong error: $e');
      return null;
    }
  }

  /// Extract artist from runs, skipping type labels like "Song", "Video", separators
  String _extractArtistFromRuns(List runs) {
    // Type labels to skip
    const skipLabels = [
      'Song',
      'Video',
      'Пісня',
      'Відео',
      'EP',
      'Album',
      'Альбом',
      'Single',
      ' • ',
      '•'
    ];

    for (var run in runs) {
      final text = run['text']?.toString() ?? '';
      // Skip empty, separators, and type labels
      if (text.isEmpty) continue;
      if (text.trim() == '•' || text.trim() == ' • ') continue;
      if (skipLabels.contains(text.trim())) continue;
      // Skip view counts and time indicators
      if (text.contains('views') ||
          text.contains('plays') ||
          text.contains(':')) continue;
      if (RegExp(r'^\d+[KMB]?\s*(views|plays)?$', caseSensitive: false)
          .hasMatch(text)) continue;

      return text;
    }
    return "Unknown";
  }
}
