import 'package:flutter/foundation.dart';

import '../../../domain/entities/youtube_song.dart';
import 'innertube_base.dart';

/// Represents a playlist with metadata
class YouTubePlaylist {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int? trackCount;
  final String? author;

  const YouTubePlaylist({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.trackCount,
    this.author,
  });
}

/// Service for YouTube Music playlist functionality
class InnerTubePlaylistService extends InnerTubeBase {
  InnerTubePlaylistService({
    required super.authService,
    super.rateLimiter,
    super.logger,
    super.dio,
    super.parser,
  });

  /// Get tracks from a playlist or album
  Future<List<YouTubeSong>> getPlaylistTracks(String playlistId) async {
    // Ensure proper format
    String browseId = playlistId;
    if (!playlistId.startsWith('VL') &&
        !playlistId.startsWith('MPREb_') &&
        !playlistId.startsWith('OLAK')) {
      browseId = 'VL$playlistId';
    }

    return _fetchPlaylistTracks(browseId);
  }

  /// Get album tracks
  Future<List<YouTubeSong>> getAlbumTracks(String albumId) async {
    return _fetchPlaylistTracks(albumId);
  }

  /// Internal method to fetch tracks from any browse ID
  Future<List<YouTubeSong>> _fetchPlaylistTracks(
    String browseId, {
    String? params,
  }) async {
    try {
      final body = webContextBody();
      body['browseId'] = browseId;
      if (params != null) {
        body['params'] = params;
      }

      final data = await postRequest('/browse', body);

      // Extract header metadata for fallback
      String? fallbackArtist;
      String? fallbackThumbnail;
      _extractHeaderMetadata(data, (artist, thumb) {
        fallbackArtist = artist;
        fallbackThumbnail = thumb;
      });

      final tracks = _parsePlaylistTracks(
        data,
        fallbackArtist: fallbackArtist,
        fallbackThumbnail: fallbackThumbnail,
      );
      
      debugPrint('[InnerTubePlaylist] Initial fetch: ${tracks.length} tracks');

      // Handle pagination
      String? continuationToken = parser.findContinuationToken(data);
      debugPrint('[InnerTubePlaylist] Continuation token: ${continuationToken != null ? "found" : "NOT FOUND"}');
      
      int pageCount = 0;
      const int maxPages = 50;

      while (continuationToken != null && pageCount < maxPages) {
        pageCount++;
        debugPrint(
            '[InnerTubePlaylist] Fetching continuation page $pageCount...');

        await Future.delayed(const Duration(milliseconds: 300));
        final contData = await browseContinuation(continuationToken);
        if (contData == null) break;

        final newTracks = _parsePlaylistTracks(contData);
        tracks.addAll(newTracks);

        continuationToken = parser.findContinuationToken(contData);
      }

      debugPrint(
          '[InnerTubePlaylist] Loaded ${tracks.length} tracks from $browseId');
      return tracks;
    } catch (e) {
      debugPrint('[InnerTubePlaylist] Error fetching tracks: $e');
      return [];
    }
  }

  /// Extract header metadata (artist, thumbnail)
  void _extractHeaderMetadata(
    Map<String, dynamic> data,
    void Function(String? artist, String? thumbnail) callback,
  ) {
    try {
      final header = data['header']?['musicDetailHeaderRenderer'] ??
          data['header']?['musicResponsiveHeaderRenderer'];

      if (header == null) {
        callback(null, null);
        return;
      }

      // Thumbnail
      String? thumbnail;
      final thumbs = (header['thumbnail']?['musicThumbnailRenderer'] ??
          header['thumbnail'])?['thumbnails'] as List?;
      if (thumbs != null && thumbs.isNotEmpty) {
        thumbnail = thumbs.last['url'] as String?;
      }

      // Artist extraction
      String? artist;

      // 1. Check strapline
      var straplineRuns = header['straplineTextOne']?['runs'] as List?;
      straplineRuns ??= header['strapline']?['runs'] as List?;
      straplineRuns ??= header['straplineText']?['runs'] as List?;

      if (straplineRuns != null && straplineRuns.isNotEmpty) {
        artist = _extractArtistFromRuns(straplineRuns);
      }

      // 2. Check byline
      if (artist == null || artist == 'Unknown') {
        final bylineRuns = header['byline']?['runs'] as List?;
        if (bylineRuns != null) {
          artist = _extractArtistFromRuns(bylineRuns);
        }
      }

      // 3. Check subtitle
      if (artist == null || artist == 'Unknown') {
        final subtitleRuns = header['subtitle']?['runs'] as List?;
        if (subtitleRuns != null) {
          final text = _extractArtistFromRuns(subtitleRuns);
          if (!['Single', 'Album', 'EP', 'Playlist', 'Сингл', 'Альбом']
              .contains(text)) {
            artist = text;
          }
        }
      }

      callback(artist, thumbnail);
    } catch (e) {
      debugPrint('[InnerTubePlaylist] Header extraction error: $e');
      callback(null, null);
    }
  }

  /// Extract artist name from runs
  String? _extractArtistFromRuns(List runs) {
    if (runs.isEmpty) return null;

    final parts = <String>[];
    
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
        if (parts.isNotEmpty) break;
        continue;
      }
      
      // Skip category labels
      if (categoryLabels.contains(text)) continue;
      
      // Stop at duration patterns
      if (RegExp(r'^\d+:\d+').hasMatch(text)) break;
      
      parts.add(text);
    }

    final result = parts.join('').trim();
    return result.isNotEmpty ? result : null;
  }

  /// Parse playlist tracks from response
  List<YouTubeSong> _parsePlaylistTracks(
    Map<String, dynamic> data, {
    String? fallbackArtist,
    String? fallbackThumbnail,
  }) {
    final List<YouTubeSong> tracks = [];

    // Find all musicResponsiveListItemRenderer items recursively
    final items =
        parser.recursiveFindItems(data, 'musicResponsiveListItemRenderer');

    for (final item in items) {
      final song = parser.parseSingleSong(item);
      if (song != null) {
        // Apply fallbacks if needed
        final finalSong = YouTubeSong(
          videoId: song.videoId,
          title: song.title,
          artist: song.artist == 'Unknown' && fallbackArtist != null
              ? fallbackArtist
              : song.artist,
          thumbnailUrl: song.thumbnailUrl.isEmpty && fallbackThumbnail != null
              ? fallbackThumbnail
              : song.thumbnailUrl,
          artistId: song.artistId,
          playlistId: song.playlistId,
          isPlaylist: song.isPlaylist,
          category: song.category,
          duration: song.duration,
        );
        tracks.add(finalSong);
      }
    }

    return tracks;
  }

  /// Get user's library playlists
  Future<List<YouTubePlaylist>> getLibraryPlaylists() async {
    if (!await authService.isSignedIn()) {
      debugPrint('[InnerTubePlaylist] Not signed in, cannot get library');
      return [];
    }

    try {
      final body = webContextBody();
      body['browseId'] = 'FEmusic_liked_playlists';

      final data = await postRequest('/browse', body);
      return _parseLibraryPlaylists(data);
    } catch (e) {
      debugPrint('[InnerTubePlaylist] Library playlists error: $e');
      return [];
    }
  }

  /// Parse library playlists
  List<YouTubePlaylist> _parseLibraryPlaylists(Map<String, dynamic> data) {
    final List<YouTubePlaylist> playlists = [];

    try {
      final contents = data['contents']?['singleColumnBrowseResultsRenderer']
          ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']
          ?['contents'] as List?;

      if (contents == null) return [];

      for (final section in contents) {
        final gridContents =
            section['gridRenderer']?['items'] as List? ??
            section['musicShelfRenderer']?['contents'] as List? ??
            [];

        for (final item in gridContents) {
          final playlist = _parsePlaylistItem(item);
          if (playlist != null) {
            playlists.add(playlist);
          }
        }
      }
    } catch (e) {
      debugPrint('[InnerTubePlaylist] Error parsing library: $e');
    }

    return playlists;
  }

  /// Parse a single playlist item
  YouTubePlaylist? _parsePlaylistItem(Map<String, dynamic> item) {
    try {
      final renderer = item['musicTwoRowItemRenderer'] ??
          item['musicResponsiveListItemRenderer'];

      if (renderer == null) return null;

      // Title
      final title = renderer['title']?['runs']?[0]?['text'] as String? ?? '';
      if (title.isEmpty) return null;

      // Playlist ID
      String? playlistId;
      final browseEndpoint =
          renderer['navigationEndpoint']?['browseEndpoint'];
      if (browseEndpoint != null) {
        playlistId = browseEndpoint['browseId'] as String?;
      }

      if (playlistId == null) return null;

      // Thumbnail
      String? thumbnail;
      final thumbs = renderer['thumbnailRenderer']?['musicThumbnailRenderer']
              ?['thumbnail']?['thumbnails'] as List? ??
          renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']
              ?['thumbnails'] as List?;
      if (thumbs != null && thumbs.isNotEmpty) {
        thumbnail = thumbs.last['url'] as String?;
      }

      // Subtitle (track count, author)
      String? author;
      int? trackCount;
      final subtitleRuns = renderer['subtitle']?['runs'] as List?;
      if (subtitleRuns != null) {
        for (var run in subtitleRuns) {
          final text = run['text']?.toString() ?? '';
          // Check for track count pattern
          final countMatch = RegExp(r'(\d+)\s*(song|track|пісн|трек)', caseSensitive: false)
              .firstMatch(text);
          if (countMatch != null) {
            trackCount = int.tryParse(countMatch.group(1) ?? '');
          }
          // First run is often the author
          if (author == null && text.isNotEmpty && text != ' • ') {
            author = text;
          }
        }
      }

      return YouTubePlaylist(
        id: playlistId,
        title: title,
        thumbnailUrl: thumbnail,
        trackCount: trackCount,
        author: author,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get user's liked songs
  Future<List<YouTubeSong>> getLikedSongs() async {
    if (!await authService.isSignedIn()) {
      debugPrint('[InnerTubePlaylist] Not signed in');
      return [];
    }

    try {
      // Use 'LM' (Liked Music) playlist ID, not 'FEmusic_liked_videos' which is for videos
      debugPrint('[InnerTubePlaylist] Fetching liked songs (LM playlist)...');
      return await getPlaylistTracks('LM');
    } catch (e) {
      debugPrint('[InnerTubePlaylist] Liked songs error: $e');
      return [];
    }
  }

  /// Rate a song (like/dislike/remove)
  Future<bool> rateSong(String videoId, String rating) async {
    if (!await authService.isSignedIn()) return false;

    try {
      final body = webContextBody();
      body['target'] = {'videoId': videoId};

      String endpoint;
      switch (rating.toLowerCase()) {
        case 'like':
          endpoint = '/like/like';
          break;
        case 'dislike':
          endpoint = '/like/dislike';
          break;
        case 'remove':
        default:
          endpoint = '/like/removelike';
          break;
      }

      await postRequest(endpoint, body);
      return true;
    } catch (e) {
      debugPrint('[InnerTubePlaylist] Rate song error: $e');
      return false;
    }
  }
}
