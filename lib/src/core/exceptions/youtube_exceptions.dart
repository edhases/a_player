// Custom exceptions for YouTube/InnerTube operations
// Provides meaningful error types for proper UI handling

/// Base exception for all YouTube/InnerTube errors
sealed class YouTubeException implements Exception {
  final String message;
  final String? videoId;

  const YouTubeException(this.message, {this.videoId});

  @override
  String toString() =>
      '$runtimeType: $message${videoId != null ? ' (videoId: $videoId)' : ''}';
}

/// Network connectivity issues (timeout, no internet)
class NetworkException extends YouTubeException {
  final bool isTimeout;

  const NetworkException(super.message,
      {super.videoId, this.isTimeout = false});
}

/// Authentication expired or invalid
class AuthenticationException extends YouTubeException {
  const AuthenticationException(super.message, {super.videoId});
}

/// Content restricted (geo-block, age-gate, premium-only)
class ContentRestrictedException extends YouTubeException {
  final String? reason;
  final String? status;

  const ContentRestrictedException(
    super.message, {
    super.videoId,
    this.reason,
    this.status,
  });
}

/// YouTube API structure changed (parsing failed)
class ParsingException extends YouTubeException {
  final String path;

  const ParsingException(
    super.message, {
    required this.path,
    super.videoId,
  });
}

/// Rate limited by YouTube
class RateLimitException extends YouTubeException {
  final Duration? retryAfter;

  const RateLimitException(super.message, {super.videoId, this.retryAfter});
}

/// No results found (not an error, but useful for UI)
class NoResultsException extends YouTubeException {
  const NoResultsException(super.message, {super.videoId});
}
