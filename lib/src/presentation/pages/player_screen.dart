import 'package:flutter/material.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class PlayerScreen extends StatefulWidget {
  final Track track;

  const PlayerScreen({super.key, required this.track});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioHandler _audioHandler;

  @override
  void initState() {
    super.initState();
    _audioHandler = Provider.of<AudioHandler>(context, listen: false);
    _playTrack();
  }

  void _playTrack() {
    final mediaItem = MediaItem(
      id: widget.track.path,
      title: widget.track.title,
      artist: widget.track.artist,
      album: widget.track.album,
      duration: Duration(milliseconds: widget.track.durationMs),
    );
    _audioHandler.addQueueItem(mediaItem);
    _audioHandler.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 150),
            const SizedBox(height: 20),
            Text(
              widget.track.title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.track.artist ?? 'Unknown Artist',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            _buildSeekBar(),
            const SizedBox(height: 20),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeekBar() {
    return StreamBuilder<MediaState>(
      stream: _mediaStateStream,
      builder: (context, snapshot) {
        final mediaState = snapshot.data;
        final position = mediaState?.position ?? Duration.zero;
        final duration = mediaState?.mediaItem?.duration ?? Duration.zero;

        return Column(
          children: [
            Slider(
              min: 0.0,
              max: duration.inMilliseconds.toDouble(),
              value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
              onChanged: (value) {
                _audioHandler.seek(Duration(milliseconds: value.toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position)),
                  Text(_formatDuration(duration)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    return StreamBuilder<PlaybackState>(
      stream: _audioHandler.playbackState,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return IconButton(
          icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
          iconSize: 80,
          onPressed: playing ? _audioHandler.pause : _audioHandler.play,
        );
      },
    );
  }

  Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem?, Duration, MediaState>(
        _audioHandler.mediaItem,
        AudioService.position,
        (mediaItem, position) => MediaState(mediaItem, position),
      );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}
