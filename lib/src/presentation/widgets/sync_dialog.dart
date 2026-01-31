import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/background_cache_service.dart';
import '../../core/utils/localization.dart';
import '../../domain/entities/youtube_song.dart';
import '../../core/theme/app_theme.dart';
import 'common_artwork.dart';

/// Dialog for syncing liked songs from YouTube Music with cache selection
class SyncDialog extends StatefulWidget {
  const SyncDialog({super.key});

  /// Shows the sync dialog and returns true if sync was performed
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SyncDialog(),
    );
    return result ?? false;
  }

  @override
  State<SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<SyncDialog> {
  final _favoritesService = GetIt.I<FavoritesService>();
  final _backgroundCacheService = GetIt.I<BackgroundCacheService>();

  List<YouTubeSong> _newSongs = [];
  Map<String, bool> _cacheSelection = {};
  bool _isLoading = true;
  bool _isImporting = false;
  bool _selectAll = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNewSongs();
  }

  Future<void> _fetchNewSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final songs = await _favoritesService.fetchNewLikedFromYouTube();
      setState(() {
        _newSongs = songs;
        // Initialize all songs as selected for caching by default
        _cacheSelection = {for (var s in songs) s.videoId: true};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Помилка завантаження: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleAll(bool? value) {
    setState(() {
      _selectAll = value ?? true;
      for (var key in _cacheSelection.keys) {
        _cacheSelection[key] = _selectAll;
      }
    });
  }

  void _toggleSong(String videoId, bool? value) {
    setState(() {
      _cacheSelection[videoId] = value ?? false;
      _selectAll = _cacheSelection.values.every((v) => v);
    });
  }

  Future<void> _performSync() async {
    if (_newSongs.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isImporting = true);

    try {
      // 1. Import all songs to favorites
      await _favoritesService.importLikedSongs(_newSongs);

      // 2. Queue selected songs for background caching
      final songsToCache = _newSongs
          .where((s) => _cacheSelection[s.videoId] == true)
          .toList();

      if (songsToCache.isNotEmpty) {
        // Start background caching (non-blocking)
        _backgroundCacheService.queueForCaching(songsToCache);
        
        if (mounted) {
          final loc = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.translate('sync_caching_background', args: {'count': songsToCache.length})),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.sync),
          const SizedBox(width: 8),
          Text(loc.translate('sync_with_youtube')),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _buildContent(theme, loc),
      ),
      actions: _buildActions(loc),
    );
  }

  Widget _buildContent(ThemeData theme, AppLocalizations loc) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loc.translate('sync_loading')),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(loc.translate('sync_error'), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchNewSongs,
              child: Text(loc.translate('sync_try_again')),
            ),
          ],
        ),
      );
    }

    if (_newSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text(loc.translate('sync_all_synced')),
          ],
        ),
      );
    }

    if (_isImporting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loc.translate('sync_importing')),
          ],
        ),
      );
    }

    // List of new songs with checkboxes
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate('sync_found_new', args: {'count': _newSongs.length}),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          loc.translate('sync_select_for_cache'),
          style: theme.textTheme.bodySmall?.copyWith(color: context.appColors.textSecondary),
        ),
        const SizedBox(height: 8),
        // Select all checkbox
        CheckboxListTile(
          value: _selectAll,
          onChanged: _toggleAll,
          title: Text(loc.translate('sync_select_all')),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
        const Divider(height: 1),
        // Songs list
        Expanded(
          child: ListView.builder(
            itemCount: _newSongs.length,
            itemBuilder: (context, index) {
              final song = _newSongs[index];
              final isSelected = _cacheSelection[song.videoId] ?? false;
              
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) => _toggleSong(song.videoId, value),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CommonArtwork(url: song.thumbnailUrl, size: 40),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                subtitle: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                dense: true,
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(AppLocalizations loc) {
    if (_isLoading || _isImporting) {
      return [];
    }

    if (_newSongs.isEmpty) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(loc.translate('close')),
        ),
      ];
    }

    final selectedCount = _cacheSelection.values.where((v) => v).length;

    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text(loc.translate('cancel')),
      ),
      ElevatedButton.icon(
        onPressed: _performSync,
        icon: const Icon(Icons.download),
        label: Text(
          selectedCount > 0
              ? loc.translate('sync_import_and_cache', args: {'count': selectedCount})
              : loc.translate('sync_import_no_cache'),
        ),
      ),
    ];
  }
}
