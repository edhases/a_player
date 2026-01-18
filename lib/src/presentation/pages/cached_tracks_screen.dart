import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/cache_service.dart';
import '../../data/models/cached_track.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/localization.dart';
import '../../core/services/download_service.dart';
import '../../domain/entities/youtube_song.dart';

class CachedTracksScreen extends StatefulWidget {
  const CachedTracksScreen({super.key});

  @override
  State<CachedTracksScreen> createState() => _CachedTracksScreenState();
}

class _CachedTracksScreenState extends State<CachedTracksScreen> {
  final CacheService _cacheService = GetIt.I<CacheService>();
  List<CachedTrack> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    final tracks = await _cacheService.getCachedTracks();
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTrack(CachedTrack track) async {
    await _cacheService.deleteCachedTrack(track.id);
    _loadTracks(); // Refresh list
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).cachedTracksTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ? Center(child: Text(AppLocalizations.of(context).noTracksFound))
              : ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: track.thumbnailUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note),
                          ),
                        ),
                      ),
                      title: Text(track.title),
                      subtitle: Text(
                          '${track.artist} • ${_formatBytes(track.fileSize)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.save_alt),
                            tooltip: AppLocalizations.of(context).saveToDevice,
                            onPressed: () => _saveToDevice(track),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteTrack(track),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _saveToDevice(CachedTrack track) async {
    final downloadService = GetIt.I<DownloadService>();
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context);

    // Show starting snackbar
    messenger.showSnackBar(
      SnackBar(content: Text(loc.downloadStarted(track.title))),
    );

    final song = YouTubeSong(
      videoId: track.videoId,
      title: track.title,
      artist: track.artist,
      thumbnailUrl: track.thumbnailUrl,
      duration:
          0, // Duration not stored in cache model, acceptable for download wrapper
    );

    final path = await downloadService.saveToDevice(
      song,
      onProgress: (progress) {
        // Optional: show progress dialog
      },
    );

    if (!mounted) return;

    if (path != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.downloadCompleted(track.title))),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.downloadError)),
      );
    }
  }
}
