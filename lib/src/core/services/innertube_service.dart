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
import '../utils/json_path.dart';
import '../exceptions/youtube_exceptions.dart';
import 'settings_service.dart';
import 'youtube_helper.dart';

import '../../data/datasources/app_database.dart';

class InnerTubeService {
  final Dio _dio;
  final GoogleAuthService _googleAuthService;
  final RateLimiter _rateLimiter = RateLimiter();
  final AppDatabase _db;
  final SettingsService _settingsService;
  final _logger = Logger(
    printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 50,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.none),
  );

  String? _visitorId;

  // User agents for different clients
  // IMPORTANT: For /browse, use browser-style UAs. YouTube Music app UA is only for /player.
  static const String _webUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36';
  static const String _androidUserAgent =
      'Mozilla/5.0 (Linux; Android 14; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36';
  static const String _tvUserAgent =
      'Mozilla/5.0 (X11; CrOS x86_64 15136.72.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.6045.90 Safari/537.36';

  InnerTubeService(
      {GoogleAuthService? googleAuthService,
      AppDatabase? db,
      required SettingsService settingsService})
      : _googleAuthService = googleAuthService ?? GetIt.I<GoogleAuthService>(),
        _db = db ?? GetIt.I<AppDatabase>(),
        _settingsService = settingsService,
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
      requestHeader: false, // Turn off headers to avoid Cookie spam
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
    } on DioException catch (e) {
      // Convert Dio exceptions to typed exceptions
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException(
          'Connection timeout to YouTube',
          isTimeout: true,
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException('No internet connection');
      }
      if (e.response?.statusCode == 429) {
        throw const RateLimitException('YouTube rate limit exceeded');
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw const AuthenticationException('YouTube authentication failed');
      }
      debugPrint('InnerTube API $endpoint Error: $e');
      rethrow;
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
          "hl": _settingsService.loadString('language_code') ?? "en",
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

  Map<String, dynamic> _androidContextBody({bool isPlayer = false}) {
    return {
      "context": {
        "client": {
          "clientName": "ANDROID_MUSIC",
          "clientVersion": "9.02.50",
          "hl": _settingsService.loadString('language_code') ?? "en",
          "gl": "US",
          "androidSdkVersion": 33
        }
      },
      "playbackContext": {
        "contentPlaybackContext": {"signatureTimestamp": 20470}
      }
    };
  }

  Future<Result<List<YouTubeSong>>> search(String query) async {
    await _rateLimiter.throttle();
    await _addAuthHeaders();

    // Strategy 1: Try specific "Songs" filter with ANDROID_MUSIC (Primary)
    try {
      final body = _androidContextBody();
      body['query'] = query;
      body['params'] = "EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D";

      final response = await _dio.post('/search', data: body);
      final results = _parseSearchResults(response.data);

      if (results.isNotEmpty) {
        return Result.success(results);
      }
      // debugPrint('[InnerTube] Android Music search with filter returned empty. Trying fallback...');
    } catch (e) {
      // Ignored: Expected fallback behavior for some contexts
      // debugPrint('[InnerTube] Android Music filter search failed: $e. Trying fallback...');
    }

    // Strategy 2: Fallback to broad search (Top Results) with ANDROID_MUSIC
    try {
      final body = _androidContextBody();
      body['query'] = query;
      // No params = mixed results

      final response = await _dio.post('/search', data: body);
      final results = _parseSearchResults(response.data);
      if (results.isNotEmpty) {
        return Result.success(results);
      }
    } catch (e) {
      debugPrint('[InnerTube] Android Music broad search failed: $e');
    }

    // Strategy 3: Last Resort - WEB_REMIX
    try {
      debugPrint('[InnerTube] Trying WEB_REMIX as last resort...');
      final body = _webContextBody();
      body['query'] = query;
      final response = await _dio.post('/search', data: body);
      final results = _parseSearchResults(response.data);
      if (results.isNotEmpty) return Result.success(results);
    } catch (e) {
      debugPrint('[InnerTube] WEB_REMIX failed: $e');
    }

    // Strategy 4: Anonymous Fallback (Remove Cookies and try again)
    // This fixes issues where bad/expired cookies cause empty results.
    if (_dio.options.headers.containsKey('Cookie')) {
      debugPrint(
          '[InnerTube] All auth searches failed. Trying Anonymous search...');
      _dio.options.headers.remove('Cookie');
      _dio.options.headers.remove('Authorization');

      try {
        final body = _androidContextBody();
        body['query'] = query;
        final response = await _dio.post('/search', data: body);
        final results = _parseSearchResults(response.data);
        return Result.success(results);
      } catch (e) {
        _logger.e('InnerTube Anonymous Fallback Error', error: e);
        return Result.failure(e.toString());
      }
    }

    return Result.failure("No results found after all attempts");
  }

  /// Returns {'url': string, 'agent': string} on success, null on failure.
  ///
  /// Delegates to [YouTubeHelper.getAudioUrlWithAgent] which uses
  /// `youtube_explode_dart` with ANDROID_VR client for reliable streaming.
  /// This handles signature cipher decryption, PO Token, and other
  /// YouTube anti-bot measures automatically.
  Future<Map<String, String>?> getSongUrl(String videoId) async {
    await _rateLimiter.throttle();

    // Delegate to YouTubeHelper which uses youtube_explode_dart
    // This handles signature cipher, ANDROID_VR client, and PO Token
    try {
      final youtubeHelper = GetIt.I<YouTubeHelper>();
      final result = await youtubeHelper.getAudioUrlWithAgent(videoId);
      if (result != null) {
        debugPrint(
            '[InnerTube] Stream URL obtained via YouTubeHelper for: $videoId');
        return result;
      }
    } catch (e) {
      debugPrint('[InnerTube] YouTubeHelper delegation failed: $e');
    }

    // Fallback to legacy InnerTube method (for edge cases)
    debugPrint(
        '[InnerTube] Falling back to legacy stream resolution for: $videoId');
    await _addAuthHeaders();
    final results = await _waitForFirstSuccess<Map<String, String>>([
      _tryAndroidMusic(videoId),
      _tryTVHTML5(videoId),
    ]);

    return results;
  }

  Future<Map<String, String>?> _tryAndroidMusic(String videoId) async {
    const String mobileAgent =
        'com.google.android.apps.youtube.music/9.02.50 (Linux; U; Android 14; US) gzip';
    try {
      debugPrint('[InnerTube] Trying ANDROID_MUSIC for: $videoId');
      final url = await _getStreamUrl(
        videoId,
        _androidContextBody(isPlayer: true), // Use specific context for player
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
        'signatureTimestamp': 20470 // Updated for Jan 2026
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
      debugPrint('[InnerTube] Parsing Search Results...');
      // Debug the top-level keys
      // debugPrint('[InnerTube] Keys: ${data.keys.toList()}');

      var contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs']
          ?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];

      if (contents == null) {
        debugPrint('[InnerTube] Path 1 failed.');
        contents = data['contents']?['sectionListRenderer']?['contents'];
      }

      if (contents == null) {
        debugPrint('[InnerTube] Path 2 failed.');
        // Path 3: Single Column (Mobile/Tablet)
        contents = data['contents']?['singleColumnSearchResultsRenderer']
                ?['tabs']?[0]?['tabRenderer']?['content']
            ?['sectionListRenderer']?['contents'];
      }

      if (contents == null) {
        debugPrint('[InnerTube] Path 3 failed.');
        // Path 4: Two Column (Desktop/WEB_REMIX default)
        contents = data['contents']?['twoColumnSearchResultsRenderer']
            ?['primaryContents']?['sectionListRenderer']?['contents'];
      }

      if (contents == null || contents is! List) {
        debugPrint(
            '[InnerTube] All structured paths failed. Falling back to recursive search.');
        // FALLBACK: Recursive Search
        // If structured paths failed, recursively find ALL musicResponsiveListItemRenderer
        // This is a "nuclear option" effective when UI structure changes slightly.
        final items =
            _recursiveFindItems(data, 'musicResponsiveListItemRenderer');

        // Also look for secondary items (desktop/list views)
        final secondaryItems =
            _recursiveFindItems(data, 'musicTwoColumnItemRenderer');
        items.addAll(secondaryItems);

        for (var item in items) {
          final song = _parseSingleSong(item);
          if (song != null) {
            results.add(song);
          }
        }
        return results;
      }

      debugPrint(
          '[InnerTube] Path 1 Success. Found ${contents.length} sections.');

      for (final section in contents) {
        final musicShelf = section['musicShelfRenderer'];
        if (musicShelf != null) {
          debugPrint(
              '[InnerTube] Found musicShelfRenderer. Checking contents...');
          final items = musicShelf['contents'];
          if (items is List) {
            debugPrint('[InnerTube] Shelf has ${items.length} items.');
            for (final item in items) {
              final song = _parseSingleSong(item);
              if (song != null) {
                results.add(song);
              } else {
                debugPrint('[InnerTube] Failed to parse item in shelf.');
              }
            }
          }
        } else if (section['musicCardShelfRenderer'] != null) {
          // Handle Top Result Card (musicCardShelfRenderer)
          debugPrint('[InnerTube] Found musicCardShelfRenderer (Top Result).');
          final cardShelf = section['musicCardShelfRenderer'];
          final song = _parseTopResultCard(cardShelf);
          if (song != null) {
            results.insert(0, song); // Insert at top since it's the best match
          }
        } else {
          debugPrint(
              '[InnerTube] No musicShelfRenderer. Trying recursive fallback for section keys: ${section.keys}');
          // Fallback for sections without explicit musicShelfRenderer
          final items =
              _recursiveFindItems(section, 'musicResponsiveListItemRenderer');
          debugPrint('[InnerTube] Recursive found ${items.length} items.');
          for (final item in items) {
            final song = _parseSingleSong(item);
            if (song != null) {
              results.add(song);
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

  bool _hasFallbackMode = false;

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

      // Optimization: If earlier requests failed with 400, skip directly to fallback
      if (_hasFallbackMode) {
        _logger.w(
            '[InnerTube] Fallback mode active. Skipping ANDROID_MUSIC and going to WEB_REMIX.');
        return await _getHomeDataWebFallback();
      }

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
      // If ANDROID_MUSIC failed, enable fallback mode for future requests
      if (e is DioException && e.response?.statusCode == 400) {
        _hasFallbackMode = true;
        // Downgraded to debug to reduce noise as this is handled behavior
        debugPrint(
            '[InnerTube] ANDROID_MUSIC 400 Error. Fallback mode ENABLED for session.');
        return await _getHomeDataWebFallback();
      }
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

  /// Fetches top/popular tracks from an artist/channel page
  Future<List<YouTubeSong>> _getArtistTopTracks(String artistId) async {
    final body = _webContextBody();
    body['browseId'] = artistId;

    try {
      final response = await _dio.post('/browse', data: body);
      final data = response.data;

      final List<YouTubeSong> tracks = [];
      String artistName = 'Unknown Artist';
      String? continuationToken;

      // Try to get artist name from header
      try {
        final header = data['header']?['musicImmersiveHeaderRenderer'] ??
            data['header']?['musicVisualHeaderRenderer'] ??
            data['header']?['musicDetailHeaderRenderer'];
        if (header != null) {
          artistName = header['title']?['runs']?[0]?['text'] ?? artistName;
        }
      } catch (e) {
        debugPrint('[InnerTube] Could not parse artist header: $e');
      }

      // Navigate to contents - artist page has tabs, we want "Songs" or first shelf
      try {
        final tabs = data['contents']?['singleColumnBrowseResultsRenderer']
            ?['tabs'] as List?;
        if (tabs != null) {
          debugPrint('[InnerTube] Channel has ${tabs.length} tabs.');
          for (var i = 0; i < tabs.length; i++) {
            final title = tabs[i]['tabRenderer']?['title'];
            debugPrint('[InnerTube] Tab $i: $title');
          }
          
          // First, try to find and load the "Songs" tab directly for full list
          // Localized "Songs" tab names: English, Ukrainian, German, Spanish, Japanese, Polish
          const songsTabNames = ['songs', 'пісні', 'titel', 'canciones', '曲', 'utwory', 'músicas', 'chansons', 'brani', '노래'];
          for (final tab in tabs) {
            final tabTitle = tab['tabRenderer']?['title'];
            if (tabTitle != null) {
              final titleLower = tabTitle.toLowerCase();
              if (songsTabNames.contains(titleLower)) {
                final tabEndpoint = tab['tabRenderer']?['endpoint']?['browseEndpoint'];
                if (tabEndpoint != null) {
                  final browseId = tabEndpoint['browseId'];
                  final params = tabEndpoint['params'];
                  if (browseId != null) {
                    debugPrint('[InnerTube] Found "Songs" tab. Fetching full list from $browseId...');
                    final fullList = await _fetchFullTracks(browseId, params: params);
                    if (fullList.isNotEmpty) {
                      debugPrint('[InnerTube] Loaded ${fullList.length} tracks from Songs tab');
                      return fullList;
                    }
                  }
                }
              }
            }
          }
        }

        final contents = data['contents']?['singleColumnBrowseResultsRenderer']
                ?['tabs']?[0]?['tabRenderer']?['content']
            ?['sectionListRenderer']?['contents'];

        if (contents != null) {
          for (final section in contents) {
            // Look for musicShelfRenderer (songs list)
            final shelf = section['musicShelfRenderer'];
            if (shelf != null) {
              final title = shelf['title']?['runs']?[0]?['text'];
              debugPrint('[InnerTube] Found MusicShelf: "$title"');

              // Check for "View All" / "More" button (bottomEndpoint)
              var browseEndpoint = shelf['bottomEndpoint']?['browseEndpoint'];

              // Fallback: Check title navigation (e.g. clickable "Top Songs" header)
              if (browseEndpoint == null) {
                browseEndpoint = shelf['title']?['runs']?[0]
                    ?['navigationEndpoint']?['browseEndpoint'];
              }

              // Scan tabs for "Songs" or "Videos" as a backup if we don't find a direct "See All" link
              // or to ensure we can get the full list.
              if (browseEndpoint == null) {
                final tabs = data['contents']
                    ?['singleColumnBrowseResultsRenderer']?['tabs'] as List?;
                if (tabs != null) {
                  for (final tab in tabs) {
                    final tabTitle = tab['tabRenderer']?['title'];
                    if (tabTitle != null) {
                      final titleLower = tabTitle.toLowerCase();
                      // Check for localized "Songs" or "Videos"
                      if ([
                        'songs',
                        'пісні',
                        'videos',
                        'відео',
                        'uploads',
                        'завантаження'
                      ].contains(titleLower)) {
                        final tabEndpoint =
                            tab['tabRenderer']?['endpoint']?['browseEndpoint'];
                        if (tabEndpoint != null) {
                          debugPrint(
                              '[InnerTube] Found promiseing tab: $tabTitle. Using as "See All" fallback.');
                          browseEndpoint = tabEndpoint;
                          break;
                        }
                      }
                    }
                  }
                }
              }

              if (browseEndpoint != null) {
                final browseId = browseEndpoint['browseId'];
                final params = browseEndpoint['params'];
                if (browseId != null) {
                  debugPrint(
                      '[InnerTube] Found "See All" link (via bottom, title, or tab) for artist/channel. Loading full list from $browseId...');
                  final fullList =
                      await _fetchFullTracks(browseId, params: params);
                  if (fullList.isNotEmpty) {
                    return fullList;
                  }
                }
              } else {
                debugPrint(
                    '[InnerTube] NO "See All" link found for shelf "$title". Loading preview items only.');
                debugPrint('[InnerTube] Shelf keys: ${shelf.keys.toList()}');

                // Aggressive Fallback: If we are in the "Home" tab (implied by context) and found no "See All",
                // try to explicitly find the "Songs" tab params if possible.
                // This is tricky without the full tab object here, but we can look at the top-level tabs we logged earlier.
                // This block relies on the `tabs` variable being available in the outer scope.
                // Let's rely on the outer loop's tab scanning which we added earlier (lines 809-840).
                // However, we can enhance THAT loop to be smarter.
              }

              final shelfContents = shelf['contents'] as List?;
              if (shelfContents != null) {
                for (final item in shelfContents) {
                  final renderer = item['musicResponsiveListItemRenderer'];
                  if (renderer != null) {
                    final song = _parseShelfItem(renderer, artistName);
                    if (song != null) tracks.add(song);
                  }
                }
              }

              // Get continuation token for loading more
              continuationToken = shelf['continuations']?[0]
                  ?['nextContinuationData']?['continuation'];
              if (continuationToken != null) {
                debugPrint('[InnerTube] Found continuation token in shelf.');
              }

              // If we found songs, break
              if (tracks.isNotEmpty) break;
            }

            // Also check for musicCarouselShelfRenderer
            final carousel = section['musicCarouselShelfRenderer'];
            if (carousel != null) {
              final header =
                  carousel['header']?['musicCarouselShelfBasicHeaderRenderer'];
              final title = header?['title']?['runs']?[0]?['text'];
              debugPrint('[InnerTube] Found Carousel Shelf: "$title"');

              // Check for "More" / "See All" button in carousel header
              // Usually inside 'moreContentButton' -> 'buttonRenderer' -> 'navigationEndpoint'
              // OR sometimes as title navigation endpoint
              var browseEndpoint = header?['moreContentButton']
                  ?['buttonRenderer']?['navigationEndpoint']?['browseEndpoint'];

              if (browseEndpoint == null) {
                browseEndpoint = header?['title']?['runs']?[0]
                    ?['navigationEndpoint']?['browseEndpoint'];
              }

              // Special check for "Top Songs" / "Songs" title to allow fallback logic if explicit endpoint missing
              // but we might want to trigger the "Songs" tab search if we suspect this is the songs list.
              // For now, let's trust explicit endpoints first.

              if (browseEndpoint != null) {
                final browseId = browseEndpoint['browseId'];
                final params = browseEndpoint['params'];
                if (browseId != null) {
                  debugPrint(
                      '[InnerTube] Found "See All" link in Carousel header. Loading full list from $browseId...');
                  final fullList =
                      await _fetchFullTracks(browseId, params: params);
                  if (fullList.isNotEmpty) {
                    return fullList;
                  }
                }
              }

              final carouselContents = carousel['contents'] as List?;
              if (carouselContents != null) {
                for (final item in carouselContents) {
                  final renderer = item['musicResponsiveListItemRenderer'] ??
                      item['musicTwoRowItemRenderer'];
                  if (renderer != null) {
                    final song = _parseCarouselItem(renderer, artistName);
                    if (song != null) tracks.add(song);
                  }
                }
              }
              if (tracks.isNotEmpty) break;
            }
          }
        }
      } catch (e) {
        debugPrint('[InnerTube] Error parsing artist tracks: $e');
      }

      // Load more tracks using continuation if we have fewer than 200
      if (continuationToken != null && tracks.length < 200) {
        final moreTracks = await _loadMoreArtistTracks(
            continuationToken, artistName, 200 - tracks.length);
        tracks.addAll(moreTracks);
      }

      debugPrint(
          '[InnerTube] Found ${tracks.length} tracks for artist $artistId');

      // Aggressive Fallback: If we have very few tracks (<= 50) and no continuation,
      // and we haven't already fetched a "See All" list (implied by execution flow),
      // let's try to find a "Songs" or "Videos" tab and fetch that.
      if (tracks.length < 50 && continuationToken == null) {
        try {
          final tabs = data['contents']?['singleColumnBrowseResultsRenderer']
              ?['tabs'] as List?;
          if (tabs != null) {
            for (final tab in tabs) {
              final tabTitle = tab['tabRenderer']?['title'];
              if (tabTitle != null) {
                final titleLower = tabTitle.toLowerCase();
                if ([
                  'songs',
                  'пісні',
                  'videos',
                  'відео',
                  'uploads',
                  'завантаження'
                ].contains(titleLower)) {
                  final tabEndpoint =
                      tab['tabRenderer']?['endpoint']?['browseEndpoint'];
                  if (tabEndpoint != null) {
                    final browseId = tabEndpoint['browseId'];
                    final params = tabEndpoint['params'];
                    if (browseId != null) {
                      debugPrint(
                          '[InnerTube] Aggressive Fallback: Fetching "$tabTitle" tab for full list...');
                      final fullList =
                          await _fetchFullTracks(browseId, params: params);
                      if (fullList.isNotEmpty) {
                        return fullList;
                      }
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[InnerTube] Aggressive Fallback failed: $e');
        }
      }

      return tracks;
    } catch (e) {
      debugPrint('[InnerTube] Failed to fetch artist tracks: $e');
      return [];
    }
  }

  /// Load more artist tracks using continuation token
  Future<List<YouTubeSong>> _loadMoreArtistTracks(
      String continuation, String artistName, int maxTracks) async {
    final List<YouTubeSong> tracks = [];
    String? currentContinuation = continuation;

    while (currentContinuation != null && tracks.length < maxTracks) {
      try {
        await _rateLimiter.throttle();

        final body = _webContextBody();
        body['continuation'] = currentContinuation;

        final response = await _dio.post('/browse', data: body);
        final data = response.data;

        // Parse continuation response
        final contents = data['continuationContents']?['musicShelfContinuation']
            ?['contents'] as List?;
        if (contents == null || contents.isEmpty) break;

        for (final item in contents) {
          if (tracks.length >= maxTracks) break;
          final renderer = item['musicResponsiveListItemRenderer'];
          if (renderer != null) {
            final song = _parseShelfItem(renderer, artistName);
            if (song != null) tracks.add(song);
          }
        }

        // Get next continuation
        currentContinuation = data['continuationContents']
                ?['musicShelfContinuation']?['continuations']?[0]
            ?['nextContinuationData']?['continuation'];

        debugPrint(
            '[InnerTube] Loaded ${tracks.length} more tracks via continuation');
      } catch (e) {
        debugPrint('[InnerTube] Error loading continuation: $e');
        break;
      }
    }

    return tracks;
  }

  /// Parse a shelf item into YouTubeSong
  YouTubeSong? _parseShelfItem(
      Map<String, dynamic> renderer, String fallbackArtist) {
    try {
      final flexColumns = renderer['flexColumns'] as List?;
      if (flexColumns == null || flexColumns.isEmpty) return null;

      String title = '';
      String artist = fallbackArtist;
      String? artistId;
      String videoId = '';
      String thumbnail = '';

      // Title from first column
      final col0 = flexColumns[0]['musicResponsiveListItemFlexColumnRenderer']
          ?['text']?['runs']?[0];
      title = col0?['text'] ?? '';
      videoId = col0?['navigationEndpoint']?['watchEndpoint']?['videoId'] ?? '';

      // Artist from second column if available
      if (flexColumns.length > 1) {
        final col1Runs = flexColumns[1]
            ['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
        if (col1Runs != null && col1Runs.isNotEmpty) {
          final artistInfo = _extractArtistInfo(col1Runs);
          artist = artistInfo['name'] ?? fallbackArtist;
          artistId = artistInfo['id'];
        }
      }

      // Fallback: Recursive search for artistId
      if (artistId == null) {
        artistId = _findArtistBrowseIdRecursive(renderer);
      }

      // Thumbnail
      final thumbs = renderer['thumbnail']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'] as List?;
      if (thumbs != null && thumbs.isNotEmpty) {
        thumbnail = thumbs.last['url'] ?? '';
      }

      if (title.isEmpty || videoId.isEmpty) return null;

      return YouTubeSong(
        videoId: videoId,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnail,
        artistId: artistId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse a carousel item into YouTubeSong
  YouTubeSong? _parseCarouselItem(
      Map<String, dynamic> renderer, String fallbackArtist) {
    try {
      String title = '';
      String artist = fallbackArtist;
      String? artistId;
      String videoId = '';
      String thumbnail = '';

      // For musicTwoRowItemRenderer
      if (renderer.containsKey('title')) {
        title = renderer['title']?['runs']?[0]?['text'] ?? '';
        videoId =
            renderer['navigationEndpoint']?['watchEndpoint']?['videoId'] ?? '';
        
        // Extract artist with artistId
        final subtitleRuns = renderer['subtitle']?['runs'] as List?;
        if (subtitleRuns != null && subtitleRuns.isNotEmpty) {
          final artistInfo = _extractArtistInfo(subtitleRuns);
          artist = artistInfo['name'] ?? fallbackArtist;
          artistId = artistInfo['id'];
        }

        final thumbs = renderer['thumbnailRenderer']?['musicThumbnailRenderer']
            ?['thumbnail']?['thumbnails'] as List?;
        if (thumbs != null && thumbs.isNotEmpty) {
          thumbnail = thumbs.last['url'] ?? '';
        }
      }

      // Fallback: Recursive search for artistId
      if (artistId == null) {
        artistId = _findArtistBrowseIdRecursive(renderer);
      }

      if (title.isEmpty || videoId.isEmpty) return null;

      return YouTubeSong(
        videoId: videoId,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnail,
        artistId: artistId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetches the user's liked songs from YouTube Music account
  /// Uses the special playlist ID "LM" (Liked Music)
  Future<List<YouTubeSong>> getYouTubeLikedSongs({int limit = 200}) async {
    await _rateLimiter.throttle();
    await _addAuthHeaders();

    debugPrint('[InnerTube] Fetching YouTube Liked Songs (playlist LM)...');

    try {
      // "LM" is the special playlist ID for liked songs in YouTube Music
      // We need to prepend "VL" to make it a valid browse ID
      final tracks = await _fetchFullTracks('VLLM');
      debugPrint('[InnerTube] Fetched ${tracks.length} liked songs from YouTube');
      
      // Limit the results if specified
      if (limit > 0 && tracks.length > limit) {
        return tracks.sublist(0, limit);
      }
      return tracks;
    } catch (e) {
      debugPrint('[InnerTube] Error fetching YouTube liked songs: $e');
      return [];
    }
  }

  Future<List<YouTubeSong>> getPlaylistTracks(String playlistId) async {
    await _rateLimiter.throttle();
    await _addAuthHeaders();

    // Handle Radio Mix IDs (RDAMVM prefix) - these are not browsable playlists
    // They require the /next endpoint with a videoId instead
    if (playlistId.startsWith('RDAMVM')) {
      debugPrint(
          '[InnerTube] Radio Mix ID detected: $playlistId - extracting videoId');
      // Extract the videoId from RDAMVM{videoId}
      final videoId = playlistId.substring(6); // Remove 'RDAMVM' prefix
      if (videoId.length == 11) {
        // Return a single track with the videoId
        return [
          YouTubeSong(
            videoId: videoId,
            title: 'Radio Mix Track',
            artist: 'Unknown',
            thumbnailUrl: '',
          )
        ];
      }
    }

    // Handle Artist/Channel IDs (UC prefix) - fetch artist's popular tracks
    if (playlistId.startsWith('UC')) {
      debugPrint('[InnerTube] Artist/Channel ID detected: $playlistId');
      return await _getArtistTopTracks(playlistId);
    }

    // For everything else (Album, Playlist), use the generic fetcher
    return await _fetchFullTracks(playlistId);
  }

  /// Rate a song on YouTube Music account (like/unlike)
  /// [rating] should be 'LIKE' to like, 'INDIFFERENT' to remove like
  Future<bool> rateSong(String videoId, String rating) async {
    try {
      debugPrint(
          '[InnerTube] rateSong called: videoId=$videoId, rating=$rating');

      // YouTube Music uses /like/like endpoint for both like and remove
      final endpoint = rating == 'LIKE' ? '/like/like' : '/like/removelike';

      // ytmusicapi format: {"target": {"videoId": videoId}} - context is added by _postRequest
      final body = {
        ..._webContextBody(),
        'target': {
          'videoId': videoId,
        },
      };

      final response = await _postRequest(endpoint, body);

      final success = response.containsKey('actions') ||
          response.containsKey('responseContext');

      debugPrint(
          '[InnerTube] rateSong result: ${success ? 'SUCCESS' : 'FAILED'}');
      return success;
    } catch (e) {
      debugPrint('[InnerTube] rateSong error: $e');
      return false;
    }
  }

  /// Get the playback tracking URL for a video
  /// This URL is used to report playback to YouTube history
  Future<String?> getPlaybackTrackingUrl(String videoId) async {
    try {
      debugPrint('[InnerTube] getPlaybackTrackingUrl for videoId=$videoId');

      final body = {
        ..._webContextBody(),
        'video_id': videoId,
        'playbackContext': {
          'contentPlaybackContext': {
            'signatureTimestamp': _getSignatureTimestamp(),
          }
        },
      };

      final response = await _postRequest('/player', body);

      // Extract playbackTracking.videostatsPlaybackUrl.baseUrl
      final playbackTracking =
          response['playbackTracking'] as Map<String, dynamic>?;
      if (playbackTracking == null) {
        debugPrint('[InnerTube] No playbackTracking in response');
        return null;
      }

      final videostatsPlaybackUrl =
          playbackTracking['videostatsPlaybackUrl'] as Map<String, dynamic>?;
      final trackingUrl = videostatsPlaybackUrl?['baseUrl'] as String?;

      debugPrint(
          '[InnerTube] Got tracking URL: ${trackingUrl?.substring(0, 80)}...');
      return trackingUrl;
    } catch (e) {
      debugPrint('[InnerTube] getPlaybackTrackingUrl error: $e');
      return null;
    }
  }

  /// Get signature timestamp (days since epoch) for player requests
  int _getSignatureTimestamp() {
    final now = DateTime.now();
    final epoch = DateTime(1970, 1, 1);
    return now.difference(epoch).inDays - 1;
  }

  /// Report playback to YouTube history
  /// Should be called after ~30 seconds of playback
  Future<bool> reportPlayback(String trackingUrl) async {
    try {
      // Add required params like ytmusicapi does:
      // CPNA = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
      // cpn = "".join(CPNA[randint(0, 256) & 63] for _ in range(0, 16))
      // params = {"ver": 2, "c": "WEB_REMIX", "cpn": cpn}

      final cpn = _generateCpn();
      final uri = Uri.parse(trackingUrl).replace(queryParameters: {
        ...Uri.parse(trackingUrl).queryParameters,
        'ver': '2',
        'c': 'WEB_REMIX',
        'cpn': cpn,
      });

      debugPrint(
          '[InnerTube] reportPlayback to: ${uri.toString().substring(0, 100)}... with cpn=$cpn');

      await _addAuthHeaders();

      // GET request to the tracking URL
      final response = await _dio.getUri(
        uri,
        options: Options(
          headers: {
            'User-Agent': _webUserAgent,
            'X-YouTube-Client-Name': '67', // WEB_REMIX
            'X-YouTube-Client-Version': '1.20240904.01.00',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // 204 No Content = success, 200 also acceptable
      final success = response.statusCode == 204 || response.statusCode == 200;
      debugPrint(
          '[InnerTube] reportPlayback result: statusCode=${response.statusCode}, success=$success');
      return success;
    } catch (e) {
      debugPrint('[InnerTube] reportPlayback error: $e');
      return false;
    }
  }

  String _generateCpn() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_';
    final random = Random();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<Map<String, dynamic>?> _browseContinuation(String token) async {
    // web context usually works for continuations
    // For continuations, we often don't need browseId, just the token ??
    // Actually, usually it's passed as 'continuation' param? or inside parsed params?
    // /browse endpoint accepts 'continuation' param.
    // Clean body?
    // body.remove('browseId');
    // NOTE: InnerTube often uses standard browse endpoint with `continuation` field?
    // Or just `continuation` in URL query?
    // It's usually `continuation` in body?
    // Let's try body['continuation'] = token;
    // According to reverse engineering, it's typically:
    // POST /browse
    // { context: ..., continuation: "token" }

    // Create fresh body
    final contBody = _webContextBody();
    contBody['continuation'] = token;

    try {
      final response = await _dio.post('/browse', data: contBody);
      return response.data;
    } catch (e) {
      debugPrint('[InnerTube] Continuation failed: $e');
      return null;
    }
  }

  String? _recursiveFindContinuationToken(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('nextContinuationData')) {
        return data['nextContinuationData']['continuation'];
      }
      for (var value in data.values) {
        final token = _recursiveFindContinuationToken(value);
        if (token != null) return token;
      }
    } else if (data is List) {
      for (var item in data) {
        final token = _recursiveFindContinuationToken(item);
        if (token != null) return token;
      }
    }
    return null;
  }

  List<YouTubeSong> _parsePlaylistTracks(Map<String, dynamic> data,
      {String? fallbackArtist, String? fallbackThumbnail}) {
    final tracks = <YouTubeSong>[];
    try {
      // 1. Try Structured Path (Faster)
      // Common path: contents -> singleColumn -> tabs -> tab -> content -> sectionList -> contents -> musicPlaylistShelf -> contents
      var sectionList = data['contents']?['singleColumnBrowseResultsRenderer']
              ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']
          ?['contents'];

      // Secondary path (Desktop/Web): twoColumn -> secondaryContents
      if (sectionList == null) {
        sectionList = data['contents']?['twoColumnBrowseResultsRenderer']
            ?['secondaryContents']?['sectionListRenderer']?['contents'];
      }

      List<dynamic> items = [];
      bool foundStructured = false;

      if (sectionList != null && sectionList is List) {
        for (var section in sectionList) {
          if (section['musicPlaylistShelfRenderer'] != null) {
            items = section['musicPlaylistShelfRenderer']['contents'] ?? [];
            foundStructured = true;
            break;
          } else if (section['musicShelfRenderer'] != null) {
            // Sometimes playlists appear as shelves
            items = section['musicShelfRenderer']['contents'] ?? [];
            foundStructured = true;
            break;
          }
        }
      }

      // 2. Fallback to Recursive Search if structured path failed or empty
      if (!foundStructured || items.isEmpty) {
        // Use recursive search to find ALL musicResponsiveListItemRenderer nodes
        final recursiveItems =
            _recursiveFindItems(data, 'musicResponsiveListItemRenderer');

        if (recursiveItems.isEmpty) {
          // Try searching for secondary items just in case
          final secondaryItems =
              _recursiveFindItems(data, 'musicTwoColumnItemRenderer');
          recursiveItems.addAll(secondaryItems);
        }
        items = recursiveItems;
      }

      for (var mrlir in items) {
        var song = _parseSingleSong(mrlir);
        if (song != null) {
          // Apply Fallbacks
          if ((song.artist == 'Unknown' || song.artist.isEmpty) &&
              fallbackArtist != null &&
              fallbackArtist != 'Unknown') {
            song = song.copyWith(artist: fallbackArtist);
          }
          if ((song.thumbnailUrl.isEmpty) && fallbackThumbnail != null) {
            song = song.copyWith(thumbnailUrl: fallbackThumbnail);
          }
          tracks.add(song);
        }
      }
    } catch (e) {
      debugPrint('Error parsing playlist tracks: $e');
    }
    return tracks;
  }

  /// Recursively find all maps with the given key
  List<Map<String, dynamic>> _recursiveFindItems(dynamic data, String key) {
    final results = <Map<String, dynamic>>[];

    if (data is Map<String, dynamic>) {
      if (data.containsKey(key)) {
        results.add(data[key]);
      }

      for (var value in data.values) {
        if (value is Map<String, dynamic> || value is List) {
          results.addAll(_recursiveFindItems(value, key));
        }
      }
    } else if (data is List) {
      for (var item in data) {
        results.addAll(_recursiveFindItems(item, key));
      }
    }

    return results;
  }

  /// Parse Top Result card (musicCardShelfRenderer)
  YouTubeSong? _parseTopResultCard(Map<String, dynamic> card) {
    try {
      // Title is in 'title' -> 'runs'
      final title = card['title']?['runs']?[0]?['text'] as String?;
      if (title == null) return null;

      // Subtitle contains artist and type info
      String artist = 'Unknown';
      final subtitleRuns =
          card['subtitle']?['runs'] as List?; // Re-added definition
      String? artistId;
      if (subtitleRuns != null) {
        final artistInfo = _extractArtistInfo(subtitleRuns);
        artist = artistInfo['name'] ?? 'Unknown';
        artistId = artistInfo['id'];
      }

      // Extract duration from runs or lengthTexts
      String? videoId;
      String? playlistId;

      // Check onTap for watchEndpoint
      videoId = card['onTap']?['watchEndpoint']?['videoId'];
      playlistId = card['onTap']?['watchEndpoint']?['playlistId'];

      // Check buttons for play action
      if (videoId == null) {
        final buttons = card['buttons'] as List?;
        if (buttons != null) {
          for (var btn in buttons) {
            final btnRenderer = btn['buttonRenderer'];
            if (btnRenderer != null) {
              videoId = btnRenderer['command']?['watchEndpoint']?['videoId'];
              playlistId ??=
                  btnRenderer['command']?['watchEndpoint']?['playlistId'];
              if (videoId != null) break;
            }
          }
        }
      }

      // Check for browseEndpoint (Artist/Album result)
      String? browseId;
      if (videoId == null) {
        browseId = card['onTap']?['browseEndpoint']?['browseId'];
      }

      // Thumbnail
      String thumbnailUrl = '';
      final thumbs = card['thumbnail']?['musicThumbnailRenderer']?['thumbnail']
          ?['thumbnails'] as List?;
      if (thumbs != null && thumbs.isNotEmpty) {
        thumbnailUrl = thumbs.last['url'] ?? '';
      }

      // If it's an Artist result (browseId starts with UC), return as playlist (Channel)
      if (browseId != null && browseId.startsWith('UC')) {
        return YouTubeSong(
          videoId: browseId, // User browseId as ID
          title: title,
          artist: 'Artist', // Title is usually the artist name
          thumbnailUrl: thumbnailUrl,
          playlistId: browseId,
          isPlaylist: true,
          category: 'Artist',
        );
      }

      // If we have a playlist ID (Album/Single), return as playlist
      if (playlistId != null && videoId == null) {
        return YouTubeSong(
          videoId: playlistId, // Use playlist ID as identifier
          title: title,
          artist: artist,
          thumbnailUrl: thumbnailUrl,
          playlistId: playlistId,
          isPlaylist: true,
          artistId: artistId,
        );
      }

      // If we have videoId, return as song
      if (videoId != null) {
        return YouTubeSong(
          videoId: videoId,
          title: title,
          artist: artist,
          thumbnailUrl: thumbnailUrl,
          playlistId: playlistId,
          artistId: artistId,
        );
      }

      return null;
    } catch (e) {
      debugPrint('[InnerTube] _parseTopResultCard error: $e');
      return null;
    }
  }

  YouTubeSong? _parseSingleSong(Map<String, dynamic> item) {
    try {
      // Unwrap if item is wrapped in a renderer key
      var mrlir = item['musicResponsiveListItemRenderer'] ??
          item['musicTwoRowItemRenderer'] ??
          item['musicTwoColumnItemRenderer'] ??
          item; // Fallback to item itself if already unwrapped

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

      // Extract artist and category from subtitle runs
      String artist = "Unknown";
      String?
          artistId; // Declare here so it is visible in entire function scope
      String category = "";

      final flexCol1 = mrlir['flexColumns']?[1]
          ?['musicResponsiveListItemFlexColumnRenderer'];

      List? subtitleRuns;
      if (flexCol1 != null) {
        subtitleRuns = flexCol1['text']?['runs'] as List?;
      } else {
        subtitleRuns = mrlir['subtitle']?['runs'] as List?;
      }

      if (subtitleRuns != null && subtitleRuns.isNotEmpty) {
        // Check for non-music categories FIRST and filter out
        for (var run in subtitleRuns) {
          final text = run['text']?.toString().trim() ?? '';
          // Non-music categories we want to FILTER OUT
          if ([
            'Video',
            'Відео',
            'Series',
            'Серія',
            'Episode',
            'Епізод',
            'Podcast',
            'Подкаст',
            'News',
            'Новини',
            'Live',
            'Наживо',
            'Хіт-парад', // Chart/Ranking videos
          ].contains(text)) {
            // Skip this item entirely - it's not music
            return null;
          }
        }

        // Extract Category (Single, Album, EP, Playlist)
        for (var run in subtitleRuns) {
          final text = run['text']?.toString().trim() ?? '';
          if ([
            'Single',
            'Album',
            'EP',
            'Playlist',
            'Song',
            'Сингл',
            'Альбом',
            'Плейлист',
            'Альбом',
            'Плейлист',
            'Пісня',
            'Канал',
            'Channel',
            'Artist',
          ].contains(text)) {
            category = text;
          }
        }

        // Extract Artist (Smart Check using Navigation Endpoints)
        final artistNames = <String>[];
        for (var run in subtitleRuns) {
          final nav = run['navigationEndpoint'];
          final pageType = nav?['browseEndpoint']
                  ?['browseEndpointContextSupportedConfigs']
              ?['browseEndpointContextMusicConfig']?['pageType'];

          // Check for Artist or User Channel (Indie artists)
          if (pageType == 'MUSIC_PAGE_TYPE_ARTIST' ||
              pageType == 'MUSIC_PAGE_TYPE_USER_CHANNEL') {
            if (run['text'] != null) {
              artistNames.add(run['text']);
              // Capture the first valid browseId as artistId
              if (artistId == null) {
                artistId = nav?['browseEndpoint']?['browseId'];
              }
            }
          }
        }

        if (artistNames.isNotEmpty) {
          artist = artistNames.join(' & ');
          // artistId is already captured from the loop above
        } else {
          // Fallback to text extraction
          final artistInfo = _extractArtistInfo(subtitleRuns);
          artist = artistInfo['name'] ?? 'Unknown';
          artistId = artistInfo['id'];

          if (artistId == null) {
            debugPrint(
                '[InnerTube] WARNING: No artistId found for "$title". Runs: $subtitleRuns');
          } else {
            debugPrint(
                '[InnerTube] Found artistId: $artistId for artist: $artist');
          }
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

      // Path 5: Menu items (Queue Add often has it)
      if (videoId == null) {
        final menuItems = mrlir['menu']?['menuRenderer']?['items'] as List?;
        if (menuItems != null) {
          for (var item in menuItems) {
            final serviceEndpoint =
                item['menuServiceItemRenderer']?['serviceEndpoint'];
            // Check Queue Add Endpoint
            if (serviceEndpoint?['queueAddEndpoint']?['queueTarget']
                    ?['videoId'] !=
                null) {
              videoId =
                  serviceEndpoint['queueAddEndpoint']['queueTarget']['videoId'];
              break;
            }
            // Check Watch Endpoint in menu
            if (serviceEndpoint?['watchEndpoint']?['videoId'] != null) {
              videoId = serviceEndpoint['watchEndpoint']['videoId'];
              break;
            }
          }
        }
      }

      // Path 6: Thumbnail URL Hack (Last resort)
      if (videoId == null) {
        final thumbs = (mrlir['thumbnail']?['musicThumbnailRenderer'] ??
                mrlir['thumbnailRenderer']
                    ?['musicThumbnailRenderer'])?['thumbnail']?['thumbnails']
            as List?;
        if (thumbs != null && thumbs.isNotEmpty) {
          final url = thumbs.last['url'] as String;
          // Regex for vi/<ID>/ or vi_webp/<ID>/
          final regExp = RegExp(r'vi(?:_webp)?\/([a-zA-Z0-9_-]{11})\/');
          final match = regExp.firstMatch(url);
          if (match != null) {
            videoId = match.group(1);
          }
        }
      }

      // Extract Playlist/Browse ID
      String? playlistId = playButton?['playNavigationEndpoint']
          ?['watchEndpoint']?['playlistId'];
      playlistId ??=
          mrlir['navigationEndpoint']?['watchEndpoint']?['playlistId'];

      // If no videoId, check for browseEndpoint (Album/Playlist)
      String? browseId;
      if (videoId == null) {
        browseId = mrlir['navigationEndpoint']?['browseEndpoint']?['browseId'];
        if (browseId == null) {
          browseId = mrlir['onTap']?['browseEndpoint']?['browseId'];
        }
      }

      // If we have no videoId and no browseId/playlistId, we can't do anything
      if (videoId == null && playlistId == null && browseId == null)
        return null;

      // Extract thumbnail with multiple paths
      final thumbnails = (mrlir['thumbnail']?['musicThumbnailRenderer'] ??
              mrlir['thumbnailRenderer']
                  ?['musicThumbnailRenderer'])?['thumbnail']?['thumbnails']
          as List?;
      String thumbUrl = '';
      if (thumbnails != null && thumbnails.isNotEmpty) {
        thumbUrl = thumbnails.last['url'];
        if (thumbUrl.startsWith('//')) {
          thumbUrl = 'https:$thumbUrl';
        }
      }

      // Extract duration from runs or lengthText
      int duration = 0;
      final lengthText = mrlir['lengthText']?['runs']?[0]?['text'] ??
          mrlir['fixedColumns']?[0]
                  ?['musicResponsiveListItemFixedColumnRenderer']?['text']
              ?['runs']?[0]?['text'];

      if (lengthText != null) {
        duration = _parseDuration(lengthText);
      } else {
        // Fallback 1: Check fixedColumns (common in playlists/queues)
        final fixedCols = mrlir['fixedColumns'] as List?;
        if (fixedCols != null && fixedCols.isNotEmpty) {
          final text = fixedCols[0]
                  ['musicResponsiveListItemFixedColumnRenderer']?['text']
              ?['runs']?[0]?['text'];
          if (text != null) {
            duration = _parseDuration(text);
          }
        }

        // Fallback 2: Check subtitle runs for duration (often last item e.g. "Artist • Album • 3:45")
        if (duration == 0 && subtitleRuns != null && subtitleRuns.isNotEmpty) {
          final lastRun = subtitleRuns.last['text']?.toString().trim();
          if (lastRun != null && RegExp(r'^\d+:\d+').hasMatch(lastRun)) {
            duration = _parseDuration(lastRun);
          }
        }
      }
      if (duration == 0) {
        // debugPrint(
        //     '[InnerTube] WARNING: Duration is 0 for $videoId ($title). Raw lengthText: $lengthText');
        // debugPrint('[InnerTube] Keys: ${mrlir.keys.toList()}');
        // if (subtitleRuns != null) {
        //   debugPrint(
        //       '[InnerTube] Subtitle runs: ${subtitleRuns.map((r) => r['text']).toList()}');
        // }
        // if (mrlir['fixedColumns'] != null) {
        //   debugPrint(
        //       '[InnerTube] Fixed Columns found (potential duration source).');
        // }
      } else {
        // debugPrint('[InnerTube] Parsed duration: $duration s for $videoId');
      }

      final isPlaylist =
          videoId == null && (browseId != null || playlistId != null);
      // Use browseId as playlistId if playlistId is missing
      final effectivePlaylistId = playlistId ?? browseId;

      // Fallback: If artistId is missing, check if this is an Artist/Channel page
      if (artistId == null && browseId != null) {
        if (category == 'Artist' ||
            category == 'Channel' ||
            category == 'Канал' ||
            category == 'Виконавець' ||
            browseId.startsWith('UC')) {
          artistId = browseId;
        }
      }

      // Fallback 3: Recursive search for ANY artist ID in the raw object
      if (artistId == null) {
        artistId = _findArtistBrowseIdRecursive(mrlir);
        if (artistId != null) {
          debugPrint(
              '[InnerTube] Recovered artistId via recursive search: $artistId');
        } else {
          debugPrint(
              '[InnerTube] !!! WARNING: No artistId found for "$title" even after recursive search.');
          debugPrint('[InnerTube] Raw payload: $mrlir');
        }
      }

      return YouTubeSong(
        videoId: videoId ??
            effectivePlaylistId ??
            '', // Fallback to playlistId as ID if videoId missing
        title: title,
        artist: artist,
        thumbnailUrl: thumbUrl,
        artistId: artistId,
        playlistId: effectivePlaylistId,
        isPlaylist: isPlaylist,
        category: category,
        duration: duration, // Pass the parsed duration
      );
    } catch (e) {
      debugPrint('[InnerTube] _parseSingleSong error: $e');
      return null;
    }
  }

  /// Recursively searches for a browseId that looks like an artist/channel ID.
  String? _findArtistBrowseIdRecursive(dynamic data) {
    if (data is Map) {
      // Check if this map has a browseId
      if (data.containsKey('browseId')) {
        final id = data['browseId'];
        if (id is String && (id.startsWith('UC') || id.startsWith('UA'))) {
          return id;
        }
      }
      // Recursive search values
      for (var value in data.values) {
        final found = _findArtistBrowseIdRecursive(value);
        if (found != null) return found;
      }
    } else if (data is List) {
      for (var item in data) {
        final found = _findArtistBrowseIdRecursive(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Extract artist info from runs.
  /// Returns {'name': String, 'id': String?}
  Map<String, String?> _extractArtistInfo(List runs) {
    if (runs.isEmpty) return {'name': 'Unknown', 'id': null};

    final artistParts = <String>[];
    String? artistId;

    for (var run in runs) {
      final text = run['text']?.toString() ?? '';
      if (text.isEmpty) continue;

      // Stop at the metadata separator
      if (text == ' • ' || text == '•') {
        break;
      }

      // Stop if we hit view counts (defensive)
      if (text.contains('views') ||
          text.contains('plays') ||
          text == 'Watch' ||
          text.contains(' переглядів')) {
        break;
      }

      artistParts.add(text);

      // Capture the FIRST valid browseId we find (usually the main artist)
      if (artistId == null) {
        final browseId =
            run['navigationEndpoint']?['browseEndpoint']?['browseId'];
        if (browseId != null &&
            (browseId.startsWith('UC') ||
                browseId.startsWith('UA') ||
                // Sometimes channel IDs don't start with UC but rely on page type
                run['navigationEndpoint']?['browseEndpoint']
                            ?['browseEndpointContextSupportedConfigs']
                        ?['browseEndpointContextMusicConfig']?['pageType'] ==
                    'MUSIC_PAGE_TYPE_ARTIST')) {
          artistId = browseId;
        }
      }
    }

    if (artistParts.isEmpty) return {'name': 'Unknown', 'id': null};

    final fullString = artistParts.join('').trim();
    return {'name': fullString, 'id': artistId};
  }

  /// Fetches radio/related tracks for a given video using the /next endpoint
  /// This is what YouTube Music uses to populate the "Up Next" queue
  Future<List<YouTubeSong>> getRadioTracks(String videoId) async {
    await _rateLimiter.throttle();
    await _addAuthHeaders();

    final body = _webContextBody();
    body['videoId'] = videoId;
    body['enablePersistentPlaylistPanel'] = true;
    body['isAudioOnly'] = true;
    body['tunerSettingValue'] = 'AUTOMIX_SETTING_NORMAL';

    // Request automix/radio playlist
    body['playlistId'] = 'RDAMVM$videoId';

    try {
      final response = await _dio.post('/next', data: body);
      final data = response.data;

      final List<YouTubeSong> tracks = [];

      // Parse the playlist panel from watchNextRenderer
      try {
        final contents = data['contents']
                ?['singleColumnMusicWatchNextResultsRenderer']
            ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs'];

        if (contents != null) {
          for (final tab in contents) {
            final tabRenderer = tab['tabRenderer'];
            if (tabRenderer == null) continue;

            // Look for playlist panel (usually in the first or "Up Next" tab)
            final content = tabRenderer['content'];
            if (content == null) continue;

            final musicQueueRenderer = content['musicQueueRenderer'];
            if (musicQueueRenderer != null) {
              final queueContents = musicQueueRenderer['content']
                  ?['playlistPanelRenderer']?['contents'] as List?;

              if (queueContents != null) {
                for (final item in queueContents) {
                  final panelRenderer = item['playlistPanelVideoRenderer'];
                  if (panelRenderer != null) {
                    final song = _parsePlaylistPanelItem(panelRenderer);
                    if (song != null && song.videoId != videoId) {
                      tracks.add(song);
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[InnerTube] Error parsing radio tracks: $e');
      }

      debugPrint(
          '[InnerTube] Found ${tracks.length} radio tracks for $videoId');
      return tracks;
    } catch (e) {
      debugPrint('[InnerTube] Failed to fetch radio tracks: $e');
      return [];
    }
  }

  /// Parse a playlist panel item into YouTubeSong
  YouTubeSong? _parsePlaylistPanelItem(Map<String, dynamic> renderer) {
    try {
      final videoId = renderer['videoId'] as String?;
      if (videoId == null || videoId.isEmpty) return null;

      final title = renderer['title']?['runs']?[0]?['text'] as String? ?? '';
      if (title.isEmpty) return null;

      // Parse artist from shortBylineText or longBylineText
      String artist = 'Unknown';
      String? artistId;
      final shortByline = renderer['shortBylineText']?['runs'] as List?;
      final longByline = renderer['longBylineText']?['runs'] as List?;
      final bylineRuns = shortByline ?? longByline;

      if (bylineRuns != null && bylineRuns.isNotEmpty) {
        // Extract artist name and ID using the same logic as _extractArtistInfo
        final artistInfo = _extractArtistInfo(bylineRuns);
        artist = artistInfo['name'] ?? 'Unknown';
        artistId = artistInfo['id'];
      }

      // Fallback: Recursive search for artistId if not found
      if (artistId == null) {
        artistId = _findArtistBrowseIdRecursive(renderer);
      }

      // Get thumbnail
      String thumbnail = '';
      final thumbs = renderer['thumbnail']?['thumbnails'] as List?;
      if (thumbs != null && thumbs.isNotEmpty) {
        thumbnail = thumbs.last['url'] as String? ?? '';
      }

      // Get duration
      int duration = 0;
      final lengthText =
          renderer['lengthText']?['runs']?[0]?['text'] as String?;
      if (lengthText != null) {
        duration = _parseDuration(lengthText);
      }

      return YouTubeSong(
        videoId: videoId,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnail,
        duration: duration,
        artistId: artistId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetches lyrics for a given video using the /next and /browse endpoints
  /// Returns a Map with 'lyrics' (String) and 'isSynced' (bool) or null.
  Future<Map<String, dynamic>?> getLyrics(String videoId) async {
    try {
      await _rateLimiter.throttle();
      await _addAuthHeaders();

      // 1. Get browseId for lyrics using /next
      final nextBody = _webContextBody();
      nextBody['videoId'] = videoId;

      final nextResponse = await _dio.post('/next', data: nextBody);
      final nextData = nextResponse.data;

      // Extract lyrics browseId
      String? lyricsBrowseId;
      try {
        final tabs = nextData['contents']
                ?['singleColumnMusicWatchNextResultsRenderer']
            ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs'];

        if (tabs != null) {
          debugPrint(
              '[InnerTube] Found ${tabs.length} tabs in Watch Next response');
          for (var tab in tabs) {
            final tabRenderer = tab['tabRenderer'];
            final title = tabRenderer?['title'];
            debugPrint('[InnerTube] Tab title: $title');

            if (title == 'Lyrics' ||
                title == 'Тексти пісень' ||
                title == 'Тексты песен' ||
                title == 'Текст' ||
                title == 'Letra' ||
                title == 'Paroles' ||
                title == 'Songtexte') {
              lyricsBrowseId =
                  tabRenderer['endpoint']?['browseEndpoint']?['browseId'];
              debugPrint('[InnerTube] Found lyrics browseId: $lyricsBrowseId');
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('[InnerTube] Error extracting lyrics browseId: $e');
      }

      if (lyricsBrowseId == null) {
        debugPrint('[InnerTube] No lyrics browseId found for $videoId');
        return null;
      }

      // 2. Fetch lyrics content using /browse
      final browseBody = _webContextBody();
      browseBody['browseId'] = lyricsBrowseId;

      final browseResponse = await _dio.post('/browse', data: browseBody);
      final browseData = browseResponse.data;

      // 3. Parse lyrics
      // Synchronized lyrics are usually in timedLyricsData,
      // plain lyrics in description or runs.

      final lyricsRenderer = browseData['contents']?['sectionListRenderer']
          ?['contents']?[0]?['musicDescriptionShelfRenderer'];
      if (lyricsRenderer == null) return null;

      final String plainLyrics =
          (lyricsRenderer['description']?['runs'] as List?)
                  ?.map((r) => r['text'])
                  .join('') ??
              '';

      String syncedLyrics = '';

      // Try to parse synchronized lyrics if available
      final List? timedLyrics = lyricsRenderer['timedLyricsData'];
      if (timedLyrics != null && timedLyrics.isNotEmpty) {
        final buffer = StringBuffer();
        for (var line in timedLyrics) {
          final text = line['lyricLine'] ?? '';
          final startMsStr = line['startTimeMs']?.toString() ?? '0';
          final startMs = int.tryParse(startMsStr) ?? 0;

          final duration = Duration(milliseconds: startMs);
          final minutes = duration.inMinutes;
          final seconds = duration.inSeconds % 60;
          final hundredths = (duration.inMilliseconds % 1000) ~/ 10;

          final timestamp =
              '[${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}]';
          buffer.writeln('$timestamp $text');
        }
        syncedLyrics = buffer.toString().trim();
        debugPrint(
            '[InnerTube] Found and parsed ${timedLyrics.length} lines of synced lyrics');
      }

      return {
        'lyrics': plainLyrics,
        'syncedLyrics': syncedLyrics,
        'source': 'YouTube Music',
      };
    } catch (e) {
      debugPrint('[InnerTube] getLyrics failed: $e');
      return null;
    }
  }

  /// Fetches top tracks for an artist
  Future<List<YouTubeSong>> getArtistTopTracks(String browseId) async {
    // Use the comprehensive _getArtistTopTracks which handles tab navigation
    // and looks for "See All" links to fetch more tracks
    return _getArtistTopTracks(browseId);
  }

  /// Fetches tracks from any Browse ID (Playlist, Album, See All page)
  /// Supports optional params for specific views (e.g. "Songs")
  Future<List<YouTubeSong>> _fetchFullTracks(String browseId,
      {String? params}) async {
    await _rateLimiter.throttle();
    await _addAuthHeaders();

    final body = _webContextBody();
    body['browseId'] = browseId;
    if (params != null) {
      body['params'] = params;
    }

    try {
      final response = await _dio.post('/browse', data: body);
      final initialData = response.data;

      // Extract Header Metadata for Fallback
      String? fallbackArtist;
      String? fallbackThumbnail;

      try {
        final header = initialData['header']?['musicDetailHeaderRenderer'] ??
            initialData['header']?['musicResponsiveHeaderRenderer'];

        if (header != null) {
          // Thumbnails
          final thumbs = (header['thumbnail']?['musicThumbnailRenderer'] ??
              header['thumbnail'])?['thumbnails'] as List?;
          if (thumbs != null && thumbs.isNotEmpty) {
            fallbackThumbnail = thumbs.last['url'];
          }

          // ARTIST EXTRACTION STRATEGY
          debugPrint('[InnerTube] Attempting to extract artist from header...');

          // 1. Check 'straplineTextOne' / 'strapline' / 'straplineText'
          var straplineRuns = header['straplineTextOne']?['runs'] as List?;
          straplineRuns ??= header['strapline']?['runs'] as List?;
          straplineRuns ??= header['straplineText']?['runs'] as List?;

          if (straplineRuns != null) {
            final artistInfo = _extractArtistInfo(straplineRuns);
            fallbackArtist = artistInfo['name'] ?? 'Unknown';
            // Note: artistId is not used as a fallback for the track artist,
            // but rather for navigation. Keeping fallbackArtist for consistency.
            debugPrint(
                '[InnerTube] Found artist in strapline: $fallbackArtist');
          }

          // 2. Check 'byline' (Common in Detail Header for Artist)
          if (fallbackArtist == null ||
              fallbackArtist == 'Unknown' ||
              fallbackArtist == 'Single') {
            final bylineRuns = header['byline']
                        ?['musicDescriptionShelfRenderer']?['description']
                    ?['runs'] ??
                header['byline']?['runs'] as List?;
            if (bylineRuns != null) {
              final artistInfo = _extractArtistInfo(bylineRuns);
              final artist = artistInfo['name'] ?? 'Unknown';
              final artistId = artistInfo['id'];
              fallbackArtist =
                  artist; // Update fallbackArtist with the extracted artist
              debugPrint('[InnerTube] Found artist in byline: $fallbackArtist');
            }
          }

          // 3. Fallback to 'subtitle' (Album • Artist • Year) - standard Detail Header
          if (fallbackArtist == null ||
              fallbackArtist == 'Unknown' ||
              fallbackArtist == 'Single') {
            final subtitleRuns = header['subtitle']?['runs'] as List?;
            if (subtitleRuns != null) {
              final artistInfo = _extractArtistInfo(subtitleRuns);
              final text = artistInfo['name'];
              // Defensive: If it looks like a category, ignore it
              if (!['Single', 'Album', 'EP', 'Playlist', 'Сингл', 'Альбом']
                  .contains(text)) {
                fallbackArtist = text;
                debugPrint(
                    '[InnerTube] Found artist in subtitle: $fallbackArtist');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Header Parsing Error: $e');
      }

      final tracks = _parsePlaylistTracks(initialData,
          fallbackArtist: fallbackArtist, fallbackThumbnail: fallbackThumbnail);

      // Pagination Logic
      String? continuationToken = _recursiveFindContinuationToken(initialData);
      int pageCount = 0;
      // Limit pages to avoid infinite loops, e.g. 50 pages * 100 items = 5000 tracks
      const int maxPages = 50;
      while (continuationToken != null && pageCount < maxPages) {
        pageCount++;
        debugPrint(
            '[InnerTube] Fetching playlist continuation page $pageCount/$maxPages...');

        await Future.delayed(
            const Duration(milliseconds: 300)); // Gentle throttling
        final contResponse = await _browseContinuation(continuationToken);

        if (contResponse == null) break;

        final newTracks = _parsePlaylistTracks(contResponse);
        tracks.addAll(newTracks);

        continuationToken = _recursiveFindContinuationToken(contResponse);
      }

      if (pageCount >= maxPages && continuationToken != null) {
        _logger.w(
            '[InnerTube] Hit pagination limit ($maxPages pages). Some tracks may not be loaded.');
      }

      return tracks;
    } on YouTubeException {
      rethrow;
    } catch (e) {
      debugPrint('InnerTube _fetchFullTracks Error: $e');
      return [];
    }
  }

  /// Parse duration string (e.g. "3:45") to seconds
  int _parseDuration(String durationStr) {
    try {
      final parts = durationStr.split(':').map(int.parse).toList();
      if (parts.length == 2) {
        return parts[0] * 60 + parts[1];
      } else if (parts.length == 3) {
        return parts[0] * 3600 + parts[1] * 60 + parts[2];
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 0;
  }
}
