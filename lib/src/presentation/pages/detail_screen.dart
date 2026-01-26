import 'package:flutter/material.dart';

import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import '../../data/datasources/app_database.dart';
import '../../core/services/audio_handler.dart';
import '../widgets/common_artwork.dart';

import '../widgets/track_list_tile.dart';
import '../../core/utils/localization.dart';

enum DetailScreenType { album, artist }

/// Detail screen for albums and artists with track listings.
class DetailScreen extends StatelessWidget {
  final DetailScreenType type;
  final String title;

  const DetailScreen({
    super.key,
    required this.type,
    required this.title,
  });

  Future<List<Track>> _fetchTracks(AppDatabase db) {
    if (type == DetailScreenType.album) {
      return db.getTracksByAlbum(title);
    } else {
      return db.getTracksByArtist(title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = GetIt.I<AppDatabase>();
    final audioHandler = GetIt.I<MyAudioHandler>();

    return Scaffold(
      body: FutureBuilder<List<Track>>(
        future: _fetchTracks(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text(AppLocalizations.of(context)
                    .translate('error', args: {'error': snapshot.error})));
          }

          final List<Track> tracks = snapshot.data ?? <Track>[];

          if (tracks.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: Text(title)),
              body: Center(
                  child: Text(AppLocalizations.of(context).noTracksFound)),
            );
          }

          // Safe access to mediaStoreId (generated code might not be ready yet without build_runner)
          final firstTrack = tracks.first;
          int? firstMediaStoreId;
          try {
            firstMediaStoreId = (firstTrack as dynamic).mediaStoreId;
          } catch (_) {}

          return CustomScrollView(
            slivers: [
              // Header with album art
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CommonArtwork(
                        mediaStoreId: firstMediaStoreId,
                        path: firstTrack.path,
                        size: 300,
                        radius: 0,
                        placeholderIcon: type == DetailScreenType.album
                            ? Icons.album
                            : Icons.person,
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Info row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('tracks_count',
                            args: {'count': tracks.length}),
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => _playQueue(audioHandler, tracks, 0),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(AppLocalizations.of(context).playAll),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        onPressed: () {
                          // Shuffle play
                          final shuffled = List<Track>.from(tracks)..shuffle();
                          _playQueue(audioHandler, shuffled, 0);
                        },
                        icon: const Icon(Icons.shuffle),
                      ),
                    ],
                  ),
                ),
              ),
              // Track list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = tracks[index];
                    final isCurrentTrack =
                        audioHandler.mediaItem.value?.id == track.path;

                    return TrackListTile(
                      track: track,
                      trackNumber: index + 1,
                      isCurrentTrack: isCurrentTrack,
                      onTap: () => _playQueue(audioHandler, tracks, index),
                    );
                  },
                  childCount: tracks.length,
                ),
              ),
              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _playQueue(
      MyAudioHandler audioHandler, List<Track> tracks, int startIndex) async {
    final mediaItems = tracks.map((track) {
      int? mId;
      try {
        mId = (track as dynamic).mediaStoreId;
      } catch (_) {}

      return MediaItem(
        id: track.path,
        album: track.album ?? '',
        title: track.title,
        artist: track.artist,
        duration: Duration(milliseconds: track.duration),
        extras: mId != null ? {'mediaStoreId': mId} : null,
      );
    }).toList();

    await audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
    await audioHandler.playQueueFromIndex(mediaItems, startIndex);
  }
}
