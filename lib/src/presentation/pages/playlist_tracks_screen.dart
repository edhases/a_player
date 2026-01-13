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

  const PlaylistTracksScreen({
    super.key,
    required this.playlistId,
    required this.title,
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
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    _tracks = await _innerTube.getPlaylistTracks(widget.playlistId);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _playSong(YouTubeSong song) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Loading ${song.title}...'),
          duration: const Duration(seconds: 1)),
    );

    final url = await _ytHelper.getAudioUrl(song.videoId);
    if (url != null) {
      final duration =
          (await _ytHelper.getVideoDetails(song.videoId))?.duration;
      final desktopUA =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36';

      final mediaItem = MediaItem(
        id: url,
        title: song.title,
        artist: song.artist,
        duration: duration,
        artUri: Uri.parse(song.thumbnailUrl),
        extras: {
          'isOnline': true,
          'videoId': song.videoId,
          'user_agent': desktopUA,
        },
      );

      await _audioHandler.updateQueue([mediaItem]);
      _audioHandler.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
