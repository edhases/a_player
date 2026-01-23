import 'package:flutter/material.dart';
import '../../domain/entities/youtube_song.dart';
import 'compact_quick_pick_tile.dart';

class PagedSongList extends StatelessWidget {
  final List<YouTubeSong> songs;
  final Function(YouTubeSong) onSongTap;
  final Function(YouTubeSong) onPlayTap;
  final Function(YouTubeSong) onMenuTap;
  final int itemsPerPage;

  const PagedSongList({
    super.key,
    required this.songs,
    required this.onSongTap,
    required this.onPlayTap,
    required this.onMenuTap,
    this.itemsPerPage = 4, // Default to 4 items per column
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const SizedBox.shrink();

    final pageCount = (songs.length / itemsPerPage).ceil();
    // Calculate approximate height: 72px per tile + padding
    // If total songs < itemsPerPage, shrink the height to fit content.
    final effectiveItemsCount =
        songs.length < itemsPerPage ? songs.length : itemsPerPage;
    final double height = (effectiveItemsCount * 72.0) + 16.0;

    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: PageController(
          viewportFraction: 0.92, // Peek next page
        ),
        padEnds: false, // Align to start
        itemCount: pageCount,
        itemBuilder: (context, pageIndex) {
          final startIndex = pageIndex * itemsPerPage;
          final endIndex = (startIndex + itemsPerPage < songs.length)
              ? startIndex + itemsPerPage
              : songs.length;

          final pageSongs = songs.sublist(startIndex, endIndex);

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: pageSongs.map((song) {
                return CompactQuickPickTile(
                  song: song,
                  onTap: () => onSongTap(song),
                  onPlayTap: () => onPlayTap(song),
                  onMenuTap: () => onMenuTap(song),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
