import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'telegram_service.dart';

/// Log levels for categorizing messages
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Error categories for structured logging
enum ErrorCategory {
  playback, // Audio playback issues
  network, // Network/API errors
  cache, // Cache/storage issues
  auth, // Authentication errors
  ui, // UI/rendering errors
  database, // Database errors
  general, // Uncategorized errors
}

/// Aggregated error entry for batching
class _AggregatedError {
  final ErrorCategory category;
  final String message;
  int count;
  DateTime firstOccurrence;
  DateTime lastOccurrence;

  _AggregatedError({
    required this.category,
    required this.message,
    DateTime? time,
  })  : count = 1,
        firstOccurrence = time ?? DateTime.now(),
        lastOccurrence = time ?? DateTime.now();

  void increment() {
    count++;
    lastOccurrence = DateTime.now();
  }

  String get key => '${category.name}:${message.hashCode}';
}

/// Playback analytics data
class PlaybackAnalytics {
  int songsPlayed = 0;
  int playbackErrors = 0;
  int cacheHits = 0;
  int networkStreams = 0;
  Duration totalPlaytime = Duration.zero;
  DateTime sessionStart = DateTime.now();
  final Map<String, int> errorCounts = {};

  Duration get sessionDuration => DateTime.now().difference(sessionStart);

  Map<String, dynamic> toSummary() => {
        'songsPlayed': songsPlayed,
        'playbackErrors': playbackErrors,
        'cacheHits': cacheHits,
        'networkStreams': networkStreams,
        'totalPlaytime': totalPlaytime.inMinutes,
        'sessionMinutes': sessionDuration.inMinutes,
        'topErrors': _topErrors(3),
      };

  List<MapEntry<String, int>> _topErrors(int n) {
    final sorted = errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }

  void reset() {
    songsPlayed = 0;
    playbackErrors = 0;
    cacheHits = 0;
    networkStreams = 0;
    totalPlaytime = Duration.zero;
    errorCounts.clear();
    sessionStart = DateTime.now();
  }
}

/// Centralized logging service with local file storage and Telegram integration
class LogService {
  int _maxFileSize = 10 * 1024 * 1024; // Default 10MB
  static const int _maxFiles = 3;
  static const String _logFileName = 'oxide_player.log';

  // Error aggregation
  static const Duration _aggregationWindow = Duration(minutes: 5);
  final Map<String, _AggregatedError> _errorBuffer = {};
  Timer? _digestTimer;

  // App info
  String _appVersion = 'unknown';
  String _buildNumber = 'unknown';

  // Analytics
  final PlaybackAnalytics analytics = PlaybackAnalytics();

  File? _logFile;
  bool _initialized = false;

  /// Patterns to sanitize from logs (cookies, tokens, etc.)
  static final List<RegExp> _sensitivePatterns = [
    RegExp(r'Cookie:\s*[^\n]+', caseSensitive: false),
    RegExp(r'Authorization:\s*[^\n]+', caseSensitive: false),
    RegExp(r'SAPISID[=:][^\s;]+', caseSensitive: false),
    RegExp(r'SID[=:][^\s;]+', caseSensitive: false),
    RegExp(r'__Secure-\w+[=:][^\s;]+', caseSensitive: false),
    RegExp(r'token[=:][^\s,]+', caseSensitive: false),
  ];

  /// Set the maximum size of a single log file
  void setMaxFileSize(int bytes) {
    _maxFileSize = bytes;
    info('Log limit set to ${_formatBytes(bytes)}');
    // Trigger rotation check if needed
    _checkForRotation();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _checkForRotation() async {
    if (_logFile != null && await _logFile!.exists()) {
      if ((await _logFile!.length()) > _maxFileSize) {
        await _rotateFiles();
      }
    }
  }

  /// Initialize the log service
  Future<void> init() async {
    if (_initialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      _logFile = File('${logsDir.path}/$_logFileName');
      _initialized = true;

      // Load app version
      await _loadAppVersion();

      // Start error digest timer
      _startDigestTimer();

      // Log startup info
      info('LogService initialized (v$_appVersion+$_buildNumber)');
      await _logDeviceInfo();
    } catch (e) {
      debugPrint('[LogService] Failed to initialize: $e');
    }
  }

  /// Load app version from package info
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    } catch (e) {
      debugPrint('[LogService] Failed to load app version: $e');
    }
  }

  /// Start timer for sending error digest
  void _startDigestTimer() {
    _digestTimer?.cancel();
    _digestTimer = Timer.periodic(_aggregationWindow, (_) {
      _sendErrorDigest();
    });
  }

  /// Stop the digest timer
  void dispose() {
    _digestTimer?.cancel();
    _sendErrorDigest(); // Flush remaining errors
  }

  /// Log device info at startup
  Future<void> _logDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        info(
            'Device: ${android.manufacturer} ${android.model}, Android ${android.version.release} (SDK ${android.version.sdkInt})');
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        info('Device: ${ios.name} ${ios.model}, iOS ${ios.systemVersion}');
      }
    } catch (e) {
      warning('Failed to get device info: $e');
    }
  }

  /// Main logging method
  void log(LogLevel level, String message,
      {Object? error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final sanitizedMessage = _sanitize(message);

    var logLine = '[$timestamp] [$levelStr] $sanitizedMessage';

    if (error != null) {
      logLine += '\n  Error: ${_sanitize(error.toString())}';
    }
    if (stackTrace != null) {
      final stackLines =
          stackTrace.toString().split('\n').take(20).join('\n         ');
      logLine += '\n  Stack: $stackLines';
    }

    // Always print to debug console
    debugPrint(logLine);

    // Write to file
    _writeToFile(logLine);

    // Forward critical errors to Telegram (Async, fire-and-forget)
    if (level == LogLevel.error) {
      _sendToTelegram(logLine);
    }
  }

  /// Patterns to filter out from Telegram notifications (expected/non-critical errors)
  static final List<RegExp> _telegramFilterPatterns = [
    RegExp(r'android.*client', caseSensitive: false),
    RegExp(r'ANDROID_MUSIC', caseSensitive: false),
    RegExp(r'TV_EMBEDDED', caseSensitive: false),
    RegExp(r'fallback', caseSensitive: false),
  ];

  void _sendToTelegram(String message) async {
    try {
      // Filter out expected/non-critical errors
      for (final pattern in _telegramFilterPatterns) {
        if (pattern.hasMatch(message)) {
          debugPrint(
              '[LogService] Telegram notification filtered: ${pattern.pattern}');
          return;
        }
      }

      // Aggregate error instead of sending immediately
      // Detect category from message
      final category = _detectCategory(message);
      _aggregateError(category, message.split('\n').first);
    } catch (e) {
      // Ignore telegram errors to avoid loops
    }
  }

  /// Detect error category from message
  ErrorCategory _detectCategory(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('audio') ||
        lower.contains('player') ||
        lower.contains('playback') ||
        lower.contains('stream')) {
      return ErrorCategory.playback;
    }
    if (lower.contains('network') ||
        lower.contains('http') ||
        lower.contains('connection') ||
        lower.contains('timeout') ||
        lower.contains('api')) {
      return ErrorCategory.network;
    }
    if (lower.contains('cache') ||
        lower.contains('storage') ||
        lower.contains('file') ||
        lower.contains('disk')) {
      return ErrorCategory.cache;
    }
    if (lower.contains('auth') ||
        lower.contains('login') ||
        lower.contains('token') ||
        lower.contains('sign')) {
      return ErrorCategory.auth;
    }
    if (lower.contains('widget') ||
        lower.contains('render') ||
        lower.contains('build') ||
        lower.contains('layout')) {
      return ErrorCategory.ui;
    }
    if (lower.contains('database') ||
        lower.contains('db') ||
        lower.contains('sqlite') ||
        lower.contains('drift')) {
      return ErrorCategory.database;
    }
    return ErrorCategory.general;
  }

  /// Convenience methods
  void debug(String message) => log(LogLevel.debug, message);
  void info(String message) => log(LogLevel.info, message);
  void warning(String message, {Object? error}) =>
      log(LogLevel.warning, message, error: error);
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, error: error, stackTrace: stackTrace);

  /// Categorized error logging with aggregation
  void errorWithCategory(
    ErrorCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Log to file normally
    log(LogLevel.error, '[${category.name.toUpperCase()}] $message',
        error: error, stackTrace: stackTrace);

    // Track in analytics
    analytics.playbackErrors++;
    analytics.errorCounts[category.name] =
        (analytics.errorCounts[category.name] ?? 0) + 1;

    // Aggregate for Telegram digest
    _aggregateError(category, message);
  }

  /// Add error to aggregation buffer
  void _aggregateError(ErrorCategory category, String message) {
    // Create a simplified key (first 100 chars of message)
    final shortMessage =
        message.length > 100 ? message.substring(0, 100) : message;
    final key = '${category.name}:${shortMessage.hashCode}';

    if (_errorBuffer.containsKey(key)) {
      _errorBuffer[key]!.increment();
    } else {
      _errorBuffer[key] = _AggregatedError(
        category: category,
        message: shortMessage,
      );
    }
  }

  /// Send aggregated error digest to Telegram
  Future<void> _sendErrorDigest() async {
    if (_errorBuffer.isEmpty) return;

    try {
      if (!GetIt.I.isRegistered<TelegramService>()) return;

      final telegram = GetIt.I<TelegramService>();
      final deviceInfo = await getDeviceInfoSummary();

      // Group by category
      final byCategory = <ErrorCategory, List<_AggregatedError>>{};
      for (final err in _errorBuffer.values) {
        byCategory.putIfAbsent(err.category, () => []).add(err);
      }

      // Build digest message
      final buffer = StringBuffer();
      buffer.writeln('📊 <b>Error Digest</b>');
      buffer.writeln('📱 <i>$deviceInfo</i>');
      buffer.writeln('🏷️ v$_appVersion+$_buildNumber');
      buffer.writeln('⏱️ Session: ${analytics.sessionDuration.inMinutes}min');
      buffer.writeln(
          '🎵 Songs: ${analytics.songsPlayed} | Errors: ${analytics.playbackErrors}');
      buffer.writeln('');

      for (final category in byCategory.keys) {
        final emoji = _categoryEmoji(category);
        buffer.writeln('$emoji <b>${category.name.toUpperCase()}</b>');

        for (final err in byCategory[category]!) {
          if (err.count > 1) {
            buffer.writeln('  • ${err.message} <i>(×${err.count})</i>');
          } else {
            buffer.writeln('  • ${err.message}');
          }
        }
        buffer.writeln('');
      }

      await telegram.sendMessage(buffer.toString());
      _errorBuffer.clear();
    } catch (e) {
      debugPrint('[LogService] Failed to send digest: $e');
    }
  }

  /// Get emoji for error category
  String _categoryEmoji(ErrorCategory category) {
    return switch (category) {
      ErrorCategory.playback => '🎧',
      ErrorCategory.network => '🌐',
      ErrorCategory.cache => '💾',
      ErrorCategory.auth => '🔐',
      ErrorCategory.ui => '🖼️',
      ErrorCategory.database => '🗄️',
      ErrorCategory.general => '⚠️',
    };
  }

  /// Record song play for analytics
  void recordSongPlayed({bool fromCache = false}) {
    analytics.songsPlayed++;
    if (fromCache) {
      analytics.cacheHits++;
    } else {
      analytics.networkStreams++;
    }
  }

  /// Record playtime for analytics
  void recordPlaytime(Duration duration) {
    analytics.totalPlaytime += duration;
  }

  /// Get analytics summary for Telegram
  Future<void> sendAnalyticsSummary() async {
    try {
      if (!GetIt.I.isRegistered<TelegramService>()) return;

      final telegram = GetIt.I<TelegramService>();
      final deviceInfo = await getDeviceInfoSummary();
      final summary = analytics.toSummary();

      final buffer = StringBuffer();
      buffer.writeln('📈 <b>Session Analytics</b>');
      buffer.writeln('📱 <i>$deviceInfo</i>');
      buffer.writeln('🏷️ v$_appVersion+$_buildNumber');
      buffer.writeln('');
      buffer.writeln('🎵 Songs played: ${summary['songsPlayed']}');
      buffer.writeln('💾 From cache: ${summary['cacheHits']}');
      buffer.writeln('🌐 Streamed: ${summary['networkStreams']}');
      buffer.writeln('⏱️ Session: ${summary['sessionMinutes']} min');
      buffer.writeln('🎧 Playtime: ${summary['totalPlaytime']} min');
      buffer.writeln('❌ Errors: ${summary['playbackErrors']}');

      final topErrors = summary['topErrors'] as List<MapEntry<String, int>>;
      if (topErrors.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('<b>Top Errors:</b>');
        for (final err in topErrors) {
          buffer.writeln('  • ${err.key}: ${err.value}');
        }
      }

      await telegram.sendMessage(buffer.toString());
    } catch (e) {
      debugPrint('[LogService] Failed to send analytics: $e');
    }
  }

  /// Sanitize sensitive data from log message
  String _sanitize(String message) {
    var sanitized = message;
    for (final pattern in _sensitivePatterns) {
      sanitized = sanitized.replaceAll(pattern, '[REDACTED]');
    }
    return sanitized;
  }

  /// Write log line to file with rotation
  Future<void> _writeToFile(String logLine) async {
    if (_logFile == null || !_initialized) return;

    try {
      // Check for rotation
      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > _maxFileSize) {
          await _rotateFiles();
        }
      }

      // Append to log file
      await _logFile!.writeAsString('$logLine\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('[LogService] Failed to write log: $e');
    }
  }

  /// Rotate log files (app.log → app.1.log → app.2.log → delete)
  Future<void> _rotateFiles() async {
    if (_logFile == null) return;

    try {
      final dir = _logFile!.parent.path;

      // Delete oldest file
      final oldest = File('$dir/$_logFileName.${_maxFiles - 1}');
      if (await oldest.exists()) {
        await oldest.delete();
      }

      // Shift files
      for (var i = _maxFiles - 2; i >= 1; i--) {
        final file = File('$dir/$_logFileName.$i');
        if (await file.exists()) {
          await file.rename('$dir/$_logFileName.${i + 1}');
        }
      }

      // Rename current log
      if (await _logFile!.exists()) {
        await _logFile!.rename('$dir/$_logFileName.1');
      }

      // Create new empty log file
      _logFile = File('$dir/$_logFileName');
    } catch (e) {
      debugPrint('[LogService] Failed to rotate logs: $e');
    }
  }

  /// Get all logs as string (for display or sending)
  Future<String> getLogs() async {
    if (_logFile == null) return 'Log service not initialized';

    try {
      final buffer = StringBuffer();
      final dir = _logFile!.parent.path;

      // Read all log files in order (oldest first)
      for (var i = _maxFiles - 1; i >= 1; i--) {
        final file = File('$dir/$_logFileName.$i');
        if (await file.exists()) {
          buffer.writeln(await file.readAsString());
        }
      }

      // Current log file
      if (await _logFile!.exists()) {
        buffer.writeln(await _logFile!.readAsString());
      }

      return buffer.toString();
    } catch (e) {
      return 'Failed to read logs: $e';
    }
  }

  /// Get log file for sharing
  Future<File?> getLogFile() async {
    if (_logFile == null) return null;

    try {
      // Create combined log file for export
      final logs = await getLogs();
      final dir = _logFile!.parent.path;
      final exportFile = File('$dir/oxide_player_logs_export.txt');
      await exportFile.writeAsString(logs);
      return exportFile;
    } catch (e) {
      error('Failed to export logs', error: e);
      return null;
    }
  }

  /// Clear all log files
  Future<void> clearLogs() async {
    if (_logFile == null) return;

    try {
      final dir = _logFile!.parent.path;

      // Delete rotated files
      for (var i = 1; i < _maxFiles; i++) {
        final file = File('$dir/$_logFileName.$i');
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Clear current log
      if (await _logFile!.exists()) {
        await _logFile!.writeAsString('');
      }

      info('Logs cleared');
    } catch (e) {
      debugPrint('[LogService] Failed to clear logs: $e');
    }
  }

  /// Get device info summary for log header
  Future<String> getDeviceInfoSummary() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        return '${android.manufacturer} ${android.model} | Android ${android.version.release}';
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return '${ios.name} ${ios.model} | iOS ${ios.systemVersion}';
      }
    } catch (e) {
      // ignore
    }
    return 'Unknown Device';
  }
}
