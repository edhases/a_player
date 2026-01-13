import 'dart:convert';
import 'package:crypto/crypto.dart'; // Import for SAPISID hash generation
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GoogleAuthService {
  final FlutterSecureStorage _storage;
  static const String _cookieKey = 'auth_cookie';

  GoogleAuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Зберегти cookies після WebView логіну
  Future<void> saveCookies(String cookieHeader) async {
    await _storage.write(key: _cookieKey, value: cookieHeader);
    debugPrint('[GoogleAuthService] Cookies saved');
  }

  /// Отримати Cookie header для запитів
  Future<String?> getCookies() async {
    return await _storage.read(key: _cookieKey);
  }

  /// Очистити cookies та вийти з акаунта
  Future<void> logout() async {
    await _storage.delete(key: _cookieKey);
    debugPrint('[GoogleAuthService] Cookies cleared');
  }

  /// Отримати headers для HTTP запитів
  Future<Map<String, String>> getAuthHeaders() async {
    final cookie = await getCookies();
    final Map<String, String> headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept-Language': 'uk-UA,uk;q=0.9,en-US;q=0.8,en;q=0.7',
    };

    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;

      // Extract SAPISID for hash generation
      final sapisid = _extractSapisid(cookie);
      if (sapisid != null) {
        headers['Authorization'] = _generateSapisidHash(sapisid);
      }
    }

    return headers;
  }

  /// Parsing SAPISID from cookie string
  String? _extractSapisid(String cookieHeader) {
    try {
      final cookies = cookieHeader.split(';');
      for (final c in cookies) {
        final pair = c.trim().split('=');
        if (pair.length == 2 && pair[0] == 'SAPISID') {
          return pair[1];
        }
      }
    } catch (e) {
      debugPrint('[GoogleAuthService] Error extracting SAPISID: $e');
    }
    return null;
  }

  /// Generate SAPISIDHASH: Time_SHA1(Time + " " + SAPISID + " " + Origin)
  String _generateSapisidHash(String sapisid) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const origin = 'https://music.youtube.com';
    final msg = '$timestamp $sapisid $origin';
    final hash = sha1.convert(utf8.encode(msg)).toString();
    return 'SAPISIDHASH ${timestamp}_$hash';
  }

  /// Перевірити чи користувач залогінений
  Future<bool> isSignedIn() async {
    final cookie = await getCookies();
    return cookie != null && cookie.isNotEmpty;
  }

}