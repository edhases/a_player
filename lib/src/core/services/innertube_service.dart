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
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:88.0) Gecko/20100101 Firefox/88.0',
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
    body['params'] = "EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D"; // Filter: Songs only

    try {
      final response = await _dio.post(
        '/search', 
        data: body,
      );

      return _parseSearchResults(response.data);
    } catch (e) {
      print('InnerTube Search Error: $e');
      return [];
    }
  }

  Future<String?> getSongUrl(String videoId) async {
    await _addAuthHeaders(); 
    
    // Strategy 1: Try ANDROID_MUSIC (Best quality)
    String? url = await _getStreamUrl(videoId, _androidContextBody());
    
    // Strategy 2: IOS (Fallback for some restrictions)
    if (url == null) {
      print('ANDROID_MUSIC failed, trying IOS fallback...');
      url = await _getStreamUrl(videoId, _iosContextBody());
    }

    // Strategy 3: TVHTML5 (Most permissive, solves LOGIN_REQUIRED)
    if (url == null) {
       print('IOS failed, trying TVHTML5 fallback...');
       url = await _getStreamUrl(videoId, _tvHtml5ContextBody());
    }

    return url;
  }

  Future<String?> _getStreamUrl(String videoId, Map<String, dynamic> contextBody) async {
    contextBody['videoId'] = videoId;
    contextBody['playbackContext'] = {
      'contentPlaybackContext': {
        'signatureTimestamp': 19595 
      }
    };

    try {
      final response = await _dio.post('/player', data: contextBody);
      
      final playabilityStatus = response.data['playabilityStatus'];
      if (playabilityStatus != null && playabilityStatus['status'] != 'OK') {
        // Log status but don't print error to avoid clutter, as we have fallbacks
        // print('Playability Status: ${playabilityStatus['status']}');
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
      print('InnerTube Player Error: $e');
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
      final contents = data['contents']
          ?['tabbedSearchResultsRenderer']
          ?['tabs']?[0]
          ?['tabRenderer']
          ?['content']
          ?['sectionListRenderer']
          ?['contents'];

      if (contents == null || contents is! List) return [];

      for (final section in contents) {
        final musicShelf = section['musicShelfRenderer'];
        if (musicShelf != null) {
          final items = musicShelf['contents'];
          if (items is List) {
            for (final item in items) {
              final mrlir = item['musicResponsiveListItemRenderer'];
              if (mrlir != null) {
                try {
                  // Title
                  final title = mrlir['flexColumns'][0]['musicResponsiveListItemFlexColumnRenderer']
                      ['text']['runs'][0]['text'] as String;

                  // Artist
                  final secondaryText = mrlir['flexColumns'][1]['musicResponsiveListItemFlexColumnRenderer']
                      ['text']['runs'] as List;
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

                  // ID
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

                  // Thumbnail
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
                  // Skip bad item
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Parsing Error: $e');
    }
    return results;
  }
}
