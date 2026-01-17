import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import '../../core/services/innertube_service.dart';
import '../../core/services/youtube_helper.dart';

import '../../core/services/audio_handler.dart';
import '../../domain/entities/youtube_song.dart';
import '../widgets/common_artwork.dart';

class PlaylistTracksScreen extends StatefulWidget {
  final String playlistId;
  final String title;
  final String? knownArtist; // Pass artist if known from previous screen
  final String? knownThumbnail; // Pass thumbnail if known from previous screen
  final List<YouTubeSong>? preloadedTracks; // Optional pre-fetched tracks

  const PlaylistTracksScreen({
    super.key,
    required this.playlistId,
    required this.title,
    this.knownArtist,
    this.knownThumbnail,
    this.preloadedTracks,
  });

  @override
  State<PlaylistTracksScreen> createState() => _PlaylistTracksScreenState();
}

class _PlaylistTracksScreenState extends State<PlaylistTracksScreen> {
  final _innerTube = InnerTubeService();
  final _ytHelper = GetIt.I<YouTubeHelper>();
  final _audioHandler = GetIt.I<MyAudioHandler>();

  bool _isLoading = true;
  List<YouTubeSong> _tracks = [];

  @override
  void initState() {
    super.initState();
    if (widget.preloadedTracks != null && widget.preloadedTracks!.isNotEmpty) {
      _tracks = widget.preloadedTracks!;
      _isLoading = false;
    } else {
      _loadTracks();
    }
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    var fetchedTracks = await _innerTube.getPlaylistTracks(widget.playlistId);

    // Patch missing artist/thumbnail data using knownMetadata
    fetchedTracks = fetchedTracks.map((song) {
      var updatedSong = song;

      // Apply Artist Fallback
      if ((updatedSong.artist == 'Unknown' || updatedSong.artist.isEmpty) &&
          widget.knownArtist != null &&
          widget.knownArtist != 'Unknown') {
        updatedSong = updatedSong.copyWith(artist: widget.knownArtist);
      }

      // Apply Thumbnail Fallback
      // Checks if empty or if it's a generic default if we had one (usually empty)
      if (updatedSong.thumbnailUrl.isEmpty && widget.knownThumbnail != null) {
        updatedSong = updatedSong.copyWith(thumbnailUrl: widget.knownThumbnail);
      }

      return updatedSong;
    }).toList();

    _tracks = fetchedTracks;

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _playSong(YouTubeSong song) async {
    final index = _tracks.indexOf(song);
    if (index == -1) return;

    // Convert all tracks to MediaItems for lazy loading
    final queue = _tracks.map((track) {
      return MediaItem(
        id: track.videoId, // Use videoId as ID for uniqueness/matching
        title: track.title,
        artist: track.artist,
        artUri: Uri.parse(track.thumbnailUrl),
        extras: {
          'isOnline': true,
          'videoId': track.videoId,
        },
      );
    }).toList();

    // Update queue and skip to the selected song
    await _audioHandler.updateQueue(queue);
    await _audioHandler.skipToQueueItem(index);
    _audioHandler.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No tracks found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This playlist might be empty or restricted.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTracks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final song = _tracks[index];
                    return ListTile(
                      leading: CommonArtwork(url: song.thumbnailUrl, size: 50),
                      title: Text(song.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(song.artist,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => _playSong(song),
                    );
                  },
                ),
    );
  }
}
