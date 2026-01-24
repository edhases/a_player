import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/lyrics_model.dart';
import 'log_service.dart';

class LyricsService {
  static const String _lrclibUrl = 'https://lrclib.net/api';
  static const String _geniusUrl = 'https://api.genius.com';
  static const String _geniusToken =
      'wyAjHxnpbmPpTaF_aq2hbxKKDmlqyTJ2g6sCNCTghry23OHn0xfsgu1p5T5CoIRp';

  // In-memory cache: key = "artist|title" or trackId
  final Map<String, LyricsModel> _cache = {};
  final LogService? _logService;

  LyricsService({LogService? logService})
      : _logService = logService ??
            (GetIt.I.isRegistered<LogService>() ? GetIt.I<LogService>() : null);

  /// Generate cache key from track info
  String _cacheKey(String trackName, String artistName) {
    return '${artistName.toLowerCase()}|${trackName.toLowerCase()}';
  }

  /// Main entry point - with caching and fallback
  Future<LyricsModel?> getLyrics({
    required String trackName,
    required String artistName,
    required String albumName,
    required double duration,
  }) async {
    final key = _cacheKey(trackName, artistName);

    // 1. Check cache first
    if (_cache.containsKey(key)) {
      debugPrint('[LyricsService] Cache hit for: $trackName');
      return _cache[key];
    }

    // 2. Try lrclib (exact match)
    var lyrics = await _fetchFromLrclib(
      trackName: trackName,
      artistName: artistName,
      albumName: albumName,
      duration: duration,
    );

    // 3. Try lrclib fuzzy search
    if (lyrics == null) {
      lyrics = await _searchLrclib(trackName, artistName, duration);
    }

    // 4. Fallback to Genius
    if (lyrics == null) {
      lyrics = await _fetchFromGenius(trackName, artistName);
    }

    // 5. Cache result
    if (lyrics != null) {
      _cache[key] = lyrics;
    }

    return lyrics;
  }

  /// Prefetch lyrics for a track (fire-and-forget)
  Future<void> prefetchLyrics({
    required String trackName,
    required String artistName,
    required String albumName,
    required double duration,
  }) async {
    final key = _cacheKey(trackName, artistName);
    if (_cache.containsKey(key)) {
      debugPrint('[LyricsService] Already cached: $trackName');
      return;
    }

    debugPrint('[LyricsService] Prefetching lyrics for: $trackName');
    await getLyrics(
      trackName: trackName,
      artistName: artistName,
      albumName: albumName,
      duration: duration,
    );
  }

  /// Check if lyrics are already cached
  bool hasCachedLyrics(String trackName, String artistName) {
    return _cache.containsKey(_cacheKey(trackName, artistName));
  }

  /// Get cached lyrics without fetching
  LyricsModel? getCachedLyrics(String trackName, String artistName) {
    return _cache[_cacheKey(trackName, artistName)];
  }

  // ==================== LRCLIB ====================

  Future<LyricsModel?> _fetchFromLrclib({
    required String trackName,
    required String artistName,
    required String albumName,
    required double duration,
  }) async {
    try {
      final uri = Uri.parse('$_lrclibUrl/get').replace(queryParameters: {
        'track_name': trackName,
        'artist_name': artistName,
        'album_name': albumName,
        'duration': duration.toString(),
      });

      debugPrint('[LyricsService] Fetching from lrclib: $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[LyricsService] lrclib exact match found');
        return LyricsModel.fromJson(data);
      } else if (response.statusCode == 404) {
        debugPrint('[LyricsService] lrclib exact match not found');
        return null;
      } else {
        debugPrint('[LyricsService] lrclib error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[LyricsService] lrclib exception: $e');
      _logService?.error('LyricsService lrclib exception', error: e);
      return null;
    }
  }

  Future<LyricsModel?> _searchLrclib(
      String trackName, String artistName, double duration) async {
    try {
      final uri = Uri.parse('$_lrclibUrl/search').replace(queryParameters: {
        'track_name': trackName,
        'artist_name': artistName,
      });

      debugPrint('[LyricsService] Searching lrclib: $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Find closest match by duration (within +/- 5 seconds)
        LyricsModel? bestMatch;
        double minDiff = 100000;

        for (var item in data) {
          final itemDuration = (item['duration'] as num?)?.toDouble() ?? 0.0;
          final diff = (itemDuration - duration).abs();

          if (diff < 5.0 && diff < minDiff) {
            minDiff = diff;
            bestMatch = LyricsModel.fromJson(item);
          }
        }

        if (bestMatch != null) {
          debugPrint(
              '[LyricsService] lrclib fuzzy match: ${bestMatch.trackName}');
          return bestMatch;
        }
      }
    } catch (e) {
      debugPrint('[LyricsService] lrclib search exception: $e');
    }
    return null;
  }

  // ==================== GENIUS ====================

  Future<LyricsModel?> _fetchFromGenius(
      String trackName, String artistName) async {
    try {
      // 1. Search for song
      final songId = await _searchGeniusSong(trackName, artistName);
      if (songId == null) {
        debugPrint('[Genius] No song found for: $trackName - $artistName');
        return null;
      }

      // 2. Get song details (lyrics URL)
      final songData = await _getGeniusSongDetails(songId);
      if (songData == null) {
        return null;
      }

      // 3. Scrape lyrics from web page
      final lyricsUrl = songData['url'] as String?;
      if (lyricsUrl == null) {
        return null;
      }

      final plainLyrics = await _scrapeGeniusLyrics(lyricsUrl);
      if (plainLyrics == null || plainLyrics.isEmpty) {
        return null;
      }

      debugPrint('[Genius] Successfully fetched lyrics for: $trackName');
      return LyricsModel(
        id: songId,
        trackName: songData['title'] as String? ?? trackName,
        artistName: songData['artist_name'] as String? ?? artistName,
        albumName: '',
        duration: 0,
        instrumental: false,
        plainLyrics: plainLyrics,
        syncedLyrics: '', // Genius doesn't provide synced lyrics
      );
    } catch (e) {
      debugPrint('[Genius] Exception: $e');
      _logService?.error('Genius Exception', error: e);
      return null;
    }
  }

  Future<int?> _searchGeniusSong(String trackName, String artistName) async {
    try {
      final query = '$artistName $trackName';
      final uri = Uri.parse('$_geniusUrl/search').replace(queryParameters: {
        'q': query,
      });

      debugPrint('[Genius] Searching: $query');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $_geniusToken',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = data['response']?['hits'] as List?;

        if (hits != null && hits.isNotEmpty) {
          // Return first result's song ID
          final songId = hits[0]['result']?['id'] as int?;
          debugPrint('[Genius] Found song ID: $songId');
          return songId;
        }
      } else {
        debugPrint('[Genius] Search error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Genius] Search exception: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getGeniusSongDetails(int songId) async {
    try {
      final uri = Uri.parse('$_geniusUrl/songs/$songId');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $_geniusToken',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final song = data['response']?['song'] as Map<String, dynamic>?;

        if (song != null) {
          return {
            'id': song['id'],
            'title': song['title'],
            'artist_name': song['primary_artist']?['name'],
            'url': song['url'],
          };
        }
      }
    } catch (e) {
      debugPrint('[Genius] Song details exception: $e');
    }
    return null;
  }

  Future<String?> _scrapeGeniusLyrics(String url) async {
    try {
      debugPrint('[Genius] Scraping lyrics from: $url');
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      });

      if (response.statusCode == 200) {
        final html = response.body;

        // Extract lyrics using split approach (handles nested divs better)
        // Find all sections that start with data-lyrics-container
        final List<String> lyricsContents = [];
        final containerStart = 'data-lyrics-container="true"';

        int searchIndex = 0;
        while (true) {
          final startIdx = html.indexOf(containerStart, searchIndex);
          if (startIdx == -1) break;

          // Find the > that ends this opening tag
          final tagEnd = html.indexOf('>', startIdx);
          if (tagEnd == -1) break;

          // Now find the matching closing </div> - count nested divs
          int divCount = 1;
          int pos = tagEnd + 1;
          int contentStart = pos;

          while (divCount > 0 && pos < html.length) {
            final nextOpen = html.indexOf('<div', pos);
            final nextClose = html.indexOf('</div>', pos);

            if (nextClose == -1) break;

            if (nextOpen != -1 && nextOpen < nextClose) {
              divCount++;
              pos = nextOpen + 4;
            } else {
              divCount--;
              if (divCount == 0) {
                final content = html.substring(contentStart, nextClose);
                lyricsContents.add(content);
              }
              pos = nextClose + 6;
            }
          }

          searchIndex = pos;
        }

        debugPrint('[Genius] Found ${lyricsContents.length} lyrics containers');

        if (lyricsContents.isEmpty) {
          // Try alternative pattern
          final altPattern = RegExp(
            r'class="Lyrics__Container[^"]*"[^>]*>(.*?)</div>',
            dotAll: true,
          );
          final altMatches = altPattern.allMatches(html);
          if (altMatches.isEmpty) {
            debugPrint('[Genius] No lyrics container found');
            return null;
          }

          final lyrics = altMatches
              .map((m) => _cleanHtml(m.group(1) ?? ''))
              .join('\n')
              .trim();
          return lyrics.isNotEmpty ? lyrics : null;
        }

        final lyrics =
            lyricsContents.map((c) => _cleanHtml(c)).join('\n').trim();
        return lyrics.isNotEmpty ? lyrics : null;
      }
    } catch (e) {
      debugPrint('[Genius] Scrape exception: $e');
      _logService?.error('Genius Scrape exception', error: e);
    }
    return null;
  }

  String _cleanHtml(String html) {
    // Replace <br> with newlines
    var text = html.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    // Remove all other HTML tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    // Decode HTML entities
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    // Clean up Genius-specific metadata artifacts
    // Remove lines like "1 ContributorSong Title Lyrics"
    final lines = text.split('\n');
    final cleanedLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();

      // Skip empty lines (will re-add spacing later)
      if (trimmed.isEmpty) {
        cleanedLines.add('');
        continue;
      }

      // Skip lines containing "Contributor" (metadata header)
      if (trimmed.contains('Contributor')) continue;

      // Skip lines that are ONLY the song title header (ends with "Lyrics" preceded by parentheses)
      // Example: "Хороший громадянин (A good citizen) Lyrics" or "1 ContributorSong Lyrics"
      // But NOT regular lyrics that happen to contain the word "Lyrics"
      if (RegExp(r'^\d*\s*Contributor').hasMatch(trimmed)) continue;
      if (RegExp(r'\)\s*Lyrics$').hasMatch(trimmed))
        continue; // Parentheses before Lyrics = title
      if (trimmed == 'Lyrics') continue;

      // Skip embed/share buttons
      if (trimmed.contains('Embed') || trimmed.contains('Share')) continue;

      cleanedLines.add(line);
    }

    // Join and clean up extra whitespace
    text = cleanedLines.join('\n');
    // Remove excessive blank lines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  /// Clear lyrics cache
  void clearCache() {
    _cache.clear();
    debugPrint('[LyricsService] Cache cleared');
  }
}
