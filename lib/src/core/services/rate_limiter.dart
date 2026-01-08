import 'dart:collection';

/// A simple rate limiter to avoid sending too many requests in a short period.
/// This helps prevent IP-based rate limiting from services like YouTube.
class RateLimiter {
  final Queue<DateTime> _requests = Queue();
  final int maxRequests;
  final Duration window;

  RateLimiter({this.maxRequests = 200, this.window = const Duration(minutes: 1)});

  /// Waits if the number of requests exceeds the limit within the defined window.
  Future<void> throttle() async {
    // Clean up old requests that are outside the current time window.
    while (_requests.isNotEmpty && DateTime.now().difference(_requests.first) > window) {
      _requests.removeFirst();
    }

    // If the request limit is reached, calculate the necessary delay and wait.
    if (_requests.length >= maxRequests) {
      final waitTime = window - DateTime.now().difference(_requests.first);
      if (waitTime.isNegative == false) {
        await Future.delayed(waitTime);
      }
    }

    // Add the timestamp of the current request to the queue.
    _requests.add(DateTime.now());
  }
}
