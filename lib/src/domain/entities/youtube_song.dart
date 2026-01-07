class YouTubeSong {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnailUrl;

  YouTubeSong({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
  });
  
  @override
  String toString() => '$title - $artist ($videoId)';
}
