import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import '../../data/datasources/app_database.dart'; // Drift models
import '../../domain/entities/youtube_song.dart';

class MediaItemAdapter {
  static MediaItem fromYouTubeSong(YouTubeSong song, {String? cachedUrl}) {
    debugPrint(
        '[MediaItemAdapter] Adapting ${song.videoId}: duration=${song.duration} (seconds)');
    final extras = <String, dynamic>{
      'isOnline': true,
      'videoId': song.videoId,
      'thumbnailUrl': song.thumbnailUrl,
      'playlistId': song.playlistId,
      'artistId': song.artistId,
    };

    if (cachedUrl != null) {
      extras['cachedUrl'] = cachedUrl;
    }

    return MediaItem(
      id: song.videoId,
      album:
          song.artist, // YouTube Music often puts artist as album for singles
      title: song.title,
      artist: song.artist,
      duration: Duration(seconds: song.duration),
      artUri:
          song.thumbnailUrl.isNotEmpty ? Uri.parse(song.thumbnailUrl) : null,
      extras: extras,
    );
  }

  static MediaItem fromTrack(Track track, [TrackOverride? override]) {
    // Default values from track
    String title = track.title;
    String artist = track.artist ?? 'Unknown Artist';
    String? artUri = track.artworkUri;

    // Apply override if available
    if (override != null) {
      if (override.correctTitle != null) {
        title = override.correctTitle!;
      }
      if (override.correctArtist != null) {
        artist = override.correctArtist!;
      }
      if (override.thumbnailUrl != null) {
        artUri = override.thumbnailUrl;
      }
    }

    // Fallback for artwork
    Uri? artwork;
    if (artUri != null && artUri.isNotEmpty) {
      artwork = Uri.parse(artUri);
    }

    return MediaItem(
      id: track.path,
      album: track.album ?? 'Unknown Album',
      title: title,
      artist: artist,
      duration: Duration(milliseconds: track.duration),
      artUri: artwork,
      extras: {
        'isOnline': false,
        'path': track.path,
      },
    );
  }
}
