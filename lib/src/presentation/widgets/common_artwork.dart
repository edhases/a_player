import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:metadata_god/metadata_god.dart';

/// A unified widget for displaying audio artwork.
/// Prioritizes on_audio_query (fast) using mediaStoreId, falls back to direct file reading.
class CommonArtwork extends StatelessWidget {
  final int? mediaStoreId;
  final String? path;
  final ArtworkType type;
  final double size;
  final double radius;
  final IconData placeholderIcon;

  const CommonArtwork({
    super.key,
    this.mediaStoreId,
    this.path,
    this.type = ArtworkType.AUDIO,
    this.size = 50,
    this.radius = 6,
    this.placeholderIcon = Icons.music_note,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaStoreId != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: QueryArtworkWidget(
          id: mediaStoreId!,
          type: type,
          artworkHeight: size,
          artworkWidth: size,
          artworkFit: BoxFit.cover,
          nullArtworkWidget: _buildPlaceholder(context),
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
        ),
      );
    }

    // Fallback for local files. 
    // CRITICAL: Never use MetadataGod on network URLs (http/https).
    // It will try to download/stream the file to read ID3 tags, causing huge lags.
    if (path != null && !path!.startsWith('http')) {
      return FutureBuilder<Metadata?>(
        future: MetadataGod.readMetadata(file: path!),
        builder: (context, snapshot) {
          final artwork = snapshot.data?.picture?.data;
          if (artwork != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.memory(
                artwork,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            );
          }
          return _buildPlaceholder(context);
        },
      );
    }
    
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        placeholderIcon,
        color: Colors.grey[600],
        size: size * 0.5,
      ),
    );
  }
}
