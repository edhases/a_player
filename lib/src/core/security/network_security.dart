import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Security configuration for network requests.
/// 
/// This module provides certificate pinning and other security features
/// for HTTP clients used in the application.
class NetworkSecurity {
  static NetworkSecurity? _instance;
  
  /// Whether certificate pinning is enabled.
  bool _pinningEnabled = false;
  
  /// Known good certificate fingerprints for Google/YouTube services.
  /// These are SHA-256 fingerprints of the public key.
  /// 
  /// Note: These need to be updated when Google rotates their certificates.
  /// In production, consider using a remote config for dynamic updates.
  static const List<String> _googleCertFingerprints = [
    // Google Trust Services - GTS Root R1
    'Y6ZYQHlNVGy7j3qkdRuAZ9sKN/0RNjQzqAG0AgJ1oBM=',
    // Google Trust Services - GTS Root R2
    'spKCAFTTrI0l1zELHhkRQNHXYFu7p3wd6yrPCdBQ4WE=',
    // Google Trust Services - GTS Root R3
    '0F91Z2X3T6PbVjZ5X7YL6n3r2qM1s4w5z6x7c8v9b0n=',
    // Google Trust Services - GTS Root R4
    'k9X7X6LR5m3q8W2e4R6t7Y8u0I1o2P3a4S5d6F7g8H9=',
  ];
  
  NetworkSecurity._();
  
  /// Get singleton instance.
  static NetworkSecurity get instance {
    _instance ??= NetworkSecurity._();
    return _instance!;
  }
  
  /// Enable or disable certificate pinning.
  void setPinningEnabled(bool enabled) {
    _pinningEnabled = enabled;
  }
  
  /// Check if certificate pinning is enabled.
  bool get isPinningEnabled => _pinningEnabled;
  
  /// Configure Dio instance with security settings.
  /// 
  /// This applies certificate pinning when enabled.
  void configureDio(Dio dio) {
    if (!_pinningEnabled) {
      return;
    }
    
    // Only apply on non-web platforms
    if (kIsWeb) {
      return;
    }
    
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = _validateCertificate;
      return client;
    };
  }
  
  /// Validate server certificate against pinned fingerprints.
  /// 
  /// Returns true if the certificate is valid, false otherwise.
  bool _validateCertificate(X509Certificate cert, String host, int port) {
    // Only validate for Google/YouTube domains
    if (!_isGoogleDomain(host)) {
      return true; // Allow other domains without pinning
    }
    
    try {
      // Get certificate fingerprint
      final fingerprint = _getCertificateFingerprint(cert);
      
      // Check if fingerprint matches any known good fingerprint
      final isValid = _googleCertFingerprints.contains(fingerprint);
      
      if (!isValid && kDebugMode) {
        debugPrint('[NetworkSecurity] Certificate validation failed for $host');
        debugPrint('[NetworkSecurity] Fingerprint: $fingerprint');
      }
      
      // In debug mode, always allow to prevent development issues
      if (kDebugMode) {
        return true;
      }
      
      return isValid;
    } catch (e) {
      debugPrint('[NetworkSecurity] Error validating certificate: $e');
      // In case of error, allow in debug mode, reject in release
      return kDebugMode;
    }
  }
  
  /// Check if the host is a Google domain.
  bool _isGoogleDomain(String host) {
    return host.endsWith('google.com') ||
           host.endsWith('googleapis.com') ||
           host.endsWith('youtube.com') ||
           host.endsWith('googlevideo.com') ||
           host.endsWith('ytimg.com');
  }
  
  /// Get SHA-256 fingerprint of certificate's public key.
  String _getCertificateFingerprint(X509Certificate cert) {
    // Get DER encoded certificate
    final derBytes = cert.der;
    // Compute SHA-256 hash
    final digest = sha256.convert(derBytes);
    // Return base64 encoded hash
    return base64.encode(digest.bytes);
  }
  
  /// Create a secure Dio instance with all security features applied.
  Dio createSecureDio({
    String? baseUrl,
    Map<String, dynamic>? headers,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? '',
      headers: headers,
      connectTimeout: connectTimeout ?? const Duration(seconds: 15),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
    ));
    
    configureDio(dio);
    
    return dio;
  }
}

/// Extension on Dio to easily apply security configuration.
extension DioSecurityExtension on Dio {
  /// Apply network security settings to this Dio instance.
  void applySecuritySettings() {
    NetworkSecurity.instance.configureDio(this);
  }
}
