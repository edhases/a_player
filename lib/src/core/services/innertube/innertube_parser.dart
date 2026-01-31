import 'package:flutter/foundation.dart';

import '../../../domain/entities/youtube_song.dart';

/// Parser utilities for InnerTube API responses
class InnerTubeParser {
  /// Parse a single song from musicResponsiveListItemRenderer
  YouTubeSong? parseSingleSong(Map<String, dynamic> mrlir) {
    try {
      // Extract flex columns for title/artist parsing
      final flexColumns = mrlir['flexColumns'] as List?;
      if (flexColumns == null || flexColumns.isEmpty) return null;

      // Title is usually in the first column
      String title = '';
      final col0Runs = flexColumns[0]
              ['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']
          as List?;
      if (col0Runs != null && col0Runs.isNotEmpty) {
        title = col0Runs[0]['text']?.toString() ?? '';
      }

      if (title.isEmpty) return null;

      // Artist is usually in the second column (or first depending on layout)
      String artist = 'Unknown';
      String? artistId;
      String? category;
      List? subtitleRuns;

      if (flexColumns.length > 1) {
        subtitleRuns = flexColumns[1]
                ['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']
            as List?;
        if (subtitleRuns != null && subtitleRuns.isNotEmpty) {
          // First run is often the category (e.g. "Song", "Video", "Album", "Artist")
          final firstRun = subtitleRuns[0]['text']?.toString();
          if (firstRun != null &&
              ['Song', 'Video', 'Album', 'Artist', 'Playlist', 'Пісня', 'Відео']
                  .contains(firstRun)) {
            category = firstRun;
            // Artist is after the separator
            if (subtitleRuns.length > 2) {
              final artistInfo = _extractArtistInfo(subtitleRuns.sublist(2));
              artist = artistInfo['name'] ?? 'Unknown';
              artistId = artistInfo['id'];
            }
          } else {
            // No category prefix, artist is directly first
            final artistInfo = _extractArtistInfo(subtitleRuns);
            artist = artistInfo['name'] ?? 'Unknown';
            artistId = artistInfo['id'];
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
            if (serviceEndpoint?['queueAddEndpoint']?['queueTarget']
                    ?['videoId'] !=
                null) {
              videoId =
                  serviceEndpoint['queueAddEndpoint']['queueTarget']['videoId'];
              break;
            }
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
        browseId ??= mrlir['onTap']?['browseEndpoint']?['browseId'];
      }

      // If we have no videoId and no browseId/playlistId, we can't do anything
      if (videoId == null && playlistId == null && browseId == null) {
        return null;
      }

      // Extract thumbnail
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

      // Extract duration
      int duration = 0;
      final lengthText = mrlir['lengthText']?['runs']?[0]?['text'] ??
          mrlir['fixedColumns']?[0]
                  ?['musicResponsiveListItemFixedColumnRenderer']?['text']
              ?['runs']?[0]?['text'];

      if (lengthText != null) {
        duration = parseDuration(lengthText);
      } else {
        // Fallback: Check fixedColumns
        final fixedCols = mrlir['fixedColumns'] as List?;
        if (fixedCols != null && fixedCols.isNotEmpty) {
          final text = fixedCols[0]
                  ['musicResponsiveListItemFixedColumnRenderer']?['text']
              ?['runs']?[0]?['text'];
          if (text != null) {
            duration = parseDuration(text);
          }
        }

        // Fallback: Check subtitle runs for duration
        if (duration == 0 && subtitleRuns != null && subtitleRuns.isNotEmpty) {
          final lastRun = subtitleRuns.last['text']?.toString().trim();
          if (lastRun != null && RegExp(r'^\d+:\d+').hasMatch(lastRun)) {
            duration = parseDuration(lastRun);
          }
        }
      }

      final isPlaylist =
          videoId == null && (browseId != null || playlistId != null);
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

      // Fallback: Recursive search for artist ID
      artistId ??= findArtistBrowseIdRecursive(mrlir);

      return YouTubeSong(
        videoId: videoId ?? effectivePlaylistId ?? '',
        title: title,
        artist: artist,
        thumbnailUrl: thumbUrl,
        artistId: artistId,
        playlistId: effectivePlaylistId,
        isPlaylist: isPlaylist,
        category: category ?? '',
        duration: duration,
      );
    } catch (e) {
      debugPrint('[InnerTubeParser] parseSingleSong error: $e');
      return null;
    }
  }

  /// Parse playlist panel item (used in radio/queue)
  YouTubeSong? parsePlaylistPanelItem(Map<String, dynamic> renderer) {
    try {
      final videoId = renderer['videoId'] as String?;
      if (videoId == null || videoId.isEmpty) return null;

      final title = renderer['title']?['runs']?[0]?['text'] as String? ?? '';
      if (title.isEmpty) return null;

      String artist = 'Unknown';
      String? artistId;
      final shortByline = renderer['shortBylineText']?['runs'] as List?;
      final longByline = renderer['longBylineText']?['runs'] as List?;
      final bylineRuns = shortByline ?? longByline;

      if (bylineRuns != null && bylineRuns.isNotEmpty) {
        final artistInfo = _extractArtistInfo(bylineRuns);
        artist = artistInfo['name'] ?? 'Unknown';
        artistId = artistInfo['id'];
      }

      artistId ??= findArtistBrowseIdRecursive(renderer);

      String thumbnail = '';
      final thumbs = renderer['thumbnail']?['thumbnails'] as List?;
      if (thumbs != null && thumbs.isNotEmpty) {
        thumbnail = thumbs.last['url'] as String? ?? '';
      }

      int duration = 0;
      final lengthText =
          renderer['lengthText']?['runs']?[0]?['text'] as String?;
      if (lengthText != null) {
        duration = parseDuration(lengthText);
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

  /// Parse duration string (e.g. "3:45") to seconds
  int parseDuration(String durationStr) {
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

  /// Extract artist info from runs.
  /// Returns {'name': String, 'id': String?}
  Map<String, String?> _extractArtistInfo(List runs) {
    if (runs.isEmpty) return {'name': 'Unknown', 'id': null};

    final artistParts = <String>[];
    String? artistId;
    
    // Category labels that should be skipped
    const categoryLabels = {
      'Single', 'Album', 'EP', 'Playlist', 'Song', 'Video',
      'Сингл', 'Альбом', 'Плейлист', 'Пісня', 'Відео',
      'Artist', 'Виконавець', 'Channel', 'Канал',
    };

    for (var run in runs) {
      final text = run['text']?.toString() ?? '';
      if (text.isEmpty) continue;

      // Skip separators but continue parsing
      if (text == ' • ' || text == '•') {
        if (artistParts.isNotEmpty) break;
        continue;
      }
      
      // Skip category labels
      if (categoryLabels.contains(text)) continue;

      if (text.contains('views') ||
          text.contains('plays') ||
          text == 'Watch' ||
          text.contains(' переглядів')) {
        break;
      }
      
      // Stop at duration patterns
      if (RegExp(r'^\d+:\d+').hasMatch(text)) break;

      artistParts.add(text);

      if (artistId == null) {
        final browseId =
            run['navigationEndpoint']?['browseEndpoint']?['browseId'];
        if (browseId != null &&
            (browseId.startsWith('UC') ||
                browseId.startsWith('UA') ||
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

  /// Recursively searches for a browseId that looks like an artist/channel ID.
  String? findArtistBrowseIdRecursive(dynamic data) {
    if (data is Map) {
      if (data.containsKey('browseId')) {
        final id = data['browseId'];
        if (id is String && (id.startsWith('UC') || id.startsWith('UA'))) {
          return id;
        }
      }
      for (var value in data.values) {
        final found = findArtistBrowseIdRecursive(value);
        if (found != null) return found;
      }
    } else if (data is List) {
      for (var item in data) {
        final found = findArtistBrowseIdRecursive(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Recursively find continuation token
  String? findContinuationToken(dynamic data) {
    if (data is Map) {
      // Check for 'continuations' array (common format)
      if (data.containsKey('continuations')) {
        final continuations = data['continuations'] as List?;
        if (continuations != null && continuations.isNotEmpty) {
          final cont = continuations[0];
          // Try different continuation key formats
          return cont['nextContinuationData']?['continuation'] ??
              cont['nextRadioContinuationData']?['continuation'] ??
              cont['reloadContinuationData']?['continuation'];
        }
      }
      
      // Check for direct 'continuation' key (used in some playlist responses)
      if (data.containsKey('continuation')) {
        final cont = data['continuation'];
        if (cont is String) return cont;
        if (cont is Map) {
          return cont['continuation'] ?? 
                 cont['token'] ??
                 cont['nextContinuationData']?['continuation'];
        }
      }
      
      // Check for 'continuationEndpoint' (another format)
      if (data.containsKey('continuationEndpoint')) {
        final endpoint = data['continuationEndpoint'];
        if (endpoint is Map) {
          return endpoint['continuationCommand']?['token'];
        }
      }
      
      for (var value in data.values) {
        final found = findContinuationToken(value);
        if (found != null) return found;
      }
    } else if (data is List) {
      for (var item in data) {
        final found = findContinuationToken(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Recursively find items in nested data
  List<Map<String, dynamic>> recursiveFindItems(
    dynamic data,
    String rendererKey,
  ) {
    final results = <Map<String, dynamic>>[];

    if (data is Map<String, dynamic>) {
      if (data.containsKey(rendererKey)) {
        results.add(data[rendererKey] as Map<String, dynamic>);
      }
      for (var value in data.values) {
        results.addAll(recursiveFindItems(value, rendererKey));
      }
    } else if (data is List) {
      for (var item in data) {
        results.addAll(recursiveFindItems(item, rendererKey));
      }
    }

    return results;
  }
}
