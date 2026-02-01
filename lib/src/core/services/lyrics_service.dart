import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/lyrics_model.dart';
import 'innertube/innertube.dart';
import 'ksoft_service.dart';

class LyricsService {
  static const String _lrclibUrl = 'https://lrclib.net/api';
  static const String _geniusUrl = 'https://api.genius.com';
  static const String _geniusToken =
      'wyAjHxnpbmPpTaF_aq2hbxKKDmlqyTJ2g6sCNCTghry23OHn0xfsgu1p5T5CoIRp';

  final InnerTubeService _innerTube;
  final KSoftService _ksoft;

  // In-memory cache: key = "artist|title" or trackId
  final Map<String, LyricsModel> _cache = {};

  LyricsService(this._innerTube, {KSoftService? ksoft})
      : _ksoft = ksoft ?? KSoftService();

  /// Generate cache key from track info
  String _cacheKey(String trackName, String artistName) {
    return '${artistName.toLowerCase()}|${trackName.toLowerCase()}';
  }

  /// Main entry point - with caching and priority-based fallback
  /// Priority:
  /// 1. Synced: YouTube Music -> LRCLIB
  /// 2. Plain: YouTube Music -> Genius
  Future<LyricsModel?> getLyrics({
    required String trackName,
    required String artistName,
    required String albumName,
    required double duration,
    String? videoId,
  }) async {
    final key = _cacheKey(trackName, artistName);

    // 1. Check cache first
    if (_cache.containsKey(key)) {
      debugPrint('[LyricsService] Cache hit for: $trackName');
      return _cache[key];
    }

    LyricsModel? lrclibCandidate;
    LyricsModel? ytmCandidate;

    // --- PHASE 1: Try Synced Lyrics ---

    // 1.1 Try LRCLIB (Priority 1 for Synced)
    debugPrint('[LyricsService] Trying LRCLIB (Synced Priority)...');
    lrclibCandidate = await _fetchFromLrclib(
      trackName: trackName,
      artistName: artistName,
      albumName: albumName,
      duration: duration,
    );
    // Try fuzzy search if exact failed
    lrclibCandidate ??= await _searchLrclib(trackName, artistName, duration);

    if (lrclibCandidate != null && lrclibCandidate.isSynced) {
      debugPrint('[LyricsService] 🟢 Found synced lyrics from LRCLIB');
      _cache[key] = lrclibCandidate;
      return lrclibCandidate;
    }

    // 1.2 Try YouTube Music (Priority 2 for Synced)
    debugPrint('[LyricsService] Trying YouTube Music (Synced Priority)...');
    String? effectiveVideoId = videoId;
    if (effectiveVideoId == null) {
      try {
        final searchResult = await _innerTube.search('$artistName $trackName');
        if (searchResult.isNotEmpty) {
          effectiveVideoId = searchResult.first.videoId;
        }
      } catch (e) {
        debugPrint('[LyricsService] YTM search failed: $e');
      }
    }

    if (effectiveVideoId != null) {
      final ytmData = await _innerTube.getLyrics(effectiveVideoId);
      if (ytmData != null) {
        ytmCandidate = LyricsModel(
          id: 0,
          trackName: trackName,
          artistName: artistName,
          albumName: albumName,
          duration: duration,
          instrumental: false,
          plainLyrics: ytmData['lyrics'] ?? '',
          syncedLyrics: ytmData['syncedLyrics'] ?? '',
          source: 'YouTube Music',
        );

        if (ytmCandidate.isSynced) {
          debugPrint(
              '[LyricsService] 🟢 Found synced lyrics from YouTube Music');
          _cache[key] = ytmCandidate;
          return ytmCandidate;
        }
      }
    }

    // --- PHASE 2: Try Plain Lyrics ---

    // 2.1 Return YouTube Music if we found plain lyrics (Priority 1 for Plain)
    if (ytmCandidate != null && ytmCandidate.plainLyrics.isNotEmpty) {
      debugPrint(
          '[LyricsService] 🟡 Returning plain lyrics from YouTube Music');
      _cache[key] = ytmCandidate;
      return ytmCandidate;
    }

    // 2.2 Return LRCLIB if we found plain lyrics (Priority 2 for Plain)
    if (lrclibCandidate != null && lrclibCandidate.plainLyrics.isNotEmpty) {
      debugPrint('[LyricsService] 🟡 Returning plain lyrics from LRCLIB');
      _cache[key] = lrclibCandidate;
      return lrclibCandidate;
    }

    // 2.3 Try KSoft.Si (Priority 3 - has synced lyrics via singalong)
    if (_ksoft.isConfigured) {
      debugPrint('[LyricsService] Trying KSoft.Si...');
      final ksoftCandidate = await _ksoft.getLyrics(
        trackName: trackName,
        artistName: artistName,
        duration: duration,
      );
      if (ksoftCandidate != null) {
        if (ksoftCandidate.isSynced) {
          debugPrint('[LyricsService] 🟢 Found synced lyrics from KSoft.Si');
        } else {
          debugPrint('[LyricsService] 🟡 Found plain lyrics from KSoft.Si');
        }
        _cache[key] = ksoftCandidate;
        return ksoftCandidate;
      }
    }

    // 2.4 Fallback to Genius (Priority 4 for Plain)
    debugPrint('[LyricsService] Fallback to Genius (Priority 4 for Plain)...');
    final genius = await _fetchFromGenius(trackName, artistName);
    if (genius != null) {
      _cache[key] = genius;
      return genius;
    }

    return null;
  }

  /// Prefetch lyrics for a track (fire-and-forget)
  Future<void> prefetchLyrics({
    required String trackName,
    required String artistName,
    required String albumName,
    required double duration,
    String? videoId,
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
      videoId: videoId,
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
        final model = LyricsModel.fromJson(data);
        return LyricsModel(
          id: model.id,
          trackName: model.trackName,
          artistName: model.artistName,
          albumName: model.albumName,
          duration: model.duration,
          instrumental: model.instrumental,
          plainLyrics: model.plainLyrics,
          syncedLyrics: model.syncedLyrics,
          source: 'LRCLIB',
        );
      } else if (response.statusCode == 404) {
        debugPrint('[LyricsService] lrclib exact match not found');
        return null;
      } else {
        debugPrint('[LyricsService] lrclib error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[LyricsService] lrclib exception: $e');
      return null;
    }
  }

  Future<LyricsModel?> _searchLrclib(
      String trackName, String artistName, double duration) async {
    // Try with original artist name first, then with cleaned artist
    final artistVariants = {
      artistName,
      _cleanArtistForSearch(artistName),
    }.toList(); // Set removes duplicates

    for (final artist in artistVariants) {
      final result = await _searchLrclibWithArtist(trackName, artist, duration);
      if (result != null) return result;
    }
    return null;
  }

  Future<LyricsModel?> _searchLrclibWithArtist(
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
            final model = LyricsModel.fromJson(item);
            bestMatch = LyricsModel(
              id: model.id,
              trackName: model.trackName,
              artistName: model.artistName,
              albumName: model.albumName,
              duration: model.duration,
              instrumental: model.instrumental,
              plainLyrics: model.plainLyrics,
              syncedLyrics: model.syncedLyrics,
              source: 'LRCLIB (Fuzzy)',
            );
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

        // Last resort: Try direct URL scraping if song not found via API
        final directLyrics = await _tryDirectGeniusUrl(trackName, artistName);
        if (directLyrics != null) return directLyrics;

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
        source: 'Genius',
      );
    } catch (e) {
      debugPrint('[Genius] Exception: $e');
      return null;
    }
  }

  /// Try to construct Genius URL directly and scrape (for very new songs)
  Future<LyricsModel?> _tryDirectGeniusUrl(
      String trackName, String artistName) async {
    try {
      // Try multiple URL patterns
      final patterns = _generateGeniusUrlPatterns(trackName, artistName);

      for (final url in patterns) {
        debugPrint('[Genius] Trying direct URL: $url');
        final plainLyrics = await _scrapeGeniusLyrics(url);
        if (plainLyrics != null && plainLyrics.isNotEmpty) {
          debugPrint('[Genius] ✅ Direct URL worked: $url');
          return LyricsModel(
            id: 0,
            trackName: trackName,
            artistName: artistName,
            albumName: '',
            duration: 0,
            instrumental: false,
            plainLyrics: plainLyrics,
            syncedLyrics: '',
            source: 'Genius (Direct)',
          );
        }
      }
    } catch (e) {
      debugPrint('[Genius] Direct URL attempt failed: $e');
    }
    return null;
  }

  /// Generate possible Genius URL patterns
  List<String> _generateGeniusUrlPatterns(String track, String artist) {
    final urls = <String>[];

    // Clean inputs
    final cleanTrack = _cleanString(track).toLowerCase();
    final cleanArtist =
        _cleanArtistForSearch(_cleanString(artist)).toLowerCase();
    final fullArtist = artist.toLowerCase();

    // Pattern 1: cleaned artist + track
    final slug1 = '$cleanArtist-$cleanTrack'
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
    if (slug1.isNotEmpty) {
      urls.add('https://genius.com/$slug1-lyrics');
    }

    // Pattern 2: full artist (with collabs) + track
    final slug2 = '$fullArtist-$cleanTrack'
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
    if (slug2.isNotEmpty && slug2 != slug1) {
      urls.add('https://genius.com/$slug2-lyrics');
    }

    // Pattern 3: just track name (sometimes Genius uses this)
    final slug3 = cleanTrack
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
    if (slug3.isNotEmpty) {
      urls.add('https://genius.com/$slug3-lyrics');
    }

    return urls;
  }

  Future<int?> _searchGeniusSong(String trackName, String artistName) async {
    // Try multiple search strategies
    final cleanTrack = _cleanString(trackName);
    final cleanArtist = _cleanArtistForSearch(_cleanString(artistName));

    // Different query variants to try
    final queries = <String>{
      '$cleanArtist $cleanTrack', // "Сусіди Стерплять Забудуться жалі"
      '$artistName $trackName', // Original full names
      cleanTrack, // Just track name
      '$cleanTrack $cleanArtist', // Reversed order
    }.toList();

    for (final query in queries) {
      final songId = await _searchGeniusWithQuery(query, trackName, artistName);
      if (songId != null) return songId;
    }

    return null;
  }

  Future<int?> _searchGeniusWithQuery(
      String query, String targetTrack, String targetArtist) async {
    try {
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
          debugPrint(
              '[Genius] Found ${hits.length} partial hits. Validating...');

          for (var hit in hits) {
            final result = hit['result'];
            final hitTitle = result['title'] as String? ?? '';
            final hitArtist =
                result['primary_artist']?['name'] as String? ?? '';

            debugPrint('[Genius] Checking: "$hitTitle" by "$hitArtist"');

            if (_isValidMatch(targetTrack, targetArtist, hitTitle, hitArtist)) {
              final songId = result['id'] as int?;
              debugPrint('[Genius] ✅ Valid match found: ID $songId');
              return songId;
            }
          }
          debugPrint('[Genius] ❌ No valid match found in hits.');
        }
      } else {
        debugPrint('[Genius] Search error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Genius] Search exception: $e');
    }
    return null;
  }

  bool _isValidMatch(String targetTrack, String targetArtist, String hitTrack,
      String hitArtist) {
    if (targetTrack.isEmpty || hitTrack.isEmpty) return false;

    // 1. Clean Inputs: Remove brackets content (e.g. "(Official Video)", "(Sea)")
    // and normalize for comparison
    final tArtist = _normalize(targetArtist);
    final hArtist = _normalize(hitArtist);

    // Clean target track: Remove artist name if present as prefix to avoid "SadSvit - Море" issues
    String cleanTargetTrack = _cleanString(targetTrack);
    // If target track starts with artist name (loosely), strip it
    if (cleanTargetTrack.toLowerCase().startsWith(targetArtist.toLowerCase())) {
      cleanTargetTrack = cleanTargetTrack.substring(targetArtist.length).trim();
      // Remove leading dash if present " - Море"
      if (cleanTargetTrack.startsWith('-')) {
        cleanTargetTrack = cleanTargetTrack.substring(1).trim();
      }
    }

    final tTrack = _normalize(cleanTargetTrack);

    // Prepare Hit Track: compare both raw (normalized) and clean (no brackets)
    final hTrackRaw = _normalize(hitTrack);
    final hTrackClean = _normalize(_cleanString(hitTrack));

    // --- Artist Check ---
    // Looser check:
    // 1. Exact or containment
    // 2. Or if hit artist is "Genius ..." (translation entries)
    bool artistMatch = tArtist == hArtist ||
        hArtist.contains(tArtist) ||
        tArtist.contains(hArtist);

    // --- Title Check ---
    // Check against both raw and cleaned hit title
    bool titleMatch = tTrack == hTrackRaw ||
        hTrackRaw.contains(tTrack) ||
        tTrack.contains(hTrackRaw) ||
        tTrack == hTrackClean ||
        hTrackClean.contains(tTrack) ||
        tTrack.contains(hTrackClean);

    // Special case: If target is "Море" and Hit is "Море (Sea)", hTrackClean is "море".
    // tTrack "море" == hTrackClean "море" -> Match.

    // If strict artist check failed, try to be more lenient if title is EXACT match
    if (!artistMatch && (tTrack == hTrackClean || tTrack == hTrackRaw)) {
      // Maybe allow?
      // But verify if it's a translation entry like "Genius English Translations"
      if (hArtist.contains('genius') || hArtist.contains('translation')) {
        return true; // Often these have the correct lyrics
      }
      // If the title is very unique/long, maybe safe. For short titles like "More", risky.
      // Let's stick to returning true if title is exact match to the CLEAN hit.
      return true;
    }

    return titleMatch && artistMatch;
  }

  String _cleanString(String s) {
    // Remove content in parentheses and brackets
    String result = s.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    result = result.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    return result;
  }

  /// Clean artist name for better search results
  /// Removes featuring artists, collab markers like "& Artist", "feat. Artist", "x Artist"
  String _cleanArtistForSearch(String artist) {
    String clean = artist;

    // Remove content after common collab markers
    // "Artist & Other" -> "Artist"
    // "Artist feat. Other" -> "Artist"
    // "Artist x Other" -> "Artist"
    final collabPatterns = [
      RegExp(r'\s*&\s+\w.*$', caseSensitive: false), // & Artist
      RegExp(r'\s+feat\.?\s+\w.*$', caseSensitive: false), // feat. Artist
      RegExp(r'\s+ft\.?\s+\w.*$', caseSensitive: false), // ft. Artist
      RegExp(r'\s+x\s+\w.*$', caseSensitive: false), // x Artist (collab)
      RegExp(r'\s+і\s+\w.*$',
          caseSensitive: false), // і Artist (Ukrainian "and")
      RegExp(r'\s+та\s+\w.*$',
          caseSensitive: false), // та Artist (Ukrainian "and")
    ];

    for (final pattern in collabPatterns) {
      clean = clean.replaceAll(pattern, '');
    }

    return clean.trim();
  }

  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0400-\u04FF]'),
            '') // Keep alphanumeric and Cyrillic
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
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
        final allLyrics = StringBuffer();

        // Find all data-lyrics-container sections
        // Use indexOf approach to handle nested divs properly
        int searchStart = 0;
        while (true) {
          final containerStart =
              html.indexOf('data-lyrics-container="true"', searchStart);
          if (containerStart == -1) break;

          // Find the opening > of this div
          final contentStart = html.indexOf('>', containerStart);
          if (contentStart == -1) break;

          // Now find the matching closing </div> by counting nesting
          int depth = 1;
          int pos = contentStart + 1;
          int contentEnd = -1;

          while (pos < html.length && depth > 0) {
            final nextOpen = html.indexOf('<div', pos);
            final nextClose = html.indexOf('</div>', pos);

            if (nextClose == -1) break;

            if (nextOpen != -1 && nextOpen < nextClose) {
              // Found nested div
              depth++;
              pos = nextOpen + 4;
            } else {
              // Found closing div
              depth--;
              if (depth == 0) {
                contentEnd = nextClose;
              }
              pos = nextClose + 6;
            }
          }

          if (contentEnd != -1) {
            final content = html.substring(contentStart + 1, contentEnd);
            final cleanContent = _cleanHtml(content);
            if (cleanContent.isNotEmpty) {
              if (allLyrics.isNotEmpty) allLyrics.write('\n');
              allLyrics.write(cleanContent);
            }
          }

          searchStart = contentEnd != -1 ? contentEnd : containerStart + 30;
        }

        if (allLyrics.isEmpty) {
          debugPrint('[Genius] No lyrics found in containers');
          return null;
        }

        debugPrint('[Genius] Extracted ${allLyrics.length} chars of lyrics');
        return allLyrics.toString();
      }
    } catch (e) {
      debugPrint('[Genius] Scrape exception: $e');
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
    // Be very precise to avoid removing actual lyrics
    final lines = text.split('\n');
    final cleanedLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();

      // Skip empty lines (will re-add spacing later)
      if (trimmed.isEmpty) {
        cleanedLines.add('');
        continue;
      }

      // Skip lines that are EXACTLY metadata patterns (very specific)
      // Pattern: "N Contributor(s)SongTitle Lyrics" at the very start
      if (RegExp(r'^\d+\s*Contributor').hasMatch(trimmed)) continue;

      // Skip lines that are ONLY "Lyrics" (title marker)
      if (trimmed == 'Lyrics') continue;

      // Skip Genius embed button (exact match)
      if (trimmed == 'Embed' || trimmed == 'EmbedShare URLCopyEmbedCopy') {
        continue;
      }

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
