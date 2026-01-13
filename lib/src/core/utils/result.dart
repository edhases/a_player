/// A generic class that holds a value or an error.
/// Used to avoid null returns and unchecked exceptions.
class Result<T> {
  final T? data;
  final String? error;

  Result._({this.data, this.error});

  factory Result.success(T data) => Result._(data: data);
  factory Result.failure(String error) => Result._(error: error);

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  R fold<R>(R Function(T data) onSuccess, R Function(String error) onFailure) {
    if (isSuccess) {
      return onSuccess(data as T);
    } else {
      return onFailure(error!);
    }
  }
}
