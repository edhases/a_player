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

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}
