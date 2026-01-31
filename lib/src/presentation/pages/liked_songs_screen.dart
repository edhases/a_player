import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/smart_play_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/audio_handler.dart';
import '../../core/services/background_cache_service.dart';
import '../../data/datasources/app_database.dart'; // Drift models
import '../../domain/entities/youtube_song.dart';
import '../widgets/common_artwork.dart';
import '../widgets/sync_dialog.dart';
import '../../core/utils/localization.dart';
import '../utils/track_actions.dart';
import '../../core/theme/app_theme.dart';

class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({super.key});

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen> {
  final _favoritesService = GetIt.I<FavoritesService>();
  final _smartPlayService = GetIt.I<SmartPlayService>();
  final _settingsService = GetIt.I<SettingsService>();
  final _audioHandler = GetIt.I<MyAudioHandler>();
  final _backgroundCacheService = GetIt.I<BackgroundCacheService>();

  List<YouTubeTrack> _songs = []; // Changed type
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _autoCacheLiked = true;
  
  // Background caching state
  StreamSubscription<CacheProgress>? _cacheProgressSubscription;
  CacheProgress? _cacheProgress;

  @override
  void initState() {
    super.initState();
    _autoCacheLiked = _settingsService.loadAutoCacheLiked();
    _loadSongs();
    
    // Listen to background cache progress
    _cacheProgressSubscription = _backgroundCacheService.progressStream.listen((progress) {
      if (mounted) {
        setState(() => _cacheProgress = progress);
      }
    });
  }

  @override
  void dispose() {
    _cacheProgressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    final songs = await _favoritesService.getLikedSongs();
    if (mounted) {
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    }
  }
  Future<void> _playAllLiked({bool shuffle = false}) async {
    if (_songs.isEmpty) return;
    
    final loc = AppLocalizations.of(context);
    
    // Convert all liked songs to MediaItem list
    var songsList = _songs.toList();
    if (shuffle) {
      songsList.shuffle();
    }
    
    final mediaItems = songsList.map((song) => MediaItem(
      id: song.videoId,
      title: song.title,
      artist: song.artist,
      artUri: Uri.tryParse(song.thumbnailUrl),
      duration: Duration(seconds: song.duration),
      extras: {
        'videoId': song.videoId,
        'isOnline': true,
        'isYouTube': true,
      },
    )).toList();
    
    // Play the queue starting from index 0
    await _audioHandler.playQueueFromIndex(mediaItems, 0);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shuffle 
            ? loc.translate('playing_liked_shuffle', args: {'count': mediaItems.length})
            : loc.translate('playing_liked_count', args: {'count': mediaItems.length})),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleAutoCacheLiked(bool value) {
    setState(() => _autoCacheLiked = value);
    _settingsService.saveAutoCacheLiked(value);
  }

  Future<void> _syncFromYouTube() async {
    if (_isSyncing) return;
    
    setState(() => _isSyncing = true);
    
    try {
      // Show sync dialog with cache selection
      final synced = await SyncDialog.show(context);
      
      if (synced && mounted) {
        await _loadSongs();
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _playSong(YouTubeTrack song) async {
    // Конвертуємо YouTubeTrack в YouTubeSong
    final ytSong = YouTubeSong(
      videoId: song.videoId,
      title: song.title,
      artist: song.artist,
      thumbnailUrl: song.thumbnailUrl,
      duration: song.duration,
    );

    await _smartPlayService.handleSongTap(context, ytSong);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.likedSongs),
        actions: [
          // Play all liked songs button
          if (_songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: loc.translate('play_liked'),
              onPressed: () => _playAllLiked(),
            ),
          // Shuffle play button
          if (_songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shuffle),
              tooltip: loc.translate('shuffle_and_play'),
              onPressed: () => _playAllLiked(shuffle: true),
            ),
          // Sync from YouTube button
          IconButton(
            icon: _isSyncing 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
            tooltip: loc.translate('sync_from_youtube'),
            onPressed: _isSyncing ? null : _syncFromYouTube,
          ),
          // Settings menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'toggle_cache') {
                _toggleAutoCacheLiked(!_autoCacheLiked);
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem<String>(
                value: 'toggle_cache',
                checked: _autoCacheLiked,
                child: Text(loc.translate('auto_cache_liked')),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Background caching progress indicator
          if (_cacheProgress != null && _cacheProgress!.isCaching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('caching_progress', args: {
                            'done': _cacheProgress!.completed,
                            'total': _cacheProgress!.total,
                          }),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          _cacheProgress!.currentSong,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _backgroundCacheService.cancelCaching(),
                    tooltip: loc.translate('caching_cancel'),
                  ),
                ],
              ),
            ),
          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _songs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border,
                                size: 64, color: context.appColors.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              loc.noTracksFound,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CommonArtwork(url: song.thumbnailUrl, size: 50),
                            ),
                            title: Text(song.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(song.artist,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: Icon(Icons.favorite, color: context.appColors.error),
                              onPressed: () async {
                                // Allow unliking from the list
                                await TrackActions.handleLikeButton(
                                  context,
                                  videoId: song.videoId,
                                  title: song.title,
                                  artist: song.artist,
                                  thumbnailUrl: song.thumbnailUrl,
                                );
                                _loadSongs(); // Refresh list
                              },
                            ),
                            onTap: () => _playSong(song),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
