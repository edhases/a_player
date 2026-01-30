import '../exceptions/youtube_exceptions.dart';

/// Error categories for UI handling
enum ErrorType {
  network,
  authentication,
  contentRestricted,
  parsing,
  rateLimit,
  noResults,
  unknown,
}

/// A generic class that holds a value or an error.
/// Used to avoid null returns and unchecked exceptions.
class Result<T> {
  final T? data;
  final String? error;
  final ErrorType? errorType;

  Result._({this.data, this.error, this.errorType});

  factory Result.success(T data) => Result._(data: data);

  factory Result.failure(String error, {ErrorType type = ErrorType.unknown}) =>
      Result._(error: error, errorType: type);

  /// Create a Result from a YouTubeException
  factory Result.fromException(YouTubeException e) {
    final ErrorType type;
    switch (e) {
      case NetworkException():
        type = ErrorType.network;
      case AuthenticationException():
        type = ErrorType.authentication;
      case ContentRestrictedException():
        type = ErrorType.contentRestricted;
      case ParsingException():
        type = ErrorType.parsing;
      case RateLimitException():
        type = ErrorType.rateLimit;
      case NoResultsException():
        type = ErrorType.noResults;
    }
    return Result._(error: e.message, errorType: type);
  }

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  /// Whether this is a network-related error (user might want to retry)
  bool get isNetworkError => errorType == ErrorType.network;

  /// Whether this is an auth error (user should re-login)
  bool get isAuthError => errorType == ErrorType.authentication;

  R fold<R>(R Function(T data) onSuccess, R Function(String error) onFailure) {
    if (isSuccess) {
      return onSuccess(data as T);
    } else {
      return onFailure(error!);
    }
  }

  /// Map success value to another type
  Result<R> map<R>(R Function(T data) mapper) {
    if (isSuccess) {
      return Result.success(mapper(data as T));
    }
    return Result._(error: error, errorType: errorType);
  }
}
