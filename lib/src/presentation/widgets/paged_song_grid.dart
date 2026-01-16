import 'package:flutter/material.dart';
import '../../domain/entities/youtube_song.dart';
import 'compact_song_tile.dart';

class PagedSongGrid extends StatelessWidget {
  final List<YouTubeSong> songs;
  final Function(YouTubeSong) onSongTap;

  const PagedSongGrid({
    super.key,
    required this.songs,
    required this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    // We want 4 rows.
    // Calculate total width based on number of columns needed.
    // However, horizontal GridView needs a bounded height.
    // Each row is approx 56-60px height. 4 rows ~= 240px.

    return SizedBox(
      height: 240, // 4 * ~60px
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4 items vertically
          mainAxisSpacing: 12, // Horizontal space between columns
          crossAxisSpacing: 4, // Vertical space between items
          childAspectRatio: 0.22, // Width/Height ratio. Needs tuning.
          // Height is ~60 (240/4). Width needs to be ~300?
          // Ratio = Width / Height. 300 / 60 = 5.
          // To get width of ~280-300px for the tile.
        ),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          return SizedBox(
            width: 300,
            child: CompactSongTile(
              song: songs[index],
              onTap: () => onSongTap(songs[index]),
            ),
          );
        },
      ),
    );
  }
}
