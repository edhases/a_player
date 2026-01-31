import 'package:flutter/foundation.dart';

import 'innertube_base.dart';

/// Lyrics result with optional sync data
class LyricsResult {
  final String lyrics;
  final String? syncedLyrics;
  final String source;

  const LyricsResult({
    required this.lyrics,
    this.syncedLyrics,
    this.source = 'YouTube Music',
  });

  bool get hasSyncedLyrics => syncedLyrics != null && syncedLyrics!.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'lyrics': lyrics,
        'syncedLyrics': syncedLyrics,
        'source': source,
      };
}

/// Service for YouTube Music lyrics functionality
class InnerTubeLyricsService extends InnerTubeBase {
  InnerTubeLyricsService({
    required super.authService,
    super.rateLimiter,
    super.logger,
    super.dio,
    super.parser,
  });

  /// Fetch lyrics for a video
  Future<LyricsResult?> getLyrics(String videoId) async {
    try {
      // Step 1: Get lyrics browse ID from /next endpoint
      final lyricsBrowseId = await _getLyricsBrowseId(videoId);
      if (lyricsBrowseId == null) {
        debugPrint('[InnerTubeLyrics] No lyrics found for $videoId');
        return null;
      }

      // Step 2: Fetch lyrics content
      return _fetchLyricsContent(lyricsBrowseId);
    } catch (e) {
      debugPrint('[InnerTubeLyrics] Error getting lyrics: $e');
      return null;
    }
  }

  /// Get lyrics browse ID from watch next endpoint
  Future<String?> _getLyricsBrowseId(String videoId) async {
    try {
      final body = webContextBody();
      body['videoId'] = videoId;

      final data = await postRequest('/next', body);

      // Navigate to tabs
      final tabs = data['contents']?['singleColumnMusicWatchNextResultsRenderer']
          ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs']
          as List?;

      if (tabs == null) return null;

      debugPrint('[InnerTubeLyrics] Found ${tabs.length} tabs');

      for (final tab in tabs) {
        final tabRenderer = tab['tabRenderer'];
        final title = tabRenderer?['title'] as String?;

        debugPrint('[InnerTubeLyrics] Tab title: $title');

        // Match lyrics tab in various languages
        if (_isLyricsTab(title)) {
          final browseId =
              tabRenderer['endpoint']?['browseEndpoint']?['browseId'] as String?;
          debugPrint('[InnerTubeLyrics] Found lyrics browseId: $browseId');
          return browseId;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[InnerTubeLyrics] Error getting lyrics browse ID: $e');
      return null;
    }
  }

  /// Check if tab title matches lyrics tab
  bool _isLyricsTab(String? title) {
    if (title == null) return false;

    const lyricsTabTitles = [
      'Lyrics',
      'Тексти пісень',
      'Текст',
      'Текст песни',
      'Тексты песен',
      'Letra',
      'Letras',
      'Paroles',
      'Songtexte',
      'Liedtext',
      '歌詞',
      '가사',
    ];

    return lyricsTabTitles.any(
      (t) => title.toLowerCase().contains(t.toLowerCase()),
    );
  }

  /// Fetch lyrics content from browse endpoint
  Future<LyricsResult?> _fetchLyricsContent(String browseId) async {
    try {
      final body = webContextBody();
      body['browseId'] = browseId;

      final data = await postRequest('/browse', body);

      // Parse lyrics
      final lyricsRenderer = data['contents']?['sectionListRenderer']
          ?['contents']?[0]?['musicDescriptionShelfRenderer'];

      if (lyricsRenderer == null) {
        debugPrint('[InnerTubeLyrics] No lyrics renderer found');
        return null;
      }

      // Plain lyrics from description runs
      final plainLyrics = _extractPlainLyrics(lyricsRenderer);

      // Synced lyrics from timed data
      final syncedLyrics = _extractSyncedLyrics(lyricsRenderer);

      if (plainLyrics.isEmpty && syncedLyrics.isEmpty) {
        return null;
      }

      return LyricsResult(
        lyrics: plainLyrics,
        syncedLyrics: syncedLyrics.isNotEmpty ? syncedLyrics : null,
        source: 'YouTube Music',
      );
    } catch (e) {
      debugPrint('[InnerTubeLyrics] Error fetching lyrics content: $e');
      return null;
    }
  }

  /// Extract plain text lyrics
  String _extractPlainLyrics(Map<String, dynamic> renderer) {
    try {
      final runs = renderer['description']?['runs'] as List?;
      if (runs == null) return '';

      return runs.map((r) => r['text'] as String? ?? '').join('');
    } catch (e) {
      return '';
    }
  }

  /// Extract synced lyrics in LRC format
  String _extractSyncedLyrics(Map<String, dynamic> renderer) {
    try {
      final timedLyrics = renderer['timedLyricsData'] as List?;
      if (timedLyrics == null || timedLyrics.isEmpty) return '';

      final buffer = StringBuffer();

      for (final line in timedLyrics) {
        final text = line['lyricLine'] as String? ?? '';
        final startMsStr = line['startTimeMs']?.toString() ?? '0';
        final startMs = int.tryParse(startMsStr) ?? 0;

        final timestamp = _formatLrcTimestamp(startMs);
        buffer.writeln('$timestamp $text');
      }

      debugPrint(
          '[InnerTubeLyrics] Parsed ${timedLyrics.length} lines of synced lyrics');

      return buffer.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// Format milliseconds to LRC timestamp [mm:ss.xx]
  String _formatLrcTimestamp(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final hundredths = (duration.inMilliseconds % 1000) ~/ 10;

    return '[${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}]';
  }

  /// Check if lyrics are available for a video (without fetching full lyrics)
  Future<bool> hasLyrics(String videoId) async {
    final browseId = await _getLyricsBrowseId(videoId);
    return browseId != null;
  }
}
