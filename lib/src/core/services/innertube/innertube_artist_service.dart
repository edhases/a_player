import 'package:flutter/foundation.dart';

import '../../../domain/entities/youtube_song.dart';
import 'innertube_base.dart';

/// Represents artist information
class YouTubeArtist {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final String? description;
  final int? subscriberCount;

  const YouTubeArtist({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.description,
    this.subscriberCount,
  });
}

/// Service for YouTube Music artist functionality
class InnerTubeArtistService extends InnerTubeBase {
  InnerTubeArtistService({
    required super.authService,
    super.rateLimiter,
    super.logger,
    super.dio,
    super.parser,
  });

  /// Get artist info
  Future<YouTubeArtist?> getArtistInfo(String browseId) async {
    try {
      final body = webContextBody();
      body['browseId'] = browseId;

      final data = await postRequest('/browse', body);
      return _parseArtistInfo(data, browseId);
    } catch (e) {
      debugPrint('[InnerTubeArtist] Artist info error: $e');
      return null;
    }
  }

  /// Parse artist info from response
  YouTubeArtist? _parseArtistInfo(Map<String, dynamic> data, String browseId) {
    try {
      final header = data['header']?['musicImmersiveHeaderRenderer'] ??
          data['header']?['musicVisualHeaderRenderer'] ??
          data['header']?['musicHeaderRenderer'];

      if (header == null) return null;

      // Name
      final name = header['title']?['runs']?[0]?['text'] as String? ?? '';
      if (name.isEmpty) return null;

      // Thumbnail
      String? thumbnail;
      final thumbs =
          header['thumbnail']?['musicThumbnailRenderer']?['thumbnail']
              ?['thumbnails'] as List?;
      if (thumbs != null && thumbs.isNotEmpty) {
        thumbnail = thumbs.last['url'] as String?;
      }

      // Description
      String? description;
      final descRuns = header['description']?['runs'] as List?;
      if (descRuns != null) {
        description = descRuns.map((r) => r['text']).join('');
      }

      // Subscriber count
      int? subscriberCount;
      final subText =
          header['subscriptionButton']?['subscribeButtonRenderer']
              ?['subscriberCountText']?['runs']?[0]?['text'] as String?;
      if (subText != null) {
        final match = RegExp(r'[\d,\.]+').firstMatch(subText);
        if (match != null) {
          subscriberCount = int.tryParse(match.group(0)!.replaceAll(',', ''));
        }
      }

      return YouTubeArtist(
        id: browseId,
        name: name,
        thumbnailUrl: thumbnail,
        description: description,
        subscriberCount: subscriberCount,
      );
    } catch (e) {
      debugPrint('[InnerTubeArtist] Error parsing artist info: $e');
      return null;
    }
  }

  /// Get artist's top tracks
  Future<List<YouTubeSong>> getArtistTopTracks(String browseId) async {
    try {
      final body = webContextBody();
      body['browseId'] = browseId;

      final data = await postRequest('/browse', body);

      // First try to find "Songs" tab or "See All" link
      final seeAllParams = _findSeeAllParams(data, 'songs');
      if (seeAllParams != null) {
        return _fetchArtistSongsPage(browseId, seeAllParams);
      }

      // Fallback: Parse songs from artist page directly
      return _parseArtistSongs(data);
    } catch (e) {
      debugPrint('[InnerTubeArtist] Top tracks error: $e');
      return [];
    }
  }

  /// Find "See All" params for a specific section
  String? _findSeeAllParams(Map<String, dynamic> data, String sectionType) {
    try {
      // Navigate to tabs
      final tabs = data['contents']?['singleColumnBrowseResultsRenderer']
          ?['tabs'] as List?;

      if (tabs == null) return null;

      for (final tab in tabs) {
        final contents = tab['tabRenderer']?['content']?['sectionListRenderer']
            ?['contents'] as List?;

        if (contents == null) continue;

        for (final section in contents) {
          final shelfRenderer = section['musicShelfRenderer'] ??
              section['musicCarouselShelfRenderer'];

          if (shelfRenderer == null) continue;

          // Check title for section type
          final titleRuns = shelfRenderer['header']
                  ?['musicShelfBasicHeaderRenderer']?['title']?['runs'] ??
              shelfRenderer['header']?['musicCarouselShelfBasicHeaderRenderer']
                  ?['title']?['runs'] as List?;

          if (titleRuns == null) continue;

          final title = (titleRuns[0]['text'] as String? ?? '').toLowerCase();

          // Check if this is the songs section
          if (title.contains('song') ||
              title.contains('пісн') ||
              title.contains('песн')) {
            // Find "More" button
            final moreButton = shelfRenderer['header']
                    ?['musicShelfBasicHeaderRenderer']?['moreContentButton'] ??
                shelfRenderer['header']
                        ?['musicCarouselShelfBasicHeaderRenderer']
                    ?['moreContentButton'];

            if (moreButton != null) {
              final browseEndpoint = moreButton['buttonRenderer']
                  ?['navigationEndpoint']?['browseEndpoint'];

              if (browseEndpoint != null) {
                return browseEndpoint['params'] as String?;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[InnerTubeArtist] Error finding See All: $e');
    }

    return null;
  }

  /// Fetch artist songs page with params
  Future<List<YouTubeSong>> _fetchArtistSongsPage(
    String browseId,
    String params,
  ) async {
    try {
      final body = webContextBody();
      body['browseId'] = browseId;
      body['params'] = params;

      final data = await postRequest('/browse', body);

      final tracks = _parseArtistSongs(data);

      // Handle pagination
      String? continuationToken = parser.findContinuationToken(data);
      int pageCount = 0;
      const int maxPages = 10;

      while (continuationToken != null && pageCount < maxPages) {
        pageCount++;
        debugPrint('[InnerTubeArtist] Fetching continuation page $pageCount...');

        await Future.delayed(const Duration(milliseconds: 300));
        final contData = await browseContinuation(continuationToken);
        if (contData == null) break;

        final newTracks = _parseArtistSongs(contData);
        tracks.addAll(newTracks);

        continuationToken = parser.findContinuationToken(contData);
      }

      return tracks;
    } catch (e) {
      debugPrint('[InnerTubeArtist] Songs page error: $e');
      return [];
    }
  }

  /// Parse songs from artist page
  List<YouTubeSong> _parseArtistSongs(Map<String, dynamic> data) {
    final List<YouTubeSong> songs = [];

    // Find all song items recursively
    final items =
        parser.recursiveFindItems(data, 'musicResponsiveListItemRenderer');

    for (final item in items) {
      final song = parser.parseSingleSong(item);
      if (song != null && song.videoId.isNotEmpty) {
        songs.add(song);
      }
    }

    // Also check carousel items
    final carouselItems =
        parser.recursiveFindItems(data, 'musicTwoRowItemRenderer');

    for (final item in carouselItems) {
      final song = _parseTwoRowItem(item);
      if (song != null && song.videoId.isNotEmpty && !song.isPlaylist) {
        songs.add(song);
      }
    }

    return songs;
  }

  /// Parse two-row item (from carousel)
  YouTubeSong? _parseTwoRowItem(Map<String, dynamic> mtrir) {
    try {
      final title = mtrir['title']?['runs']?[0]?['text'] as String? ?? '';
      if (title.isEmpty) return null;

      // Subtitle
      String artist = 'Unknown';
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
        artist = parts.join('').trim();
        if (artist.isEmpty) artist = 'Unknown';
      }

      // Thumbnail
      String thumbnail = '';
      final thumbs = mtrir['thumbnailRenderer']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'] as List?;
      if (thumbs != null && thumbs.isNotEmpty) {
        thumbnail = thumbs.last['url'] as String? ?? '';
      }

      // Navigation
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

      final isPlaylist =
          videoId == null && (browseId != null || playlistId != null);

      return YouTubeSong(
        videoId: videoId ?? browseId ?? playlistId ?? '',
        title: title,
        artist: artist,
        thumbnailUrl: thumbnail,
        artistId: artistId,
        playlistId: playlistId ?? browseId,
        isPlaylist: isPlaylist,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get artist's albums
  Future<List<YouTubeSong>> getArtistAlbums(String browseId) async {
    try {
      final body = webContextBody();
      body['browseId'] = browseId;

      final data = await postRequest('/browse', body);

      // Find albums section and parse
      final albums = <YouTubeSong>[];
      final items =
          parser.recursiveFindItems(data, 'musicTwoRowItemRenderer');

      for (final item in items) {
        final song = _parseTwoRowItem(item);
        if (song != null && song.isPlaylist) {
          albums.add(song);
        }
      }

      return albums;
    } catch (e) {
      debugPrint('[InnerTubeArtist] Albums error: $e');
      return [];
    }
  }

  /// Get radio tracks based on a video
  Future<List<YouTubeSong>> getRadioTracks(String videoId) async {
    try {
      final body = webContextBody();
      body['videoId'] = videoId;
      body['enablePersistentPlaylistPanel'] = true;
      body['isAudioOnly'] = true;
      body['tunerSettingValue'] = 'AUTOMIX_SETTING_NORMAL';
      body['playlistId'] = 'RDAMVM$videoId';

      final data = await postRequest('/next', body);

      final List<YouTubeSong> tracks = [];

      // Parse playlist panel
      final tabs = data['contents']?['singleColumnMusicWatchNextResultsRenderer']
          ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs']
          as List?;

      if (tabs != null) {
        for (final tab in tabs) {
          final content = tab['tabRenderer']?['content'];
          if (content == null) continue;

          final queueContents = content['musicQueueRenderer']?['content']
              ?['playlistPanelRenderer']?['contents'] as List?;

          if (queueContents != null) {
            for (final item in queueContents) {
              final panelRenderer = item['playlistPanelVideoRenderer'];
              if (panelRenderer != null) {
                final song = parser.parsePlaylistPanelItem(panelRenderer);
                if (song != null && song.videoId != videoId) {
                  tracks.add(song);
                }
              }
            }
          }
        }
      }

      debugPrint('[InnerTubeArtist] Found ${tracks.length} radio tracks');
      return tracks;
    } catch (e) {
      debugPrint('[InnerTubeArtist] Radio tracks error: $e');
      return [];
    }
  }
}
