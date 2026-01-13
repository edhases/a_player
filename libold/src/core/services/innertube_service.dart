import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/youtube_song.dart';
import 'google_auth_service.dart';
import 'rate_limiter.dart';

import '../../data/datasources/app_database.dart';
import 'models/parser.dart';
 
class InnerTubeService {
  final Dio _dio;
  final GoogleAuthService _googleAuthService;
  final RateLimiter _rateLimiter = RateLimiter();
  final AppDatabase _db;
  String? _visitorId;

  // User agents for different clients
  static const String webUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const String androidUserAgent = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36';
  static const String iosUserAgent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';
  static const String tvUserAgent = 'Mozilla/5.0 (X11; CrOS x86_64 15136.72.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.6045.90 Safari/537.36';

  // Context configurations for different clients
  static const Map<String, dynamic> webContext = {
    "context": {
      "client": {
        "clientName": "WEB_REMIX",
        "clientVersion": "1.20230615.1.0",
        "hl": "en", 
        "gl": "US",
        "browserName": "Chrome",
        "browserVersion": "114.0.5735.134",
        "screenWidthPoints": 1920,
        "screenHeightPoints": 1080,
        "screenPixelDensity": 1,
        "platform": "DESKTOP"
      }
    }
  };

  static const Map<String, dynamic> androidMusicContext = {
    "context": {
      "client": {
        "clientName": "ANDROID_MUSIC",
        "clientVersion": "6.33.51", 
        "hl": "en", 
        "gl": "US",
        "androidSdkVersion": 31
      }
    }
  };

  static const Map<String, dynamic> iosContext = {
    "context": {
      "client": {
        "clientName": "IOS",
        "clientVersion": "19.10.1",
        "deviceMake": "Apple",
        "deviceModel": "iPhone14,5",
        "hl": "en",
        "gl": "US",
      }
    }
  };

  static const Map<String, dynamic> tvHtml5Context = {
    "context": {
      "client": {
        "clientName": "TVHTML5",
        "clientVersion": "7.20230405.08.01",
        "hl": "en",
        "gl": "US",
      }
    }
  };

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
  }

  void _initializeVisitorId() {
    // Generate a basic visitor ID format used by YouTube
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final suffix = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    _visitorId = 'CAIS$suffix';
    debugPrint('[InnerTubeService] Generated Visitor ID: $_visitorId');
  }

  // Universal POST request method with automatic auth header injection
  Future<Map<String, dynamic>> _postRequest(String endpoint, Map<String, dynamic> body, {bool useAuth = true, String? customUserAgent}) async {
    await _rateLimiter.throttle();
    
    if (useAuth) {
      await _addAuthHeaders();
    }

    // Add Visitor ID header
    if (_visitorId != null) {
      _dio.options.headers['X-Goog-Visitor-Id'] = _visitorId!;
    }

    // Use custom user agent if provided, otherwise determine based on context
    if (customUserAgent != null) {
      _dio.options.headers['User-Agent'] = customUserAgent;
    } else if (body.containsKey('context') && body['context'] is Map) {
      final clientName = body['context']['client']['clientName'];
      switch (clientName) {
        case 'WEB_REMIX':
          _dio.options.headers['User-Agent'] = webUserAgent;
          break;
        case 'ANDROID_MUSIC':
          _dio.options.headers['User-Agent'] = androidUserAgent;
          break;
        case 'IOS':
          _dio.options.headers['User-Agent'] = iosUserAgent;
          break;
        case 'TVHTML5':
          _dio.options.headers['User-Agent'] = tvUserAgent;
          break;
        default:
          _dio.options.headers['User-Agent'] = androidUserAgent; // fallback
      }
    }

    try {
      final response = await _dio.post(endpoint, data: body);
      return response.data;
    } catch (e) {
      debugPrint('InnerTube API $endpoint Error: $e');
      rethrow;
    }
  }

  Future<List<YouTubeSong>> search(String query) async {
    await _rateLimiter.throttle();
    
    // Use the universal request method with WEB_REMIX context
    final body = webContext;
    body['query'] = query;
    body['params'] = "EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D"; 

    try {
      // Use web user agent for web context searches
      final response = await _postRequest('/search', body, customUserAgent: webUserAgent);
      return _parseSearchResults(response);
    } catch (e) {
      debugPrint('InnerTube Search Error: $e');
      return [];
    }
  }

  Future<List<YouTubeSong>> searchWithContinuation(String query, String? continuation) async {
    await _rateLimiter.throttle();
    
    final body = Map<String, dynamic>.from(webContext);
    if (continuation != null) {
      body['continuation'] = continuation;
    } else {
      body['query'] = query;
      body['params'] = "EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D"; 
    }

    try {
      final response = await _postRequest('/search', body);
      final result = _parseSearchResultsWithContinuation(response);
      return result.items;
    } catch (e) {
      debugPrint('InnerTube Search Error: $e');
      return [];
    }
  }

  List<YouTubeSong> _parseSearchResults(Map<String, dynamic> data) {
    final results = <YouTubeSong>[];

    try {
      var contents = data['contents']
          ?['tabbedSearchResultsRenderer']
          ?['tabs']?[0]
          ?['tabRenderer']
          ?['content']
          ?['sectionListRenderer']
          ?['contents'];

      if (contents == null) {
        contents = data['contents']?['sectionListRenderer']?['contents'];
      }

      if (contents == null || contents is! List) {
        return [];
      }

      for (final section in contents) {
        final musicShelf = section['musicShelfRenderer'];
        if (musicShelf != null) {
          final items = musicShelf['contents'];
          if (items is List) {
            // Use the new parser to extract songs
            results.addAll(RendererParser.extractSongs(items));
          }
        }
      }
    } catch (e) {
      debugPrint('Parsing Error: $e');
    }
    return results;
  }

  ({List<YouTubeSong> items, String? continuation}) _parseSearchResultsWithContinuation(Map<String, dynamic> data) {
    final results = <YouTubeSong>[];
    String? nextContinuation;

    try {
      var contents = data['contents']
          ?['tabbedSearchResultsRenderer']
          ?['tabs']?[0]
          ?['tabRenderer']
          ?['content']
          ?['sectionListRenderer']
          ?['contents'];

      if (contents == null) {
        contents = data['contents']?['sectionListRenderer']?['contents'];
      }

      if (contents is List) {
        for (final section in contents) {
          final musicShelf = section['musicShelfRenderer'];
          if (musicShelf != null) {
            final items = musicShelf['contents'];
            if (items is List) {
              results.addAll(RendererParser.extractSongs(items));
            }
            
            // Look for continuation in the shelf
            final continuationData = musicShelf['continuations']?[0]?['nextContinuationData'] ??
                                   musicShelf['continuations']?[0]?['infiniteScrollContinuationData'];
            if (continuationData != null) {
              nextContinuation = continuationData['continuation'];
            }
          }
        }
      }
      
      // Also check at the top level for continuation
      if (nextContinuation == null) {
        final topContinuation = data['onResponseReceivedCommands']?[0]?['appendContinuationItemsAction']?['continuationItem']?['continuationEndpoint']?['continuationCommand']?['token'];
        if (topContinuation != null) {
          nextContinuation = topContinuation;
        }
      }
    } catch (e) {
      debugPrint('Parsing Error: $e');
    }
    
    return (items: results, continuation: nextContinuation);
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
    const String mobileAgent = 'com.google.android.apps.youtube.music/6.33.51 (Linux; U; Android 11; US) gzip';
    try {
      debugPrint('[InnerTube] Trying ANDROID_MUSIC for: $videoId');
      final url = await _getStreamUrl(
        videoId, 
        androidMusicContext, 
        options: Options(headers: {'User-Agent': mobileAgent}),
      );
      if (url != null) return {'url': url, 'agent': mobileAgent};
    } catch (e) {
      debugPrint('[InnerTube] ANDROID_MUSIC error: $e');
    }
    return null;
  }

  Future<Map<String, String>?> _tryTVHTML5(String videoId) async {
    const String tvAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36';
    try {
      debugPrint('[InnerTube] Trying TVHTML5 for: $videoId');
      final url = await _getStreamUrl(
        videoId, 
        tvHtml5Context, 
        options: Options(headers: {'User-Agent': tvAgent}),
      );
      if (url != null) return {'url': url, 'agent': tvAgent};
    } catch (e) {
      debugPrint('[InnerTube] TVHTML5 error: $e');
    }
    return null;
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

  Future<String?> _getStreamUrl(String videoId, Map<String, dynamic> contextBody, {Options? options}) async {
    contextBody['videoId'] = videoId;
    contextBody['playbackContext'] = {
      'contentPlaybackContext': {
        'signatureTimestamp': 20380 // Updated for 2024+
      }
    };

    try {
      final response = await _dio.post('/player', data: contextBody, options: options);
      
      final playabilityStatus = response.data['playabilityStatus'];
      if (playabilityStatus != null && playabilityStatus['status'] != 'OK') {
        debugPrint('[InnerTube] Playability Status: ${playabilityStatus['status']} for $videoId');
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
      debugPrint('[InnerTube] Auth: No active session. Personalization disabled.');
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
    await _googleAuthService.logout();
    _dio.options.headers.remove('Cookie');
  }

  Future<bool> isLoggedIn() async {
    final cookies = await _googleAuthService.getCookies();
    if (cookies != null && cookies.isNotEmpty) {
      return true;
    }
    // Also check if user is logged in via GoogleAuthService
    return _googleAuthService.isSignedIn();
  }

  Future<Map<String, dynamic>> getHomeData() async {
    await _rateLimiter.throttle();
    
    final body = Map<String, dynamic>.from(androidMusicContext);
    body['browseId'] = 'FEmusic_home';

    try {
      final response = await _postRequest('/browse', body);
      return response;
    } catch (e) {
      debugPrint('InnerTube Home Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNext(String videoId) async {
    await _rateLimiter.throttle();
    
    final body = Map<String, dynamic>.from(webContext);
    body['videoId'] = videoId;
    body['context']['client']['clientScreen'] = 'SEARCH';

    try {
      final response = await _postRequest('/next', body);
      return response;
    } catch (e) {
      debugPrint('InnerTube Next Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRadio({required String videoId}) async {
    await _rateLimiter.throttle();
    
    final body = Map<String, dynamic>.from(androidMusicContext);
    body['continuation'] = videoId;
    body['context']['client']['clientScreen'] = 'MUSIC_REMIX';

    try {
      final response = await _postRequest('/browse', body);
      return response;
    } catch (e) {
      debugPrint('InnerTube Radio Error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLibraryPlaylists() async {
    await _rateLimiter.throttle();
    await _addAuthHeaders();
    final body = Map<String, dynamic>.from(webContext);
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
      final sections = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]
          ?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];

      if (sections == null || sections is! List) return [];

      for (var section in sections) {
        final grid = section['musicCarouselShelfRenderer'] ?? section['gridRenderer'];
        if (grid == null) continue;

        final items = grid['items'] as List?;
        if (items != null) {
          for (var item in items) {
            final renderer = item['musicTwoColumnItemRenderer'] ?? item['musicResponsiveListItemRenderer'];
            if (renderer != null) {
              final title = renderer['title']?['runs']?[0]?['text'];
              final browseId = renderer['navigationEndpoint']?['browseEndpoint']?['browseId'];
              final type = renderer['navigationEndpoint']?['browseEndpoint']?['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType'];
              
              if (title != null && browseId != null && type == 'MUSIC_PAGE_TYPE_PLAYLIST') {
                final thumbnails = (renderer['thumbnailRenderer'] ?? renderer['thumbnail'])?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
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
    final body = Map<String, dynamic>.from(webContext);
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
      final contents = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]
          ?['tabRenderer']?['content']?['sectionListRenderer']?['contents']?[0]
          ?['musicPlaylistShelfRenderer']?['contents'];

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

  List<YouTubeSong> _parseNextResults(Map<String, dynamic> data) {
    final results = <YouTubeSong>[];
    try {
      final contents = data['contents']?['singleColumnMusicWatchNextResultsRenderer']
          ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs']?[0]
          ?['tabRenderer']?['content']?['musicQueueRenderer']?['content']
          ?['playlistPanelRenderer']?['contents'];

      if (contents == null || contents is! List) return [];

      // Skip the first item as it's the currently playing song
      for (int i = 1; i < contents.length; i++) {
        final item = contents[i];
        final mrlir = item['playlistPanelVideoRenderer'] ??
                      item['playlistPanelVideoWrapperRenderer']?['primaryRenderer']?['playlistPanelVideoRenderer'];
        
        if (mrlir != null) {
          final title = mrlir['title']?['runs']?[0]?['text'];
          final longBylineText = mrlir['longBylineText']?['runs']?[0]?['text'] ?? "Unknown";
          final videoId = mrlir['videoId'];
          
          final thumbnails = mrlir['thumbnail']?['thumbnails'] as List?;
          String thumbUrl = '';
          if (thumbnails != null && thumbnails.isNotEmpty) {
            thumbUrl = thumbnails.last['url'];
          }

          if (title != null && videoId != null) {
            results.add(YouTubeSong(
              videoId: videoId,
              title: title,
              artist: longBylineText,
              thumbnailUrl: thumbUrl,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Parsing Next Results Error: $e');
    }
    return results;
  }

  YouTubeSong? _parseSingleSong(Map<String, dynamic> mrlir) {
    try {
      final title = mrlir['flexColumns']?[0]['musicResponsiveListItemFlexColumnRenderer']
          ['text']?['runs']?[0]?['text'] ?? mrlir['title']?['runs']?[0]?['text'];
      
      if (title == null) return null;

      String artist = "Unknown";
      final flexCol1 = mrlir['flexColumns']?[1]['musicResponsiveListItemFlexColumnRenderer'];
      if (flexCol1 != null) {
        final runs = flexCol1['text']?['runs'] as List?;
        if (runs != null && runs.isNotEmpty) artist = runs[0]['text'];
      } else {
        artist = mrlir['subtitle']?['runs']?[0]?['text'] ?? "Unknown";
      }

      String? videoId;
      final playButton = mrlir['overlay']?['musicItemThumbnailOverlayRenderer']
          ?['content']?['musicPlayButtonRenderer'];
      videoId = playButton?['playNavigationEndpoint']?['watchEndpoint']?['videoId'] ??
                mrlir['navigationEndpoint']?['watchEndpoint']?['videoId'] ??
                mrlir['onTap']?['watchEndpoint']?['videoId'];

      if (videoId == null) return null;

      final thumbnails = (mrlir['thumbnail']?['musicThumbnailRenderer'] ?? mrlir['thumbnailRenderer']?['musicThumbnailRenderer'])
          ?['thumbnail']?['thumbnails'] as List?;
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
      return null;
    }
  }
}