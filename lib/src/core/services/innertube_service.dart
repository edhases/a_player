import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/youtube_song.dart';
import 'google_auth_service.dart';
import 'rate_limiter.dart';

import '../../data/datasources/app_database.dart';

class InnerTubeService {
  final Dio _dio;
  final GoogleAuthService _googleAuthService;
  final RateLimiter _rateLimiter = RateLimiter();
  final AppDatabase _db;

  InnerTubeService({GoogleAuthService? googleAuthService, AppDatabase? db})
      : _googleAuthService = googleAuthService ?? GetIt.I<GoogleAuthService>(),
        _db = db ?? GetIt.I<AppDatabase>(),
        _dio = Dio(BaseOptions(
          baseUrl: 'https://music.youtube.com/youtubei/v1',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
            'Referer': 'https://music.youtube.com/',
            'Content-Type': 'application/json',
            'X-Goog-AuthUser': '0',
            'Origin': 'https://music.youtube.com',
          },
        ));

  Map<String, dynamic> _webContextBody() {
    return {
      "context": {
        "client": {
          "clientName": "WEB_REMIX",
          "clientVersion": "1.20250101.01.00", 
          "hl": "en", // Changed from uk to en according to spec
          "gl": "US", // Changed from UA to US according to spec
        }
      }
    };
  }

  Map<String, dynamic> _androidContextBody() {
    return {
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
  }

  Map<String, dynamic> _iosContextBody() {
    return {
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

  Future<List<YouTubeSong>> search(String query) async {
    await _rateLimiter.throttle();
    await _addAuthHeaders();

    final body = _webContextBody();
    body['query'] = query;
    body['params'] = "EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D"; 

    try {
      final response = await _dio.post('/search', data: body);
      return _parseSearchResults(response.data);
    } catch (e) {
      debugPrint('InnerTube Search Error: $e');
      return [];
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
    const String mobileAgent = 'com.google.android.apps.youtube.music/6.33.51 (Linux; U; Android 11; US) gzip';
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
    const String tvAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36';
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

  Future<void> _addAuthHeaders() async {
    final cookies = await _googleAuthService.getCookies();
    if (cookies != null && cookies.isNotEmpty) {
      debugPrint('[InnerTube] Auth: Active session found (${cookies.length} chars)');
      _dio.options.headers['Cookie'] = cookies;
      
      // Also add other auth headers
      final authHeaders = await _googleAuthService.getAuthHeaders();
      _dio.options.headers.addAll({
        'User-Agent': authHeaders['User-Agent'] ?? _dio.options.headers['User-Agent'],
        'Accept-Language': authHeaders['Accept-Language'] ?? _dio.options.headers['Accept-Language'],
      });
    } else {
      debugPrint('[InnerTube] Auth: No active session. Personalization disabled.');
      _dio.options.headers.remove('Cookie');
    }
  }

  Future<void> logout() async {
    debugPrint('[InnerTube] Performing logout (clearing cookies)');
    await _googleAuthService.signOut();
    _dio.options.headers.remove('Cookie');
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

      if (contents == null) {
         contents = data['contents']
            ?['singleColumnSearchResultsRenderer']
            ?['tabs']?[0]
            ?['tabRenderer']
            ?['content']
            ?['sectionListRenderer']
            ?['contents'];
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
                  final title = mrlir['flexColumns'][0]['musicResponsiveListItemFlexColumnRenderer']
                      ['text']['runs'][0]['text'] as String;

                  final secondaryText = mrlir['flexColumns'][1]['musicResponsiveListItemFlexColumnRenderer']
                      ['text']['runs'] as List;
                  String artist = "Unknown";
                   if (secondaryText.isNotEmpty) {
                    for (var run in secondaryText) {
                      final text = run['text'];
                      if (text != ' • ' && !text.contains('views') && !text.contains('plays') && !text.contains(':')) { 
                        artist = text;
                        break; 
                      }
                    }
                  }

                  String? videoId;
                  final playButton = mrlir['overlay']?['musicItemThumbnailOverlayRenderer']
                      ?['content']?['musicPlayButtonRenderer'];
                  videoId = playButton?['playNavigationEndpoint']?['watchEndpoint']?['videoId'];

                  final playlistItemData = mrlir['playlistItemData'];
                  if (videoId == null && playlistItemData != null && playlistItemData['videoId'] != null) {
                    videoId = playlistItemData['videoId'];
                  }
                  
                  if (videoId == null) {
                     videoId = mrlir['navigationItem']?['watchEndpoint']?['videoId'];
                  }

                  final thumbnails = mrlir['thumbnail']?['musicThumbnailRenderer']
                      ?['thumbnail']?['thumbnails'] as List?;
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
                } catch (e) {
                }
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

  Future<List<Map<String, dynamic>>> getHomeData() async {
    // Check the cache first
    final cached = await _db.getCachedHomeData();
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < const Duration(hours: 6)) {
      debugPrint('[InnerTubeService] Using cached home data.');
      return cached.data;
    }

    // If cache is old or doesn't exist, fetch from network
    await _rateLimiter.throttle();
    await _addAuthHeaders();
    final body = _webContextBody();
    body['browseId'] = "FEmusic_home";

    try {
      final response = await _dio.post('/browse', data: body);
      final freshData = _parseHomeData(response.data);

      // Cache the new data
      if (freshData.isNotEmpty) {
        await _db.cacheHomeData(freshData);
        debugPrint('[InnerTubeService] Cached fresh home data.');
      }

      return freshData;
    } catch (e) {
      debugPrint('InnerTube getHomeData Error: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _parseHomeData(Map<String, dynamic> data) {
    final sections = <Map<String, dynamic>>[];
    try {
      final contents = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]
          ?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];

      if (contents == null || contents is! List) return [];

      for (var section in contents) {
        final shelf = section['musicShelfRenderer'] ?? 
                      section['musicCarouselShelfRenderer'] ??
                      section['gridRenderer'];
        if (shelf == null) continue;

        String title = "Recommended";
        final titleRuns = shelf['title']?['runs'] as List?;
        if (titleRuns != null && titleRuns.isNotEmpty) {
           title = titleRuns[0]['text'];
        }

        final items = <YouTubeSong>[];
        final shelfContents = shelf['contents'] ?? shelf['items'];
        if (shelfContents is List) {
          for (var item in shelfContents) {
            final mrlir = item['musicResponsiveListItemRenderer'] ?? 
                          item['musicTwoColumnItemRenderer'] ??
                          item['musicMultiRowListItemRenderer'];
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
    } catch (e) {
      debugPrint('Error parsing home data: $e');
    }
    return sections;
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