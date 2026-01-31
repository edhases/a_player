import 'package:flutter/foundation.dart';

import '../../../domain/entities/youtube_song.dart';
import 'innertube_base.dart';

/// Represents a shelf of content on the home page
class HomeShelf {
  final String title;
  final List<YouTubeSong> items;
  final String? browseId;
  final String? params;

  const HomeShelf({
    required this.title,
    required this.items,
    this.browseId,
    this.params,
  });
}

/// Service for YouTube Music home feed functionality
class InnerTubeHomeService extends InnerTubeBase {
  InnerTubeHomeService({
    required super.authService,
    super.rateLimiter,
    super.logger,
    super.dio,
    super.parser,
  });

  /// Get home feed data with shelves
  Future<List<HomeShelf>> getHomeData() async {
    try {
      final body = webContextBody();
      body['browseId'] = 'FEmusic_home';

      final data = await postRequest('/browse', body);
      return _parseHomeData(data);
    } catch (e) {
      debugPrint('[InnerTubeHome] Home data failed: $e, trying web fallback');
      return _getHomeDataWebFallback();
    }
  }

  /// Web fallback for home data
  Future<List<HomeShelf>> _getHomeDataWebFallback() async {
    try {
      final body = webContextBody();
      body['browseId'] = 'FEmusic_home';

      // Add additional context for web
      (body['context'] as Map<String, dynamic>)['client']
          ['originalUrl'] = 'https://music.youtube.com/';

      final data = await postRequest('/browse', body);
      return _parseHomeData(data);
    } catch (e) {
      debugPrint('[InnerTubeHome] Web fallback also failed: $e');
      return [];
    }
  }

  /// Get home feed continuation (more shelves)
  Future<List<HomeShelf>> getHomeContinuation(String continuationToken) async {
    try {
      final data = await browseContinuation(continuationToken);
      if (data == null) return [];

      return _parseHomeData(data);
    } catch (e) {
      debugPrint('[InnerTubeHome] Home continuation failed: $e');
      return [];
    }
  }

  /// Parse home data from API response
  List<HomeShelf> _parseHomeData(Map<String, dynamic> data) {
    final List<HomeShelf> shelves = [];

    try {
      // Path 1: Standard browse response
      var contents = data['contents']?['singleColumnBrowseResultsRenderer']
          ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']
          ?['contents'] as List?;

      // Path 2: Continuation response
      contents ??= data['continuationContents']?['sectionListContinuation']
          ?['contents'] as List?;

      // Path 3: Direct section list
      contents ??=
          data['contents']?['sectionListRenderer']?['contents'] as List?;

      if (contents == null) {
        debugPrint('[InnerTubeHome] No contents found in response');
        return [];
      }

      for (final section in contents) {
        final shelf = _processShelf(section);
        if (shelf != null && shelf.items.isNotEmpty) {
          shelves.add(shelf);
        }
      }

      debugPrint('[InnerTubeHome] Parsed ${shelves.length} shelves');
    } catch (e) {
      debugPrint('[InnerTubeHome] Error parsing home data: $e');
    }

    return shelves;
  }

  /// Process a single shelf section
  HomeShelf? _processShelf(Map<String, dynamic> section) {
    try {
      // Music Carousel Shelf (most common)
      var shelfRenderer = section['musicCarouselShelfRenderer'];

      // Music Immersive Carousel Shelf
      shelfRenderer ??= section['musicImmersiveCarouselShelfRenderer'];

      // Music Description Shelf (skip)
      if (section.containsKey('musicDescriptionShelfRenderer')) {
        return null;
      }

      if (shelfRenderer == null) return null;

      // Extract title
      String title = '';
      final titleRuns =
          shelfRenderer['header']?['musicCarouselShelfBasicHeaderRenderer']
                  ?['title']?['runs'] as List? ??
              shelfRenderer['header']?['musicImmersiveCarouselShelfRenderer']
                  ?['title']?['runs'] as List?;

      if (titleRuns != null && titleRuns.isNotEmpty) {
        title = titleRuns[0]['text']?.toString() ?? '';
      }

      if (title.isEmpty) return null;

      // Extract browse endpoint for "See All"
      String? browseId;
      String? params;
      final moreButton = shelfRenderer['header']
              ?['musicCarouselShelfBasicHeaderRenderer']?['moreContentButton']
          ?['buttonRenderer']?['navigationEndpoint']?['browseEndpoint'];
      if (moreButton != null) {
        browseId = moreButton['browseId'] as String?;
        params = moreButton['params'] as String?;
      }

      // Parse items
      final List<YouTubeSong> items = [];
      final contents = shelfRenderer['contents'] as List?;

      if (contents != null) {
        for (final item in contents) {
          final song = _parseShelfItem(item);
          if (song != null) {
            items.add(song);
          }
        }
      }

      return HomeShelf(
        title: title,
        items: items,
        browseId: browseId,
        params: params,
      );
    } catch (e) {
      debugPrint('[InnerTubeHome] Error processing shelf: $e');
      return null;
    }
  }

  /// Parse a shelf item (carousel or list item)
  YouTubeSong? _parseShelfItem(Map<String, dynamic> item) {
    // Music Two Row Item Renderer (common in carousels)
    final mtrir = item['musicTwoRowItemRenderer'];
    if (mtrir != null) {
      return _parseTwoRowItem(mtrir);
    }

    // Music Responsive List Item Renderer
    final mrlir = item['musicResponsiveListItemRenderer'];
    if (mrlir != null) {
      return parser.parseSingleSong(mrlir);
    }

    return null;
  }

  /// Parse two-row item (album, playlist, artist in carousel)
  YouTubeSong? _parseTwoRowItem(Map<String, dynamic> mtrir) {
    try {
      final title = mtrir['title']?['runs']?[0]?['text'] as String? ?? '';
      if (title.isEmpty) return null;

      // Subtitle (artist, type, etc.)
      String subtitle = '';
      String? artistId;
      final subtitleRuns = mtrir['subtitle']?['runs'] as List?;
      if (subtitleRuns != null && subtitleRuns.isNotEmpty) {
        final parts = <String>[];
        
        // Category labels that should be skipped
        const categoryLabels = {
          'Single', 'Album', 'EP', 'Playlist', 'Song', 'Video',
          'Сингл', 'Альбом', 'Плейлист', 'Пісня', 'Відео',
          'Artist', 'Виконавець', 'Channel', 'Канал',
        };
        
        for (var run in subtitleRuns) {
          final text = run['text']?.toString() ?? '';
          if (text.isEmpty) continue;
          
          // Skip separators but continue parsing
          if (text == ' • ' || text == '•') {
            // If we already have artist parts, we can stop
            if (parts.isNotEmpty) break;
            continue;
          }
          
          // Skip category labels
          if (categoryLabels.contains(text)) continue;
          
          // Stop at duration patterns
          if (RegExp(r'^\d+:\d+').hasMatch(text)) break;
          
          parts.add(text);
          if (artistId == null) {
            final browseId =
                run['navigationEndpoint']?['browseEndpoint']?['browseId'];
            if (browseId != null &&
                (browseId.startsWith('UC') || browseId.startsWith('UA'))) {
              artistId = browseId;
            }
          }
        }
        subtitle = parts.join('').trim();
      }

      // Thumbnail
      String thumbnail = '';
      final thumbs = mtrir['thumbnailRenderer']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'] as List?;
      if (thumbs != null && thumbs.isNotEmpty) {
        thumbnail = thumbs.last['url'] as String? ?? '';
      }

      // Navigation endpoint
      String? videoId;
      String? browseId;
      String? playlistId;

      final navEndpoint = mtrir['navigationEndpoint'];
      if (navEndpoint != null) {
        final watchEndpoint = navEndpoint['watchEndpoint'];
        if (watchEndpoint != null) {
          videoId = watchEndpoint['videoId'] as String?;
          playlistId = watchEndpoint['playlistId'] as String?;
        }

        final browseEndpoint = navEndpoint['browseEndpoint'];
        if (browseEndpoint != null) {
          browseId = browseEndpoint['browseId'] as String?;
        }
      }

      final isPlaylist = videoId == null && (browseId != null || playlistId != null);

      return YouTubeSong(
        videoId: videoId ?? browseId ?? playlistId ?? '',
        title: title,
        artist: subtitle.isNotEmpty ? subtitle : 'Unknown',
        thumbnailUrl: thumbnail,
        artistId: artistId,
        playlistId: playlistId ?? browseId,
        isPlaylist: isPlaylist,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get "Charts" or specific category
  Future<List<HomeShelf>> getCharts() async {
    try {
      final body = webContextBody();
      body['browseId'] = 'FEmusic_charts';

      final data = await postRequest('/browse', body);
      return _parseHomeData(data);
    } catch (e) {
      debugPrint('[InnerTubeHome] Charts failed: $e');
      return [];
    }
  }

  /// Get "New Releases"
  Future<List<HomeShelf>> getNewReleases() async {
    try {
      final body = webContextBody();
      body['browseId'] = 'FEmusic_new_releases';

      final data = await postRequest('/browse', body);
      return _parseHomeData(data);
    } catch (e) {
      debugPrint('[InnerTubeHome] New releases failed: $e');
      return [];
    }
  }
}
