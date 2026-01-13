import 'package:audio_service/audio_service.dart';
import '../../data/datasources/app_database.dart';
import '../../domain/entities/youtube_song.dart';

class MediaItemAdapter {
  static MediaItem fromTrack(Track track) {
    return MediaItem(
      id: track.path,
      album: track.album ?? '',
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
      artUri: track.artworkUri != null ? Uri.parse(track.artworkUri!) : null,
      extras: {
        'mediaStoreId': track.mediaStoreId,
      },
    );
  }

  static MediaItem fromYouTubeSong(YouTubeSong song) {
    return MediaItem(
      id: song.videoId,
      album: song.artist,
      title: song.title,
      artist: song.artist,
      artUri: Uri.parse(song.thumbnailUrl),
      duration: Duration(seconds: song.duration),
      extras: {
        'isOnline': true,
        'videoId': song.videoId,
      },
    );
  }
}
