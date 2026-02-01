import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import '../../data/datasources/app_database.dart'; // Drift models
import '../../domain/entities/youtube_song.dart';
import '../../domain/entities/local_track.dart';

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
    // Handle empty string as null
    String artist = (track.artist == null || track.artist!.trim().isEmpty)
        ? 'Unknown Artist'
        : track.artist!;
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

  /// Convert from domain LocalTrack to MediaItem
  static MediaItem fromLocalTrack(LocalTrack track) {
    Uri? artwork;
    if (track.artworkUri != null && track.artworkUri!.isNotEmpty) {
      artwork = Uri.parse(track.artworkUri!);
    }

    // Handle empty string as null for artist
    String artist = (track.artist == null || track.artist!.trim().isEmpty)
        ? 'Unknown Artist'
        : track.artist!;

    return MediaItem(
      id: track.path,
      album: track.album ?? 'Unknown Album',
      title: track.title,
      artist: artist,
      duration: Duration(milliseconds: track.duration),
      artUri: artwork,
      extras: {
        'isOnline': false,
        'path': track.path,
      },
    );
  }

  /// Convert Drift Track to domain LocalTrack
  static LocalTrack trackToLocalTrack(Track track) => LocalTrack(
        path: track.path,
        title: track.title,
        artist: track.artist,
        album: track.album,
        duration: track.duration,
        folderPath: track.folderPath,
        artworkUri: track.artworkUri,
        isFavorite: track.isFavorite,
        mediaStoreId: track.mediaStoreId,
        lastPlayed: track.lastPlayed,
        isExcluded: track.isExcluded,
      );
}
