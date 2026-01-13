class YouTubeSong {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final int duration; // Duration in seconds

  YouTubeSong({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    this.duration = 0,
  });

  @override
  String toString() => '$title - $artist ($videoId)';

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'artist': artist,
        'thumbnailUrl': thumbnailUrl,
        'duration': duration,
      };
}
