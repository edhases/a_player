class LyricsLine {
  final Duration time;
  final String text;

  LyricsLine({required this.time, required this.text});

  @override
  String toString() => '[$time] $text';
}

class LyricsModel {
  final int id;
  final String trackName;
  final String artistName;
  final String albumName;
  final double duration;
  final bool instrumental;
  final String plainLyrics;
  final String syncedLyrics;

  // Cached parsed lyrics to avoid re-parsing
  List<LyricsLine>? _cachedParsedLyrics;

  LyricsModel({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.duration,
    required this.instrumental,
    required this.plainLyrics,
    required this.syncedLyrics,
  });

  bool get isSynced => syncedLyrics.isNotEmpty;

  /// Returns parsed synced lyrics lines (cached)
  List<LyricsLine> get parsedSyncedLyrics {
    return _cachedParsedLyrics ??= _parseSyncedLyrics();
  }

  List<LyricsLine> _parseSyncedLyrics() {
    if (!isSynced) return [];
    final lines = <LyricsLine>[];
    final regex = RegExp(r'^\[(\d{2}):(\d{2})\.(\d{2})\](.*)$');

    for (final line in syncedLyrics.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final hundredths = int.parse(match.group(3)!);

        lines.add(LyricsLine(
          time: Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: hundredths * 10,
          ),
          text: match.group(4)?.trim() ?? '',
        ));
      }
    }
    return lines;
  }

  factory LyricsModel.fromJson(Map<String, dynamic> json) {
    return LyricsModel(
      id: json['id'] as int? ?? 0,
      trackName: json['trackName'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      albumName: json['albumName'] as String? ?? '',
      duration: (json['duration'] as num? ?? 0).toDouble(),
      instrumental: json['instrumental'] as bool? ?? false,
      plainLyrics: json['plainLyrics'] as String? ?? '',
      syncedLyrics: json['syncedLyrics'] as String? ?? '',
    );
  }
}
