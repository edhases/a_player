import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';

class ArtworkWidget extends StatelessWidget {
  final Track track;
  final double size;

  const ArtworkWidget({
    super.key,
    required this.track,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: _buildArtwork(),
      ),
    );
  }

  Widget _buildArtwork() {
    if (track.artworkUri != null) {
      return Image.file(
        File(track.artworkUri!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
      );
    } else if (track.remoteArtworkUri != null) {
      return CachedNetworkImage(
        imageUrl: track.remoteArtworkUri!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildDefaultIcon(),
        errorWidget: (context, url, error) => _buildDefaultIcon(),
      );
    } else {
      return _buildDefaultIcon();
    }
  }

  Widget _buildDefaultIcon() {
    return Container(
      color: Colors.grey[800],
      child: Icon(
        Icons.music_note,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }
}
