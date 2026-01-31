import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_secrets.dart';
import '../models/lyrics_model.dart';

/// KSoft.Si API service for lyrics and music recommendations
/// API Documentation: https://api.ksoft.si/
class KSoftService {
  static const String _baseUrl = 'https://api.ksoft.si';
  static const Duration _timeout = Duration(seconds: 10);

  final String _apiToken;
  final http.Client _client;

  KSoftService({
    String? apiToken,
    http.Client? client,
  })  : _apiToken = apiToken ?? AppSecrets.ksoftApiToken,
        _client = client ?? http.Client();

  /// Check if service is configured
  bool get isConfigured => _apiToken.isNotEmpty;

  /// Get authorization headers
  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiToken',
        'Content-Type': 'application/json',
      };

  /// Search for lyrics
  /// Returns synced lyrics if available (singalong field)
  Future<KSoftLyricsResult?> searchLyrics({
    required String query,
    bool textOnly = false,
    int limit = 5,
  }) async {
    if (!isConfigured) {
      debugPrint('[KSoft] API token not configured');
      return null;
    }

    try {
      final uri = Uri.parse('$_baseUrl/lyrics/search').replace(
        queryParameters: {
          'q': query,
          'text_only': textOnly.toString(),
          'limit': limit.toString(),
        },
      );

      debugPrint('[KSoft] Searching lyrics: $query');

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['data'] as List?;

        if (results == null || results.isEmpty) {
          debugPrint('[KSoft] No lyrics found');
          return null;
        }

        // Return best match
        final best = results.first;
        return KSoftLyricsResult.fromJson(best);
      } else if (response.statusCode == 429) {
        debugPrint('[KSoft] Rate limited');
        return null;
      } else {
        debugPrint('[KSoft] Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[KSoft] Search error: $e');
      return null;
    }
  }

  /// Get lyrics by artist and track name
  Future<LyricsModel?> getLyrics({
    required String trackName,
    required String artistName,
    double? duration,
  }) async {
    final query = '$artistName $trackName';
    final result = await searchLyrics(query: query, limit: 3);

    if (result == null) return null;

    // Convert to LyricsModel
    return LyricsModel(
      id: int.tryParse(result.id) ?? 0,
      trackName: result.name,
      artistName: result.artist,
      albumName: result.album ?? '',
      duration: duration ?? 0,
      instrumental: false,
      plainLyrics: result.lyrics,
      syncedLyrics: result.syncedLyrics ?? '',
      source: 'KSoft.Si',
    );
  }

  /// Get music recommendations based on YouTube video IDs
  Future<List<KSoftRecommendation>> getRecommendations({
    required List<String> videoIds,
    int limit = 5,
  }) async {
    if (!isConfigured) {
      debugPrint('[KSoft] API token not configured');
      return [];
    }

    if (videoIds.isEmpty) {
      return [];
    }

    try {
      final uri = Uri.parse('$_baseUrl/music/recommendations');

      final body = json.encode({
        'tracks': videoIds,
        'provider': 'youtube_ids',
        'recommend_type': 'youtube_id',
        'limit': limit.clamp(1, 5),
      });

      debugPrint('[KSoft] Getting recommendations for ${videoIds.length} tracks');

      final response = await _client
          .post(uri, headers: _headers, body: body)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks'] as List?;

        if (tracks == null || tracks.isEmpty) {
          debugPrint('[KSoft] No recommendations found');
          return [];
        }

        debugPrint('[KSoft] Found ${tracks.length} recommendations');
        return tracks.map((t) => KSoftRecommendation.fromJson(t)).toList();
      } else {
        debugPrint('[KSoft] Recommendations error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[KSoft] Recommendations error: $e');
      return [];
    }
  }

  /// Get track info by ID
  Future<KSoftTrackInfo?> getTrack(int trackId) async {
    if (!isConfigured) return null;

    try {
      final uri = Uri.parse('$_baseUrl/lyrics/track/$trackId/');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return KSoftTrackInfo.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('[KSoft] Get track error: $e');
      return null;
    }
  }

  /// Get artist info by ID
  Future<KSoftArtistInfo?> getArtist(int artistId) async {
    if (!isConfigured) return null;

    try {
      final uri = Uri.parse('$_baseUrl/lyrics/artist/$artistId/');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return KSoftArtistInfo.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('[KSoft] Get artist error: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// KSoft lyrics search result
class KSoftLyricsResult {
  final String id;
  final String name;
  final String artist;
  final int artistId;
  final String? album;
  final String? albumYear;
  final String lyrics;
  final String? albumArt;
  final int popularity;
  final List<KSoftSingalongLine>? singalong;
  final KSoftMeta? meta;

  KSoftLyricsResult({
    required this.id,
    required this.name,
    required this.artist,
    required this.artistId,
    this.album,
    this.albumYear,
    required this.lyrics,
    this.albumArt,
    this.popularity = 0,
    this.singalong,
    this.meta,
  });

  factory KSoftLyricsResult.fromJson(Map<String, dynamic> json) {
    List<KSoftSingalongLine>? singalong;
    if (json['singalong'] != null) {
      singalong = (json['singalong'] as List)
          .where((s) => s['line'] != null && s['line'].toString().isNotEmpty)
          .map((s) => KSoftSingalongLine.fromJson(s))
          .toList();
    }

    return KSoftLyricsResult(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      artist: json['artist'] ?? '',
      artistId: json['artist_id'] ?? 0,
      album: json['album'],
      albumYear: json['album_year'],
      lyrics: json['lyrics'] ?? '',
      albumArt: json['album_art'],
      popularity: json['popularity'] ?? 0,
      singalong: singalong,
      meta: json['meta'] != null ? KSoftMeta.fromJson(json['meta']) : null,
    );
  }

  /// Check if synced lyrics are available
  bool get hasSyncedLyrics => singalong != null && singalong!.isNotEmpty;

  /// Get synced lyrics in LRC format
  String? get syncedLyrics {
    if (!hasSyncedLyrics) return null;

    final buffer = StringBuffer();
    for (final line in singalong!) {
      if (line.lrcTimestamp != null && line.line.isNotEmpty) {
        buffer.writeln('${line.lrcTimestamp} ${line.line}');
      }
    }
    return buffer.toString().trim();
  }
}

/// Singalong line with timing info
class KSoftSingalongLine {
  final String? lrcTimestamp;
  final int milliseconds;
  final int duration;
  final String line;

  KSoftSingalongLine({
    this.lrcTimestamp,
    this.milliseconds = 0,
    this.duration = 0,
    required this.line,
  });

  factory KSoftSingalongLine.fromJson(Map<String, dynamic> json) {
    return KSoftSingalongLine(
      lrcTimestamp: json['lrc_timestamp'],
      milliseconds: int.tryParse(json['milliseconds']?.toString() ?? '0') ?? 0,
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      line: json['line'] ?? '',
    );
  }
}

/// Metadata from KSoft
class KSoftMeta {
  final List<String>? spotifyArtists;
  final String? spotifyTrack;
  final String? spotifyAlbum;
  final List<String>? deezerArtists;
  final String? deezerTrack;
  final String? deezerAlbum;
  final double? bpm;
  final double? gain;

  KSoftMeta({
    this.spotifyArtists,
    this.spotifyTrack,
    this.spotifyAlbum,
    this.deezerArtists,
    this.deezerTrack,
    this.deezerAlbum,
    this.bpm,
    this.gain,
  });

  factory KSoftMeta.fromJson(Map<String, dynamic> json) {
    final spotify = json['spotify'] as Map<String, dynamic>?;
    final deezer = json['deezer'] as Map<String, dynamic>?;
    final other = json['other'] as Map<String, dynamic>?;

    return KSoftMeta(
      spotifyArtists: (spotify?['artists'] as List?)?.cast<String>(),
      spotifyTrack: spotify?['track'],
      spotifyAlbum: spotify?['album'],
      deezerArtists: (deezer?['artists'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      deezerTrack: deezer?['track']?.toString(),
      deezerAlbum: deezer?['album']?.toString(),
      bpm: (other?['bpm'] as num?)?.toDouble(),
      gain: (other?['gain'] as num?)?.toDouble(),
    );
  }
}

/// Music recommendation from KSoft
class KSoftRecommendation {
  final String name;
  final String? youtubeId;
  final String? youtubeLink;
  final String? youtubeTitle;
  final String? youtubeThumbnail;
  final String? spotifyId;
  final String? spotifyName;
  final String? spotifyAlbumArt;

  KSoftRecommendation({
    required this.name,
    this.youtubeId,
    this.youtubeLink,
    this.youtubeTitle,
    this.youtubeThumbnail,
    this.spotifyId,
    this.spotifyName,
    this.spotifyAlbumArt,
  });

  factory KSoftRecommendation.fromJson(Map<String, dynamic> json) {
    final youtube = json['youtube'] as Map<String, dynamic>?;
    final spotify = json['spotify'] as Map<String, dynamic>?;

    return KSoftRecommendation(
      name: json['name'] ?? '',
      youtubeId: youtube?['id'],
      youtubeLink: youtube?['link'],
      youtubeTitle: youtube?['title'],
      youtubeThumbnail: youtube?['thumbnail'],
      spotifyId: spotify?['id'],
      spotifyName: spotify?['name'],
      spotifyAlbumArt: spotify?['album']?['album_art'],
    );
  }
}

/// Track info from KSoft
class KSoftTrackInfo {
  final String name;
  final int artistId;
  final String artistName;
  final String lyrics;
  final List<KSoftAlbumRef> albums;

  KSoftTrackInfo({
    required this.name,
    required this.artistId,
    required this.artistName,
    required this.lyrics,
    required this.albums,
  });

  factory KSoftTrackInfo.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'] as Map<String, dynamic>?;
    final albumsJson = json['albums'] as List? ?? [];

    return KSoftTrackInfo(
      name: json['name'] ?? '',
      artistId: artist?['id'] ?? 0,
      artistName: artist?['name'] ?? '',
      lyrics: json['lyrics'] ?? '',
      albums: albumsJson.map((a) => KSoftAlbumRef.fromJson(a)).toList(),
    );
  }
}

/// Artist info from KSoft
class KSoftArtistInfo {
  final int id;
  final String name;
  final List<KSoftAlbumRef> albums;
  final List<KSoftTrackRef> tracks;

  KSoftArtistInfo({
    required this.id,
    required this.name,
    required this.albums,
    required this.tracks,
  });

  factory KSoftArtistInfo.fromJson(Map<String, dynamic> json) {
    final albumsJson = json['albums'] as List? ?? [];
    final tracksJson = json['tracks'] as List? ?? [];

    return KSoftArtistInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      albums: albumsJson.map((a) => KSoftAlbumRef.fromJson(a)).toList(),
      tracks: tracksJson.map((t) => KSoftTrackRef.fromJson(t)).toList(),
    );
  }
}

/// Album reference
class KSoftAlbumRef {
  final int id;
  final String name;
  final int? year;

  KSoftAlbumRef({required this.id, required this.name, this.year});

  factory KSoftAlbumRef.fromJson(Map<String, dynamic> json) {
    return KSoftAlbumRef(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      year: json['year'],
    );
  }
}

/// Track reference
class KSoftTrackRef {
  final int id;
  final String name;

  KSoftTrackRef({required this.id, required this.name});

  factory KSoftTrackRef.fromJson(Map<String, dynamic> json) {
    return KSoftTrackRef(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}
