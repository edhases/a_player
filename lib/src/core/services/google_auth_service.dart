import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart'; // Import for SAPISID hash generation
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FlutterSecureStorage _storage;
  final GoogleSignIn _googleSignIn;
  static const String _cookieKey = 'auth_cookie';
  static const String _userEmailKey = 'user_email';

  // Stream to broadcast login status changes (true = logged in, false = logged out)
  final _loginStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onLoginStatusChanged => _loginStatusController.stream;

  GoogleAuthService({FlutterSecureStorage? storage, GoogleSignIn? googleSignIn})
      : _storage = storage ?? const FlutterSecureStorage(),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [
                'email',
                'https://www.googleapis.com/auth/youtube.readonly',
              ],
            );

  /// Зберегти cookies після WebView логіну
  Future<void> saveCookies(String cookieHeader) async {
    await _storage.write(key: _cookieKey, value: cookieHeader);
    _loginStatusController.add(true); // Added this line
    debugPrint('[GoogleAuthService] Cookies saved');
  }

  /// Отримати Cookie header для запитів
  Future<String?> getCookies() async {
    return await _storage.read(key: _cookieKey);
  }

  /// Отримати headers для HTTP запитів
  Future<Map<String, String>> getAuthHeaders() async {
    final cookie = await getCookies();
    final Map<String, String> headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept-Language': 'uk-UA,uk;q=0.9,en-US;q=0.8,en;q=0.7',
    };

    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;

      // Extract SAPISID for hash generation
      final sapisid = _extractSapisid(cookie);
      if (sapisid != null) {
        headers['Authorization'] = _generateSapisidHash(sapisid);
        debugPrint('[GoogleAuthService] Generated SAPISIDHASH for auth');
      }
    }

    return headers;
  }

  /// Parsing SAPISID from cookie string
  String? _extractSapisid(String cookieHeader) {
    try {
      // Use regex to find SAPISID value safely, handling optional quotes and semicolons
      // Matches: SAPISID=Value; or SAPISID=Value at end of string
      final regex = RegExp(r'(?:^|;\s*)SAPISID=([^;]+)');
      final match = regex.firstMatch(cookieHeader);

      if (match != null) {
        return match.group(1)?.trim();
      }
    } catch (e) {
      debugPrint('[GoogleAuthService] Error extracting SAPISID: $e');
    }
    return null;
  }

  /// Generate SAPISIDHASH: Time_SHA1(Time + " " + SAPISID + " " + Origin)
  String _generateSapisidHash(String sapisid) {
    // Current timestamp in seconds
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

  /// Зберегти email (опціонально для UI)
  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _userEmailKey, value: email);
  }

  /// Отримати email користувача
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  /// Вийти з системи
  Future<void> signOut() async {
    await _storage.delete(key: _cookieKey);
    await _storage.delete(key: _userEmailKey);
    _loginStatusController.add(false); // Added this line
    debugPrint('[GoogleAuthService] User signed out');
  }

  /// Perform native Google Sign-In and cache the user's email.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        await saveUserEmail(account.email);
        debugPrint(
            '[GoogleAuthService] Native sign-in successful for ${account.email}');
        // You might want to get tokens and use them with your backend or other services.
        // final GoogleSignInAuthentication auth = await account.authentication;
        // final String? idToken = auth.idToken;
        // final String? accessToken = auth.accessToken;
      }
      return account;
    } catch (e) {
      debugPrint('[GoogleAuthService] Error during native sign-in: $e');
      // Return null or rethrow a custom exception to be handled by the UI.
      return null;
    }
  }
}
