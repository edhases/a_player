import '../../core/utils/duration_formatter.dart';

class YouTubeSong {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final int duration; // Duration in seconds
  final bool isLive;

  // New fields for mixed content
  final String? playlistId;
  final bool isPlaylist;
  final String category; // e.g. "Single", "Album", "Playlist", "Song"
  final String? artistId; // BrowseID for the artist channel

  YouTubeSong({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    this.duration = 0,
    this.isLive = false,
    this.playlistId,
    this.isPlaylist = false,
    this.category = '',
    this.artistId,
  });

  YouTubeSong copyWith({
    String? videoId,
    String? title,
    String? artist,
    String? thumbnailUrl,
    int? duration,
    bool? isLive,
    String? playlistId,
    bool? isPlaylist,
    String? category,
    String? artistId,
  }) {
    return YouTubeSong(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      isLive: isLive ?? this.isLive,
      playlistId: playlistId ?? this.playlistId,
      isPlaylist: isPlaylist ?? this.isPlaylist,
      category: category ?? this.category,
      artistId: artistId ?? this.artistId,
    );
  }

  // Helper to identify functionality
  bool get isMix => isPlaylist || (playlistId != null && videoId.isNotEmpty);

  /// Formatted duration string (e.g., "3:45" or "1:02:30")
  String get durationFormatted {
    if (duration <= 0) return '0:00';
    final d = Duration(seconds: duration);
    if (d.inHours > 0) {
      return DurationFormatter.format(d);
    }
    return DurationFormatter.formatMinimal(d);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YouTubeSong &&
          runtimeType == other.runtimeType &&
          videoId == other.videoId;

  @override
  int get hashCode => videoId.hashCode;

  @override
  String toString() =>
      'YouTubeSong(title: $title, id: $videoId, isPlaylist: $isPlaylist)';

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'artist': artist,
        'thumbnailUrl': thumbnailUrl,
        'duration': duration,
        'isLive': isLive,
        'playlistId': playlistId,
        'isPlaylist': isPlaylist,
        'artistId': artistId,
        'category': category,
      };

  Map<String, dynamic> toMap() => toJson();

  factory YouTubeSong.fromMap(Map<String, dynamic> map) {
    return YouTubeSong(
      videoId: map['videoId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      artist: map['artist'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      duration: map['duration'] as int? ?? 0,
      isLive: map['isLive'] as bool? ?? false,
      playlistId: map['playlistId'] as String?,
      isPlaylist: map['isPlaylist'] as bool? ?? false,
      category: map['category'] as String? ?? '',
      artistId: map['artistId'] as String?,
    );
  }
}
