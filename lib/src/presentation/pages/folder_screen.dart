import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import 'package:path/path.dart' as p;

import '../../data/datasources/app_database.dart';
import '../../domain/services/hierarchy_service.dart';
import '../../core/services/audio_handler.dart';
import '../widgets/common_artwork.dart';

/// Folder browser screen with track artwork thumbnails.
class FolderScreen extends StatelessWidget {
  /// The path to display. '.' represents the root.
  final String path;
  final HierarchyService _hierarchyService = HierarchyService();

  FolderScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final audioHandler = GetIt.I<MyAudioHandler>();

    final bool isRoot = path == '.';
    final String title = isRoot ? 'Folders' : p.basename(path);

    return Scaffold(
      appBar: isRoot ? null : AppBar(title: Text(title)),
      body: StreamBuilder<List<Track>>(
        stream: db.select(db.tracks).watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allTracks = snapshot.data!;
          final entries = _hierarchyService.getEntriesForPath(allTracks, path);

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'This folder is empty',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              
              if (entry is FolderEntry) {
                return _FolderListTile(
                  folder: entry,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FolderScreen(path: entry.path),
                      ),
                    );
                  },
                );
              } else if (entry is TrackEntry) {
                final isCurrentTrack = audioHandler.mediaItem.value?.id == entry.track.path;
                
                return _TrackListTile(
                  track: entry.track,
                  isCurrentTrack: isCurrentTrack,
                  onTap: () {
                    final tracksInFolder = entries
                        .whereType<TrackEntry>()
                        .map((te) => te.track)
                        .toList();
                    _playQueue(audioHandler, tracksInFolder, entry.track);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Future<void> _playQueue(MyAudioHandler audioHandler, List<Track> tracks, Track startTrack) async {
    final mediaItems = tracks.map((track) => MediaItem(
      id: track.path,
      album: track.album ?? '',
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
      extras: track.mediaStoreId != null ? {'mediaStoreId': track.mediaStoreId} : null,
    )).toList();

    final startIndex = tracks.indexOf(startTrack);

    await audioHandler.updateQueue(mediaItems);
    await audioHandler.skipToQueueItem(startIndex);
  }
}

class _FolderListTile extends StatelessWidget {
  final FolderEntry folder;
  final VoidCallback onTap;

  const _FolderListTile({
    required this.folder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.folder,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        folder.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

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
