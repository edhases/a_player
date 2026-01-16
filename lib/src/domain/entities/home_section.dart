import 'youtube_song.dart';

enum SectionType { horizontal, vertical, grid }

class HomeSection {
  final String title;
  final List<YouTubeSong> songs;
  final SectionType type;

  HomeSection({
    required this.title,
    required this.songs,
    this.type = SectionType.horizontal,
  });
}
