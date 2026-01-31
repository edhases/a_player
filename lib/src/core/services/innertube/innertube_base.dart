import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../exceptions/youtube_exceptions.dart';
import '../../security/network_security.dart';
import '../google_auth_service.dart';
import 'innertube_constants.dart';
import 'innertube_parser.dart';

/// Rate limiter for API requests
class RateLimiter {
  final int requestsPerSecond;
  final List<DateTime> _timestamps = [];

  RateLimiter({this.requestsPerSecond = 3});

  Future<void> throttle() async {
    final now = DateTime.now();
    _timestamps.removeWhere(
        (ts) => now.difference(ts).inMilliseconds > 1000);

    if (_timestamps.length >= requestsPerSecond) {
      final oldest = _timestamps.first;
      final waitTime = 1000 - now.difference(oldest).inMilliseconds;
      if (waitTime > 0) {
        await Future.delayed(Duration(milliseconds: waitTime));
      }
    }

    _timestamps.add(DateTime.now());
  }
}

/// Base class for InnerTube services with shared functionality
abstract class InnerTubeBase {
  @protected
  final Dio dio;
  @protected
  final GoogleAuthService authService;
  @protected
  final RateLimiter rateLimiter;
  @protected
  final Logger logger;
  @protected
  final InnerTubeParser parser;

  InnerTubeBase({
    required this.authService,
    RateLimiter? rateLimiter,
    Logger? logger,
    Dio? dio,
    InnerTubeParser? parser,
  })  : rateLimiter = rateLimiter ?? RateLimiter(),
        logger = logger ?? Logger(printer: PrettyPrinter(methodCount: 0)),
        dio = dio ?? _createDefaultDio(),
        parser = parser ?? InnerTubeParser();

  static Dio _createDefaultDio() {
    final dio = Dio(BaseOptions(
      baseUrl: InnerTubeConstants.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Origin': 'https://music.youtube.com',
        'Referer': 'https://music.youtube.com/',
        'User-Agent': InnerTubeConstants.userAgent,
      },
      queryParameters: {
        'key': InnerTubeConstants.webApiKey,
        'prettyPrint': 'false',
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
    ));
    
    // Apply security settings (certificate pinning when enabled)
    dio.applySecuritySettings();
    
    return dio;
  }

  /// Get web context body
  @protected
  Map<String, dynamic> webContextBody() {
    return {
      'context': {
        'client': {
          'clientName': 'WEB_REMIX',
          'clientVersion': '1.20240904.01.00',
          'hl': 'en',
          'gl': 'US',
          'experimentIds': [],
          'experimentsToken': '',
          'browserName': 'Chrome',
          'browserVersion': '120.0.0.0',
          'platform': 'DESKTOP',
          'utcOffsetMinutes': 0,
          'originalUrl': 'https://music.youtube.com/',
        },
        'user': {
          'lockedSafetyMode': false,
        },
        'request': {
          'useSsl': true,
          'internalExperimentFlags': [],
        },
      },
    };
  }

  /// Get TV HTML5 context body (for stream extraction)
  @protected
  Map<String, dynamic> tvContextBody() {
    return {
      'context': {
        'client': {
          'clientName': 'TVHTML5_SIMPLY_EMBEDDED_PLAYER',
          'clientVersion': '2.0',
          'clientScreen': 'EMBED',
          'hl': 'en',
          'gl': 'US',
          'platform': 'TV',
        },
        'thirdParty': {
          'embedUrl': 'https://www.youtube.com',
        },
      },
    };
  }

  /// Get Android Music context body
  @protected
  Map<String, dynamic> androidMusicContextBody() {
    return {
      'context': {
        'client': {
          'clientName': 'ANDROID_MUSIC',
          'clientVersion': '7.27.52',
          'androidSdkVersion': 30,
          'hl': 'en',
          'gl': 'US',
          'platform': 'MOBILE',
          'osName': 'Android',
          'osVersion': '11',
        },
      },
    };
  }

  /// Add auth headers if authenticated
  @protected
  Future<void> addAuthHeaders() async {
    // Get all auth headers from the auth service
    final authHeaders = await authService.getAuthHeaders();

    if (authHeaders.containsKey('Cookie')) {
      debugPrint('[InnerTubeBase] Auth: Active session headers applying...');

      // Add ALL headers (Cookie, Authorization, User-Agent, etc.)
      dio.options.headers.addAll(authHeaders);

      // Ensure Origin is in place (important for SAPISIDHASH)
      dio.options.headers['Origin'] = 'https://music.youtube.com';
    } else {
      debugPrint(
          '[InnerTubeBase] Auth: No active session. Personalization disabled.');
      dio.options.headers.remove('Cookie');
      dio.options.headers.remove('Authorization');
    }
  }

  /// Generic POST request helper
  @protected
  Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? extraHeaders,
  }) async {
    await rateLimiter.throttle();
    await addAuthHeaders();

    final options =
        extraHeaders != null ? Options(headers: extraHeaders) : null;

    try {
      final response = await dio.post(endpoint, data: body, options: options);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Handle Dio errors
  void _handleDioError(DioException e) {
    if (e.response != null) {
      final status = e.response!.statusCode;
      final data = e.response!.data;

      String? errorMessage;

      if (data is Map) {
        errorMessage = data['error']?['message']?.toString();
      }

      if (status == 403) {
        throw ContentRestrictedException(
          errorMessage ?? 'Access forbidden - authentication may be required',
        );
      }

      if (status == 401) {
        // Token expired or invalid
        authService.signOut();
        throw const AuthenticationException(
          'Authentication expired - please sign in again',
        );
      }

      throw NetworkException(
        errorMessage ?? 'Request failed (status: $status)',
      );
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw const NetworkException(
        'Connection timeout - please check your internet connection',
        isTimeout: true,
      );
    } else {
      throw NetworkException(
        'Network error: ${e.message}',
      );
    }
  }

  /// Browse continuation for pagination
  @protected
  Future<Map<String, dynamic>?> browseContinuation(
      String continuationToken) async {
    try {
      final body = webContextBody();
      final response = await dio.post(
        '/browse',
        data: body,
        queryParameters: {
          'ctoken': continuationToken,
          'continuation': continuationToken,
          'type': 'next',
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[InnerTubeBase] Browse continuation error: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    dio.close();
  }
}
