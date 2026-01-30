// Safe JSON path navigation utilities
// Provides clear error messages when YouTube changes API structure

import '../exceptions/youtube_exceptions.dart';

/// Extension for safe JSON navigation with explicit paths
extension JsonPath on Map<String, dynamic> {
  /// Navigate to a value at the given path, returns null if any key is missing.
  /// Supports both string keys for objects and integer indices for lists.
  ///
  /// Example:
  /// ```dart
  /// final title = data.path<String>(['contents', 'tabs', 0, 'title']);
  /// ```
  T? path<T>(List<dynamic> keys) {
    dynamic current = this;

    for (final key in keys) {
      if (current == null) return null;

      if (key is int) {
        // Array index access
        if (current is List && key >= 0 && key < current.length) {
          current = current[key];
        } else {
          return null;
        }
      } else if (key is String) {
        // Object key access
        if (current is Map<String, dynamic> && current.containsKey(key)) {
          current = current[key];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }

    return current as T?;
  }

  /// Navigate to a value at the given path, throws ParsingException if missing.
  /// Use this when the field is required for correct operation.
  ///
  /// Example:
  /// ```dart
  /// final videoId = data.require<String>(['videoId'], context: 'player response');
  /// ```
  T require<T>(List<dynamic> keys, {String? context}) {
    final result = path<T>(keys);
    if (result == null) {
      final pathStr = keys.map((k) => k.toString()).join(' -> ');
      throw ParsingException(
        'Missing required field${context != null ? ' in $context' : ''}: $pathStr',
        path: pathStr,
      );
    }
    return result;
  }

  /// Try multiple paths and return the first non-null result.
  /// Useful when YouTube uses different structures for different clients.
  ///
  /// Example:
  /// ```dart
  /// final contents = data.tryPaths<List>([
  ///   ['contents', 'singleColumnBrowseResultsRenderer', 'tabs', 0, 'content'],
  ///   ['contents', 'twoColumnBrowseResultsRenderer', 'tabs', 0, 'content'],
  /// ]);
  /// ```
  T? tryPaths<T>(List<List<dynamic>> paths) {
    for (final path in paths) {
      final result = this.path<T>(path);
      if (result != null) return result;
    }
    return null;
  }
}

/// Extension for navigating lists in JSON
extension JsonListPath on List<dynamic> {
  /// Safely get element at index, returns null if out of bounds
  T? at<T>(int index) {
    if (index >= 0 && index < length) {
      return this[index] as T?;
    }
    return null;
  }
}
