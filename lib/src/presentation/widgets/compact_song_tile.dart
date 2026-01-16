import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/youtube_song.dart';
import '../../core/utils/localization.dart';

class CompactSongTile extends StatelessWidget {
  final YouTubeSong song;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  const CompactSongTile({
    super.key,
    required this.song,
    this.onTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      visualDensity: VisualDensity.compact,
      dense: true,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 48,
          height: 48,
          child: CachedNetworkImage(
            imageUrl: song.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[900],
              child:
                  const Icon(Icons.music_note, color: Colors.white24, size: 20),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[900],
              child: const Icon(Icons.broken_image,
                  color: Colors.white24, size: 20),
            ),
          ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(builder: (context) {
            final loc = AppLocalizations.of(context);
            final artistLabel =
                song.artist == 'Unknown' || song.artist == 'Unknown Artist'
                    ? loc.unknownArtist
                    : song.artist;
            return Text(
              artistLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            );
          }),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, size: 20),
        onPressed: onMenuTap,
        splashRadius: 20,
      ),
      onTap: onTap,
    );
  }
}
