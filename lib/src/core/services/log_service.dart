import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'telegram_service.dart';

/// Log levels for categorizing messages
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Centralized logging service with local file storage and Telegram integration
class LogService {
  int _maxFileSize = 10 * 1024 * 1024; // Default 10MB
  static const int _maxFiles = 3;
  static const String _logFileName = 'oxide_player.log';

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

      // Log startup info
      info('LogService initialized');
      await _logDeviceInfo();
    } catch (e) {
      debugPrint('[LogService] Failed to initialize: $e');
    }
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

      if (GetIt.I.isRegistered<TelegramService>()) {
        final deviceInfo = await getDeviceInfoSummary();
        final formattedMessage = '🚨 <b>ERROR</b>\n'
            '📱 <i>$deviceInfo</i>\n'
            '🕐 ${DateTime.now().toIso8601String()}\n\n'
            '<pre>$message</pre>';
        GetIt.I<TelegramService>().sendMessage(formattedMessage);
      }
    } catch (e) {
      // Ignore telegram errors to avoid loops
    }
  }

  /// Convenience methods
  void debug(String message) => log(LogLevel.debug, message);
  void info(String message) => log(LogLevel.info, message);
  void warning(String message, {Object? error}) =>
      log(LogLevel.warning, message, error: error);
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, error: error, stackTrace: stackTrace);

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
