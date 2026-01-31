import 'package:flutter/foundation.dart';

import '../../../domain/entities/youtube_song.dart';
import 'innertube_base.dart';

/// Service for YouTube Music search functionality
class InnerTubeSearchService extends InnerTubeBase {
  InnerTubeSearchService({
    required super.authService,
    super.rateLimiter,
    super.logger,
    super.dio,
    super.parser,
  });

  /// Search YouTube Music with multiple strategies for better results
  Future<List<YouTubeSong>> search(
    String query, {
    String filter = 'songs',
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) return [];

    // Strategy 1: Filtered Search (preferred for specific categories)
    final filteredResults = await _filteredSearch(query, filter, limit);
    if (filteredResults.isNotEmpty) {
      return filteredResults;
    }

    // Strategy 2: General Search (fallback)
    return _generalSearch(query, limit);
  }

  /// Filtered search (songs, videos, albums, artists, playlists)
  Future<List<YouTubeSong>> _filteredSearch(
    String query,
    String filter,
    int limit,
  ) async {
    try {
      final body = webContextBody();
      body['query'] = query;

      // Filter params for different content types
      final filterParams = _getFilterParams(filter);
      if (filterParams != null) {
        body['params'] = filterParams;
      }

      final data = await postRequest('/search', body);
      return _parseSearchResults(data, limit);
    } catch (e) {
      debugPrint('[InnerTubeSearch] Filtered search failed: $e');
      return [];
    }
  }

  /// General search without filters
  Future<List<YouTubeSong>> _generalSearch(String query, int limit) async {
    try {
      final body = webContextBody();
      body['query'] = query;

      final data = await postRequest('/search', body);
      return _parseSearchResults(data, limit);
    } catch (e) {
      debugPrint('[InnerTubeSearch] General search failed: $e');
      return [];
    }
  }

  /// Get search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final body = webContextBody();
      body['input'] = query;

      final data = await postRequest('/music/get_search_suggestions', body);

      final List<String> suggestions = [];
      final contents = data['contents'] as List?;

      if (contents != null) {
        for (var item in contents) {
          final renderer =
              item['searchSuggestionsSectionRenderer']?['contents'] as List?;
          if (renderer != null) {
            for (var suggestion in renderer) {
              final text = suggestion['searchSuggestionRenderer']
                      ?['suggestion']?['runs']?[0]?['text'] as String? ??
                  suggestion['searchSuggestionRenderer']?['navigationEndpoint']
                      ?['searchEndpoint']?['query'] as String?;
              if (text != null && text.isNotEmpty) {
                suggestions.add(text);
              }
            }
          }
        }
      }

      return suggestions;
    } catch (e) {
      debugPrint('[InnerTubeSearch] Suggestions failed: $e');
      return [];
    }
  }

  /// Parse search results from API response
  List<YouTubeSong> _parseSearchResults(
    Map<String, dynamic> data,
    int limit,
  ) {
    final List<YouTubeSong> results = [];

    try {
      // Navigate to search results content
      final tabs = data['contents']?['tabbedSearchResultsRenderer']?['tabs']
              as List? ??
          [];

      if (tabs.isEmpty) {
        // Fallback: Direct content path
        final contents = data['contents']?['sectionListRenderer']?['contents']
                as List? ??
            [];
        _parseSearchContents(contents, results, limit);
        return results;
      }

      for (final tab in tabs) {
        final tabRenderer = tab['tabRenderer'];
        if (tabRenderer?['selected'] != true) continue;

        final contents = tabRenderer['content']?['sectionListRenderer']
            ?['contents'] as List?;
        if (contents != null) {
          _parseSearchContents(contents, results, limit);
        }
        break;
      }
    } catch (e) {
      debugPrint('[InnerTubeSearch] Error parsing search results: $e');
    }

    return results;
  }

  /// Parse search content sections
  void _parseSearchContents(
    List contents,
    List<YouTubeSong> results,
    int limit,
  ) {
    for (final section in contents) {
      if (results.length >= limit) break;

      final shelfContents = section['musicShelfRenderer']?['contents']
              as List? ??
          section['musicCardShelfRenderer']?['contents'] as List? ??
          [];

      // Check for top result card
      final topResult = section['musicCardShelfRenderer'];
      if (topResult != null) {
        final song = _parseTopResultCard(topResult);
        if (song != null) {
          results.add(song);
        }
      }

      for (final item in shelfContents) {
        if (results.length >= limit) break;

        final mrlir = item['musicResponsiveListItemRenderer'];
        if (mrlir != null) {
          final song = parser.parseSingleSong(mrlir);
          if (song != null) {
            results.add(song);
          }
        }
      }
    }
  }

  /// Parse top result card (featured result)
  YouTubeSong? _parseTopResultCard(Map<String, dynamic> cardRenderer) {
    try {
      final title =
          cardRenderer['title']?['runs']?[0]?['text'] as String? ?? '';
      if (title.isEmpty) return null;

      // Get video ID from watch endpoint
      String? videoId;
      final watchEndpoint =
          cardRenderer['onTap']?['watchEndpoint'] as Map<String, dynamic>?;
      if (watchEndpoint != null) {
        videoId = watchEndpoint['videoId'] as String?;
      }

      // Fallback: browse endpoint
      String? browseId;
      final browseEndpoint = cardRenderer['onTap']?['browseEndpoint'];
      if (browseEndpoint != null) {
        browseId = browseEndpoint['browseId'] as String?;
      }

      if (videoId == null && browseId == null) return null;

      // Parse subtitle for artist
      String artist = 'Unknown';
      String? artistId;
      final subtitleRuns = cardRenderer['subtitle']?['runs'] as List?;
      if (subtitleRuns != null && subtitleRuns.isNotEmpty) {
        final artistParts = <String>[];
        
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
            if (artistParts.isNotEmpty) break;
            continue;
          }
          
          // Skip category labels
          if (categoryLabels.contains(text)) continue;
          
          // Stop at duration patterns
          if (RegExp(r'^\d+:\d+').hasMatch(text)) break;
          
          artistParts.add(text);
          artistId ??= run['navigationEndpoint']?['browseEndpoint']?['browseId'];
        }
        artist = artistParts.join('').trim();
        if (artist.isEmpty) artist = 'Unknown';
      }

      // Thumbnail
      String thumbnail = '';
      final thumbs = cardRenderer['thumbnail']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'] as List?;
      if (thumbs != null && thumbs.isNotEmpty) {
        thumbnail = thumbs.last['url'] as String? ?? '';
      }

      return YouTubeSong(
        videoId: videoId ?? browseId ?? '',
        title: title,
        artist: artist,
        thumbnailUrl: thumbnail,
        artistId: artistId,
        isPlaylist: videoId == null && browseId != null,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get filter params for different content types
  String? _getFilterParams(String filter) {
    switch (filter.toLowerCase()) {
      case 'songs':
        return 'EgWKAQIIAWoQEAMQBBAJEA4QChAFEBEQEA%3D%3D';
      case 'videos':
        return 'EgWKAQIQAWoQEAMQBBAJEA4QChAFEBEQEA%3D%3D';
      case 'albums':
        return 'EgWKAQIYAWoQEAMQBBAJEA4QChAFEBEQEA%3D%3D';
      case 'artists':
        return 'EgWKAQIgAWoQEAMQBBAJEA4QChAFEBEQEA%3D%3D';
      case 'playlists':
        return 'EgWKAQIoAWoQEAMQBBAJEA4QChAFEBEQEA%3D%3D';
      case 'community_playlists':
        return 'EgeKAQQoAEABahAQAxAEEAkQDhAKEAUQERAQ';
      default:
        return null;
    }
  }

  /// Search for artist by name and return their browseId
  Future<String?> findArtistId(String artistName) async {
    if (artistName.trim().isEmpty) return null;

    try {
      debugPrint('[InnerTubeSearch] Searching for artist: $artistName');
      
      final body = webContextBody();
      body['query'] = artistName;
      body['params'] = _getFilterParams('artists');

      final data = await postRequest('/search', body);
      
      // Parse artist results
      final artistId = _findFirstArtistId(data, artistName);
      debugPrint('[InnerTubeSearch] Found artistId: $artistId');
      return artistId;
    } catch (e) {
      debugPrint('[InnerTubeSearch] Artist search failed: $e');
      return null;
    }
  }

  /// Find the first artist browseId from search results
  String? _findFirstArtistId(Map<String, dynamic> data, String targetName) {
    try {
      // Navigate to search results
      final tabs = data['contents']?['tabbedSearchResultsRenderer']?['tabs'] as List? ?? [];
      
      List<dynamic>? contents;
      if (tabs.isNotEmpty) {
        for (final tab in tabs) {
          final tabRenderer = tab['tabRenderer'];
          if (tabRenderer?['selected'] == true) {
            contents = tabRenderer['content']?['sectionListRenderer']?['contents'] as List?;
            break;
          }
        }
      } else {
        contents = data['contents']?['sectionListRenderer']?['contents'] as List?;
      }

      if (contents == null) return null;

      // Search for artist renderers
      for (final section in contents) {
        final items = section['musicShelfRenderer']?['contents'] as List? ?? 
                      section['itemSectionRenderer']?['contents'] as List? ?? [];
        
        for (final item in items) {
          final artistRenderer = item['musicResponsiveListItemRenderer'] ?? 
                                 item['musicTwoRowItemRenderer'];
          
          if (artistRenderer != null) {
            // Check if it's an artist
            final browseId = artistRenderer['navigationEndpoint']?['browseEndpoint']?['browseId'] as String?;
            if (browseId != null && browseId.startsWith('UC')) {
              // It's a channel/artist ID
              return browseId;
            }
            
            // Try to find browseId in flexColumns
            final flexColumns = artistRenderer['flexColumns'] as List?;
            if (flexColumns != null) {
              for (final col in flexColumns) {
                final runs = col['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
                if (runs != null) {
                  for (final run in runs) {
                    final navEndpoint = run['navigationEndpoint'];
                    final bid = navEndpoint?['browseEndpoint']?['browseId'] as String?;
                    if (bid != null && bid.startsWith('UC')) {
                      return bid;
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('[InnerTubeSearch] Parse artist error: $e');
      return null;
    }
  }
}
