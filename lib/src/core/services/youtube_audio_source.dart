import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import 'youtube_helper.dart';

// A custom AudioSource that fetches the stream URL for a YouTube video
// just in time and supports caching of the URL.
class YoutubeAudioSource extends StreamAudioSource {
  final String videoId;
  final YouTubeHelper _ytHelper;
  String? _cachedUrl;
  DateTime? _cacheTime;
  bool _isPrefetching = false;
  Completer<void>? _prefetchCompleter;

  YoutubeAudioSource(this.videoId, this._ytHelper, {dynamic tag})
      : super(tag: tag ?? videoId);

  /// Prefetch the audio URL before playback starts.
  /// This prevents race conditions where the player tries to stream
  /// before the URL is available.
  Future<void> prefetch() async {
    if (_cachedUrl != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < const Duration(hours: 4)) {
      debugPrint('[YoutubeAudioSource] URL already cached for $videoId');
      return;
    }

    if (_isPrefetching) {
      debugPrint('[YoutubeAudioSource] Already prefetching, waiting...');
      await _prefetchCompleter?.future;
      return;
    }

    _isPrefetching = true;
    _prefetchCompleter = Completer<void>();

    try {
      debugPrint('[YoutubeAudioSource] Prefetching URL for $videoId...');
      _cachedUrl = await _ytHelper.getAudioUrl(videoId);
      _cacheTime = DateTime.now();
      debugPrint(
          '[YoutubeAudioSource] Prefetch complete: ${_cachedUrl?.substring(0, 50)}...');
    } catch (e) {
      debugPrint('[YoutubeAudioSource] Prefetch error: $e');
      rethrow;
    } finally {
      _isPrefetching = false;
      _prefetchCompleter?.complete();
    }
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // If the cached URL is null or older than 4 hours, fetch a new one.
    if (_cachedUrl == null ||
        _cacheTime == null ||
        DateTime.now().difference(_cacheTime!) > const Duration(hours: 4)) {
      // Wait for any ongoing prefetch
      if (_isPrefetching) {
        debugPrint('[YoutubeAudioSource] request() waiting for prefetch...');
        await _prefetchCompleter?.future;
      }

      // If still null, fetch now
      if (_cachedUrl == null) {
        try {
          debugPrint('[YoutubeAudioSource] Fetching URL in request()...');
          _cachedUrl = await _ytHelper.getAudioUrl(videoId);
          _cacheTime = DateTime.now();
        } catch (e) {
          // Propagate the error if the URL fetch fails.
          throw Exception('Failed to get audio URL for videoId: $videoId - $e');
        }
      }
    }

    // If after trying to fetch, the URL is still null, we cannot proceed.
    if (_cachedUrl == null) {
      throw Exception('Audio URL for videoId: $videoId is null.');
    }

    final uri = Uri.parse(_cachedUrl!);
    final headers = <String, String>{};
    if (start != null || end != null) {
      headers['Range'] = 'bytes=${start ?? 0}-${end ?? ""}';
    }

    final client = http.Client();
    final request = http.Request('GET', uri)..headers.addAll(headers);
    final response = await client.send(request);

    final contentLength = response.contentLength;
    final statusCode = response.statusCode;

    // Check if the server supports range requests and returned a partial response.
    if (statusCode < 200 || statusCode >= 300) {
      client.close();
      throw Exception('HTTP request failed with status: $statusCode');
    }

    final contentRange = response.headers['content-range'];
    int? totalLength;
    if (contentRange != null) {
      final parts = contentRange.split('/');
      if (parts.length == 2) {
        try {
          totalLength = int.parse(parts[1]);
        } catch (_) {
          // Ignore parsing errors.
        }
      }
    }

    return StreamAudioResponse(
      sourceLength: totalLength,
      contentLength: contentLength,
      offset: start ?? 0,
      stream: response.stream.handleError((error) {
        client.close();
        throw error;
      }, test: (error) => true).transform(StreamTransformer.fromHandlers(
        handleDone: (sink) {
          client.close();
          sink.close();
        },
      )),
      contentType: response.headers['content-type'] ?? 'audio/mpeg',
    );
  }
}
