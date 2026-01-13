import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import '../../data/datasources/app_database.dart';
import '../../core/services/music_finder.dart';
import '../../core/services/audio_handler.dart';
import '../widgets/common_artwork.dart';

/// Screen displaying all tracks with album art thumbnails.
/// Poweramp-inspired design with smooth aesthetics.
class AllTracksScreen extends StatelessWidget {
  const AllTracksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = GetIt.I<AppDatabase>();
    final musicFinder = GetIt.I<MusicFinder>();
    final audioHandler = GetIt.I<MyAudioHandler>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: StreamBuilder<List<Track>>(
        stream: db.select(db.tracks).watch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tracks = snapshot.data ?? [];

          if (tracks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_music_outlined,
                      size: 80,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Music Found',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add music by scanning a folder',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => musicFinder.scanAllMusic(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Scan Music'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Sort tracks alphabetically by title
          tracks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

          return ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              final isCurrentTrack = audioHandler.mediaItem.value?.id == track.path;

              return _TrackListTile(
                track: track,
                isCurrentTrack: isCurrentTrack,
                onTap: () => _playQueue(audioHandler, tracks, index),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => musicFinder.pickFolderAndScan(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _playQueue(MyAudioHandler audioHandler, List<Track> tracks, int startIndex) async {
    // Optimization: Don't load 2000+ songs into the player queue at once.
    // This causes huge delays (15s+) and Android Binder Transaction errors.
    // Instead, load a "window" of tracks around the current one.
    
    const windowSize = 20; // Load 20 tracks before and after (total 40)
    final start = (startIndex - windowSize).clamp(0, tracks.length);
    final end = (startIndex + windowSize + 1).clamp(0, tracks.length);
    
    final subset = tracks.sublist(start, end);
    final relativeIndex = startIndex - start;

    final mediaItems = subset.map((track) {
      final extras = <String, dynamic>{};
      if (track.mediaStoreId != null) {
        extras['mediaStoreId'] = track.mediaStoreId;
      }
      return MediaItem(
        id: track.path,
        album: track.album ?? '',
        title: track.title,
        artist: track.artist,
        duration: Duration(milliseconds: track.duration),
        extras: extras.isEmpty ? null : extras,
      );
    }).toList();

    await audioHandler.updateQueue(mediaItems);
    await audioHandler.skipToQueueItem(relativeIndex);
  }
}

/// A single track list tile with album art thumbnail.
class _TrackListTile extends StatelessWidget {
  final Track track;
  final bool isCurrentTrack;
  final VoidCallback onTap;

  const _TrackListTile({
    required this.track,
    required this.isCurrentTrack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(
        width: 50,
        height: 50,
        child: CommonArtwork(
          mediaStoreId: track.mediaStoreId,
          path: track.path,
          size: 50,
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
        '${track.artist ?? 'Unknown Artist'} • ${track.album ?? 'Unknown Album'}',
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
