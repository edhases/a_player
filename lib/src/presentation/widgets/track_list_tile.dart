import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:io';
import '../../data/datasources/app_database.dart';
import '../../core/services/metadata_matching_service.dart';
import '../../data/models/local_track_override.dart';
import '../widgets/common_artwork.dart';
import '../../core/services/audio_handler.dart';
import '../widgets/search/metadata_pick_delegate.dart';
import '../../domain/entities/youtube_song.dart';
import '../../core/utils/localization.dart';

class TrackListTile extends StatefulWidget {
  final Track track;
  final bool isCurrentTrack;
  final VoidCallback onTap;
  final int? trackNumber;

  const TrackListTile({
    super.key,
    required this.track,
    required this.isCurrentTrack,
    required this.onTap,
    this.trackNumber,
  });

  @override
  State<TrackListTile> createState() => _TrackListTileState();
}

class _TrackListTileState extends State<TrackListTile> {
  @override
  Widget build(BuildContext context) {
    if (!GetIt.I.isRegistered<MetadataMatchingService>()) {
      return _buildTile(context, null);
    }

    final service = GetIt.I<MetadataMatchingService>();
    // Watch for changes to the override for this specific file
    return StreamBuilder<LocalTrackOverride?>(
      stream: service.watchTrackOverride(widget.track.path),
      builder: (context, snapshot) {
        return _buildTile(context, snapshot.data);
      },
    );
  }

  Widget _buildTile(BuildContext context, LocalTrackOverride? override) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    // Use override if available, otherwise fallback to track data
    final title = override?.correctTitle ?? widget.track.title;
    final artist =
        override?.correctArtist ?? widget.track.artist ?? loc.unknownArtist;
    final album = widget.track.album ?? loc.unknownAlbum;
    final artUrl = override?.thumbnailUrl;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(
        width: 50,
        height: 50,
        child: widget.trackNumber != null
            ? Center(
                child: Text(
                  widget.trackNumber.toString(),
                  style: TextStyle(
                    color: widget.isCurrentTrack
                        ? colorScheme.primary
                        : Colors.grey[500],
                    fontWeight: widget.isCurrentTrack
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              )
            : CommonArtwork(
                mediaStoreId: widget.track.mediaStoreId,
                path: widget.track.path,
                url: artUrl, // Use override URL if available
                size: 50,
              ),
      ),
      title: Text(
        title, // Use overridden title
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight:
              widget.isCurrentTrack ? FontWeight.bold : FontWeight.normal,
          color: widget.isCurrentTrack ? colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        widget.trackNumber != null
            ? artist // Detail view usually just shows artist
            : '$artist • $album', // All tracks view shows artist • album
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: widget.isCurrentTrack
              ? colorScheme.primary.withOpacity(0.7)
              : Colors.grey[500],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(Duration(milliseconds: widget.track.duration)),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) {
              // Safe access to isExcluded using dynamic if needed, or assume generated
              // Since build_runner acts on models, Track class might need regeneration to show property.
              // I will access it dynamically for now to prevent compile errors in THIS step if file is analysed.
              final isExcluded = (widget.track as dynamic).isExcluded == true;

              return [
                PopupMenuItem(
                  value: 'queue',
                  child: ListTile(
                    leading: Icon(Icons.queue_music),
                    title: Text(loc.addToQueue),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'next',
                  child: ListTile(
                    leading: Icon(Icons.play_arrow_outlined),
                    title: Text(loc.playNext),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'scan',
                  child: ListTile(
                    leading: Icon(Icons.auto_fix_high),
                    title: Text(loc.matchMetadata),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuDivider(),
                if (!isExcluded)
                  PopupMenuItem(
                    value: 'exclude',
                    child: ListTile(
                      leading: Icon(Icons.visibility_off_outlined),
                      title: Text(loc.excludeHide),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  )
                else
                  PopupMenuItem(
                    value: 'restore',
                    child: ListTile(
                      leading: Icon(Icons.visibility_outlined),
                      title: Text(loc.restore),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete_file',
                  child: ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red),
                    title: Text(loc.deleteFile,
                        style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      onTap: widget.onTap,
    );
  }

  void _handleMenuAction(BuildContext context, String value) async {
    final audioHandler = GetIt.I<MyAudioHandler>();
    final loc = AppLocalizations.of(context);

    switch (value) {
      case 'queue':
        await audioHandler.addToQueue(widget.track);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.queueAdded)),
          );
        }
        break;
      case 'next':
        await audioHandler.playNext(widget.track);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.willPlayNext)),
          );
        }
        break;
      case 'scan':
        _showMatchDialog(context);
        break;
      case 'exclude':
        await _toggleExclude(context, true);
        break;
      case 'restore':
        await _toggleExclude(context, false);
        break;
      case 'delete_file':
        await _hardDelete(context);
        break;
    }
  }

  Future<void> _toggleExclude(BuildContext context, bool exclude) async {
    final db = GetIt.I<AppDatabase>();
    final loc = AppLocalizations.of(context);
    await db.setExcluded(widget.track.path, exclude);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exclude ? loc.trackHidden : loc.trackRestored)),
      );
    }
  }

  Future<void> _hardDelete(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteFileTitle),
        content: Text(loc.deleteFileConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete file
        if (await File(widget.track.path).exists()) {
          await File(widget.track.path).delete();
        }

        final db = GetIt.I<AppDatabase>();
        await db.deleteTrack(widget.track.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.fileDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(loc.translate('delete_error', args: {'error': e}))),
          );
        }
      }
    }
  }

  Future<void> _showMatchDialog(BuildContext context) async {
    if (!GetIt.I.isRegistered<MetadataMatchingService>()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final service = GetIt.I<MetadataMatchingService>();
      final result =
          await service.autoMatchTags(widget.track.path, widget.track.title);

      if (context.mounted) Navigator.pop(context); // Close loading

      if (context.mounted) {
        if (result != null) {
          _showSuccessDialog(context, result);
        } else {
          // Auto-match failed, ask for manual search
          _showManualSearchOption(context, service);
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // ensure loading closed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context, LocalTrackOverride result) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.matched),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.thumbnailUrl != null)
              Image.network(result.thumbnailUrl!, height: 100),
            const SizedBox(height: 8),
            Text('Title: ${result.correctTitle}'),
            Text('Artist: ${result.correctArtist}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showManualSearchDialog(
                  context, GetIt.I<MetadataMatchingService>());
            },
            child: Text(loc.wrongMatch),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.ok)),
        ],
      ),
    );
  }

  void _showManualSearchOption(
      BuildContext context, MetadataMatchingService service) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.noMatchFound),
        content: Text(loc.manualSearchConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualSearchDialog(context, service);
            },
            child: Text(loc.manualSearch),
          ),
        ],
      ),
    );
  }

  void _showManualSearchDialog(
      BuildContext context, MetadataMatchingService service) async {
    // Use the new full-screen Search Delegate
    final YouTubeSong? selectedSong = await showSearch<YouTubeSong?>(
      context: context,
      delegate: MetadataPickDelegate(),
      query: widget.track.title, // Pre-fill the search query
    );

    if (selectedSong != null) {
      try {
        debugPrint('Saving override for: ${widget.track.title}');
        debugPrint('Selected: ${selectedSong.title} (${selectedSong.videoId})');

        await service.saveOverride(
          filePath: widget.track.path,
          youtubeId: selectedSong.videoId,
          title: selectedSong.title,
          artist: selectedSong.artist,
          thumbnailUrl: selectedSong.thumbnailUrl,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).metadataUpdated),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e, stack) {
        debugPrint('Error saving override: $e');
        debugPrint(stack.toString());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)
                  .translate('metadata_save_error', args: {'error': e})),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      debugPrint('Manual search cancelled or returned null');
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
