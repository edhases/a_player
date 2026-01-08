import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GoogleAuthService {
  static const String _tokenKey = 'google_access_token';
  static const String _refreshTokenKey = 'google_refresh_token';
  static const String _clientIdAndroid = '801317878829-oql1pd3k5rv722ka6nqjdkug6pafkrre.apps.googleusercontent.com';
  
  late final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _storage;
  GoogleSignInAccount? _currentUser;
  GoogleSignInAuthentication? _lastAuth;

  GoogleAuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _googleSignIn = GoogleSignIn(
      clientId: _clientIdAndroid,
      scopes: ['https://www.googleapis.com/auth/youtube.readonly'],
    );
  }

  /// Get current signed-in user
  Future<GoogleSignInAccount?> get currentUser async {
    _currentUser ??= await _googleSignIn.signInSilently();
    return _currentUser;
  }

  /// Check if user is currently signed in
  Future<bool> isSignedIn() async {
    final user = await currentUser;
    return user != null;
  }

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      debugPrint('[GoogleAuthService] Starting sign-in flow...');
      _currentUser = await _googleSignIn.signIn();
      
      if (_currentUser != null) {
        await _cacheTokens(_currentUser!);
        debugPrint('[GoogleAuthService] Sign-in successful for: ${_currentUser!.email}');
      }
      return _currentUser;
    } catch (e) {
      debugPrint('[GoogleAuthService] Sign-in error: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      debugPrint('[GoogleAuthService] Signing out...');
      await _googleSignIn.signOut();
      _currentUser = null;
      _lastAuth = null;
      await _clearTokens();
      debugPrint('[GoogleAuthService] Sign-out successful');
    } catch (e) {
      debugPrint('[GoogleAuthService] Sign-out error: $e');
    }
  }

  /// Disconnect the app from Google account
  Future<void> disconnect() async {
    try {
      debugPrint('[GoogleAuthService] Disconnecting...');
      await _googleSignIn.disconnect();
      _currentUser = null;
      _lastAuth = null;
      await _clearTokens();
      debugPrint('[GoogleAuthService] Disconnect successful');
    } catch (e) {
      debugPrint('[GoogleAuthService] Disconnect error: $e');
    }
  }

  /// Get valid access token (refresh if expired)
  Future<String?> getAccessToken() async {
    try {
      _currentUser ??= await _googleSignIn.signInSilently();
      
      if (_currentUser == null) {
        debugPrint('[GoogleAuthService] No signed-in user');
        return null;
      }

      // Get authentication with automatic refresh
      _lastAuth = await _currentUser!.authentication;
      
      if (_lastAuth?.accessToken == null) {
        debugPrint('[GoogleAuthService] Failed to get access token');
        return null;
      }

      debugPrint('[GoogleAuthService] Access token retrieved (${_lastAuth!.accessToken!.length} chars)');
      await _cacheTokens(_currentUser!);
      return _lastAuth!.accessToken;
    } catch (e) {
      debugPrint('[GoogleAuthService] Error getting access token: $e');
      return null;
    }
  }

  /// Get ID token for additional identity verification
  Future<String?> getIdToken() async {
    try {
      _currentUser ??= await _googleSignIn.signInSilently();
      
      if (_currentUser == null) return null;

      _lastAuth = await _currentUser!.authentication;
      return _lastAuth?.idToken;
    } catch (e) {
      debugPrint('[GoogleAuthService] Error getting ID token: $e');
      return null;
    }
  }

  /// Cache tokens locally for offline access
  Future<void> _cacheTokens(GoogleSignInAccount user) async {
    try {
      final auth = await user.authentication;
      if (auth.accessToken != null) {
        await _storage.write(key: _tokenKey, value: auth.accessToken!);
        debugPrint('[GoogleAuthService] Access token cached');
      }
      if (auth.serverAuthCode != null) {
        await _storage.write(key: _refreshTokenKey, value: auth.serverAuthCode!);
      }
    } catch (e) {
      debugPrint('[GoogleAuthService] Error caching tokens: $e');
    }
  }

  /// Clear cached tokens
  Future<void> _clearTokens() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      debugPrint('[GoogleAuthService] Tokens cleared');
    } catch (e) {
      debugPrint('[GoogleAuthService] Error clearing tokens: $e');
    }
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    final user = await currentUser;
    return user?.email;
  }

  /// Get user display name
  Future<String?> getUserDisplayName() async {
    final user = await currentUser;
    return user?.displayName;
  }

  /// Get user profile picture URL
  Future<String?> getUserPhotoUrl() async {
    final user = await currentUser;
    return user?.photoUrl;
  }
}
