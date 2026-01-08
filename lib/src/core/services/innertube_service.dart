import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/youtube_song.dart';

class InnerTubeService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  InnerTubeService()
      : _storage = const FlutterSecureStorage(),
        _dio = Dio(BaseOptions(
          baseUrl: 'https://music.youtube.com/youtubei/v1',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
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
          "clientVersion": "1.20230102.01.00", 
          "hl": "uk", 
          "gl": "UA",
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
    final cookies = await _storage.read(key: 'user_cookies');
    if (cookies != null) {
      _dio.options.headers['Cookie'] = cookies;
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
}
