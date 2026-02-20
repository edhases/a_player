/// Utility class for formatting durations in various formats.
///
/// This centralizes all duration formatting logic to avoid duplication
/// across the codebase.
class DurationFormatter {
  DurationFormatter._(); // Prevent instantiation

  /// Formats duration as MM:SS or HH:MM:SS if hours > 0.
  ///
  /// Example: 125 seconds → "02:05"
  /// Example: 3725 seconds → "1:02:05"
  static String format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats duration as M:SS (no leading zero for minutes).
  ///
  /// Example: 185 seconds → "3:05"
  /// Example: 3725 seconds → "62:05" (for long tracks without hours)
  static String formatMinimal(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats duration as HH:MM:SS regardless of hours.
  ///
  /// Example: 125 seconds → "00:02:05"
  static String formatFull(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Alias for [formatMinimal]. Formats duration as M:SS.
  /// @deprecated Use [formatMinimal] instead.
  static String formatCompact(Duration duration) => formatMinimal(duration);

  /// Formats duration as LRC timestamp [MM:SS.xx].
  ///
  /// Example: 125500ms → "[02:05.50]"
  static String formatLrc(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final hundredths = (duration.inMilliseconds % 1000) ~/ 10;

    return '[${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}]';
  }

  /// Formats duration from milliseconds.
  static String fromMilliseconds(int milliseconds) {
    return format(Duration(milliseconds: milliseconds));
  }

  /// Formats duration from seconds.
  static String fromSeconds(int seconds) {
    return format(Duration(seconds: seconds));
  }

  /// Parses a duration string like "3:45" or "1:02:30" to Duration.
  static Duration? parse(String durationString) {
    try {
      final parts = durationString.split(':').map(int.parse).toList();
      if (parts.length == 2) {
        return Duration(minutes: parts[0], seconds: parts[1]);
      } else if (parts.length == 3) {
        return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Extension on Duration for easy formatting.
extension DurationFormatExtension on Duration {
  /// Formats as MM:SS or HH:MM:SS.
  String get formatted => DurationFormatter.format(this);

  /// Formats as HH:MM:SS always.
  String get formattedFull => DurationFormatter.formatFull(this);

  /// Formats as M:SS (compact).
  String get formattedCompact => DurationFormatter.formatCompact(this);

  /// Formats as LRC timestamp.
  String get formattedLrc => DurationFormatter.formatLrc(this);
}
