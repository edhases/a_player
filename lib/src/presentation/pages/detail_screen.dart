import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import '../../data/datasources/app_database.dart';
import '../../core/services/audio_handler.dart';
import '../widgets/common_artwork.dart';

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
    final db = Provider.of<AppDatabase>(context, listen: false);
    final audioHandler = GetIt.I<MyAudioHandler>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: FutureBuilder<List<Track>>(
        future: _fetchTracks(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final tracks = snapshot.data ?? [];
          
          if (tracks.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: Text(title)),
              body: const Center(child: Text('No tracks found.')),
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
                        placeholderIcon: type == DetailScreenType.album ? Icons.album : Icons.person,
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
                        '${tracks.length} tracks',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => _playQueue(audioHandler, tracks, 0),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play All'),
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
                    final isCurrentTrack = audioHandler.mediaItem.value?.id == track.path;

                    return _TrackListTile(
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

  Future<void> _playQueue(MyAudioHandler audioHandler, List<Track> tracks, int startIndex) async {
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

    await audioHandler.updateQueue(mediaItems);
    await audioHandler.skipToQueueItem(startIndex);
  }
}

class _TrackListTile extends StatelessWidget {
  final Track track;
  final int trackNumber;
  final bool isCurrentTrack;
  final VoidCallback onTap;

  const _TrackListTile({
    required this.track,
    required this.trackNumber,
    required this.isCurrentTrack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: SizedBox(
        width: 32,
        child: Text(
          trackNumber.toString(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isCurrentTrack ? colorScheme.primary : Colors.grey[500],
            fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
          color: isCurrentTrack ? colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        track.artist ?? 'Unknown Artist',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: isCurrentTrack ? colorScheme.primary.withValues(alpha: 0.7) : Colors.grey[500],
        ),
      ),
      trailing: Text(
        _formatDuration(Duration(milliseconds: track.duration)),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
      ),
      onTap: onTap,
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
