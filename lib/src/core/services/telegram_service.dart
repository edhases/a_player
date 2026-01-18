import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'log_service.dart';

/// Service for sending logs to Telegram Bot
class TelegramService {
  static const String _botTokenKey = 'telegram_bot_token';
  static const String _chatIdKey = 'telegram_chat_id';
  static const String _baseUrl = 'https://api.telegram.org/bot';

  // Default credentials for sending logs to developer
  static const String _defaultBotToken =
      '8319336094:AAFjsqn5zKEGOwc5yZu0dbDIby00gv8KrUg';
  static const String _defaultChatId = '-1003668290632';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _botToken;
  String? _chatId;

  /// Initialize and load saved credentials
  Future<void> init() async {
    try {
      _botToken = await _storage.read(key: _botTokenKey);
      _chatId = await _storage.read(key: _chatIdKey);
      debugPrint('[TelegramService] Initialized, configured: ${isConfigured}');
    } catch (e) {
      debugPrint('[TelegramService] Failed to init: $e');
    }
  }

  /// Get effective bot token (user-configured or default)
  String get _effectiveBotToken => (_botToken != null && _botToken!.isNotEmpty)
      ? _botToken!
      : _defaultBotToken;

  /// Get effective chat ID (user-configured or default)
  String get _effectiveChatId =>
      (_chatId != null && _chatId!.isNotEmpty) ? _chatId! : _defaultChatId;

  /// Check if Telegram is configured (always true with defaults)
  bool get isConfigured => true;

  /// Save Telegram credentials
  Future<void> configure(
      {required String botToken, required String chatId}) async {
    try {
      await _storage.write(key: _botTokenKey, value: botToken);
      await _storage.write(key: _chatIdKey, value: chatId);
      _botToken = botToken;
      _chatId = chatId;
      debugPrint('[TelegramService] Configured successfully');
    } catch (e) {
      debugPrint('[TelegramService] Failed to save config: $e');
      rethrow;
    }
  }

  /// Clear Telegram credentials
  Future<void> clearConfig() async {
    await _storage.delete(key: _botTokenKey);
    await _storage.delete(key: _chatIdKey);
    _botToken = null;
    _chatId = null;
  }

  /// Send log file to Telegram
  Future<bool> sendLogs({String? caption}) async {
    if (!isConfigured) {
      debugPrint('[TelegramService] Not configured, cannot send logs');
      return false;
    }

    try {
      final logService = GetIt.I<LogService>();
      final logFile = await logService.getLogFile();

      if (logFile == null || !await logFile.exists()) {
        debugPrint('[TelegramService] No log file to send');
        return false;
      }

      final deviceInfo = await logService.getDeviceInfoSummary();
      final finalCaption = caption ??
          '📋 Oxide Player Logs\n📱 $deviceInfo\n🕐 ${DateTime.now().toIso8601String()}';

      return await sendDocument(logFile, finalCaption);
    } catch (e) {
      debugPrint('[TelegramService] Failed to send logs: $e');
      return false;
    }
  }

  /// Send a document to Telegram
  Future<bool> sendDocument(File file, String caption) async {
    try {
      final url = Uri.parse('$_baseUrl$_effectiveBotToken/sendDocument');

      final request = http.MultipartRequest('POST', url);
      request.fields['chat_id'] = _effectiveChatId;
      request.fields['caption'] = caption;
      request.files
          .add(await http.MultipartFile.fromPath('document', file.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        debugPrint('[TelegramService] Document sent successfully');
        return true;
      } else {
        debugPrint(
            '[TelegramService] Failed to send: ${response.statusCode} - $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('[TelegramService] Error sending document: $e');
      return false;
    }
  }

  /// Send a text message to Telegram
  Future<bool> sendMessage(String text) async {
    try {
      final url = Uri.parse('$_baseUrl$_effectiveBotToken/sendMessage');

      final response = await http.post(url, body: {
        'chat_id': _effectiveChatId,
        'text': text,
        'parse_mode': 'HTML',
      });

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[TelegramService] Error sending message: $e');
      return false;
    }
  }

  /// Test connection with current credentials
  Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$_baseUrl$_effectiveBotToken/getMe');
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
