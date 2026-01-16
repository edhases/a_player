import 'package:audio_service/audio_service.dart';
import '../../data/datasources/app_database.dart';
import '../../domain/entities/youtube_song.dart';
import '../../data/models/local_track_override.dart';

class MediaItemAdapter {
  static MediaItem fromTrack(Track track, [LocalTrackOverride? override]) {
    return MediaItem(
      id: track.path,
      album: track.album ?? '',
      title: override?.correctTitle ?? track.title,
      artist: override?.correctArtist ?? track.artist,
      duration: Duration(milliseconds: track.duration),
      artUri: override?.thumbnailUrl != null
          ? Uri.parse(override!.thumbnailUrl!)
          : (track.artworkUri != null ? Uri.parse(track.artworkUri!) : null),
      extras: {
        'mediaStoreId': track.mediaStoreId,
        'youtubeId': override?.youtubeId,
      },
    );
  }

  static MediaItem fromYouTubeSong(YouTubeSong song) {
    return MediaItem(
      id: song.videoId,
      album: song.artist,
      title: song.title,
      artist: song.artist,
      artUri:
          song.thumbnailUrl.isNotEmpty ? Uri.parse(song.thumbnailUrl) : null,
      duration: Duration(seconds: song.duration),
      extras: {
        'isOnline': true,
        'videoId': song.videoId,
        'thumbnailUrl': song.thumbnailUrl,
      },
    );
  }
}
