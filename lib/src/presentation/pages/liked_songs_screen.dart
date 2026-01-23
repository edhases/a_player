import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/smart_play_service.dart';
import '../../data/datasources/app_database.dart'; // Drift models
import '../../domain/entities/youtube_song.dart';
import '../widgets/common_artwork.dart';
import '../../core/utils/localization.dart';

class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({super.key});

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen> {
  final _favoritesService = GetIt.I<FavoritesService>();
  final _smartPlayService = GetIt.I<SmartPlayService>();

  List<YouTubeTrack> _songs = []; // Changed type
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).likedSongs),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).noTracksFound,
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
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () async {
                          // Allow unliking from the list
                          await _favoritesService.toggleFavorite(
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
    );
  }
}
