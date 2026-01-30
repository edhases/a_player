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
      };
}
