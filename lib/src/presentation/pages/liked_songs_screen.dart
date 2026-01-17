import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/audio_handler.dart';
import '../../data/models/liked_song.dart';
import '../../domain/entities/youtube_song.dart';
import '../widgets/common_artwork.dart';
import '../../core/utils/localization.dart';
import '../../core/services/innertube_service.dart';
import 'package:audio_service/audio_service.dart';

class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({super.key});

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen> {
  final _favoritesService = GetIt.I<FavoritesService>();
  final _audioHandler = GetIt.I<MyAudioHandler>();

  List<LikedSong> _songs = [];
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

  Future<void> _playSong(LikedSong song) async {
    // Check if the "videoId" is actually a Playlist/Album ID (e.g. starts with MPRE, VL, or length != 11)
    // Standard YouTube video IDs are 11 characters.
    final isLikelyPlaylist = song.videoId.length != 11;

    if (isLikelyPlaylist) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Loading album details...'),
            duration: const Duration(seconds: 1)),
      );

      try {
        // Resolve tracks using InnerTubeService (assuming GetIt has it)
        // We need to access InnerTubeService, but it wasn't injected in the state.
        // We can get it via GetIt.
        final innerTube = GetIt.I<InnerTubeService>();
        final tracks = await innerTube.getPlaylistTracks(song.videoId);

        if (tracks.isNotEmpty) {
          if (tracks.length == 1) {
            // Play the single track
            var singleTrack = tracks.first;

            // Merge known metadata from the LikedSong
            singleTrack = singleTrack.copyWith(
              artist: (singleTrack.artist == 'Unknown' ||
                      singleTrack.artist.isEmpty)
                  ? song.artist
                  : singleTrack.artist,
              thumbnailUrl: (singleTrack.thumbnailUrl.isEmpty)
                  ? song.thumbnailUrl
                  : singleTrack.thumbnailUrl,
            );

            await _audioHandler.playYouTubeSong(singleTrack);
          } else {
            // If multiple tracks, we probably should open the playlist view or queue them?
            // For "Smart Play" context, if user clicked "Play" on a liked item, they expect playback.
            // Let's queue them all and play the first one?
            // Or play the first one and queue the rest?
            // Actually, playing just the first one is safe for now, or adding all to Queue.
            // Let's just play the first one to be consistent with 'Play' action.
            // Better: Replace queue with these tracks.

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Playing album (${tracks.length} tracks)...'),
                  duration: const Duration(seconds: 1)),
            );

            final mediaItems = tracks
                .map((t) => MediaItem(
                    id: t.videoId,
                    title: t.title,
                    artist: t.artist,
                    artUri: Uri.parse(t.thumbnailUrl),
                    extras: {'videoId': t.videoId, 'isOnline': true}))
                .toList();

            await _audioHandler.updateQueue(mediaItems);
            await _audioHandler.skipToQueueItem(0);
            await _audioHandler.play();
          }
        } else {
          throw Exception('No tracks found for this item');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play item: $e')),
        );
      }
      return;
    }

    final ytSong = YouTubeSong(
      videoId: song.videoId,
      title: song.title,
      artist: song.artist,
      thumbnailUrl: song.thumbnailUrl,
    );

    // Play single song or maybe queue all liked songs?
    // For now, play single using standard handler
    await _audioHandler.playYouTubeSong(ytSong);
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
