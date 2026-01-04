import 'package:flutter/material.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class PlayerScreen extends StatefulWidget {
  final Track track;

  const PlayerScreen({super.key, required this.track});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioHandler;

  @override
  void initState() {
    super.initState();
    _audioHandler = Provider.of<AudioPlayer>(context, listen: false);
    _playTrack();
  }

  void _playTrack() async {
    final mediaItem = MediaItem(
      id: widget.track.path,
      title: widget.track.title,
      artist: widget.track.artist,
      album: widget.track.album,
      duration: Duration(milliseconds: widget.track.durationMs),
    );
    await _audioHandler.setAudioSource(AudioSource.uri(Uri.file(widget.track.path), tag: mediaItem));
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
    return StreamBuilder<PositionData>(
      stream: _positionDataStream,
      builder: (context, snapshot) {
        final positionData = snapshot.data;
        final position = positionData?.position ?? Duration.zero;
        final duration = positionData?.duration ?? Duration.zero;

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
    return StreamBuilder<PlayerState>(
      stream: _audioHandler.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final playing = playerState?.playing ?? false;
        return IconButton(
          icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
          iconSize: 80,
          onPressed: playing ? _audioHandler.pause : _audioHandler.play,
        );
      },
    );
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest2<Duration, Duration?, PositionData>(
        _audioHandler.positionStream,
        _audioHandler.durationStream,
        (position, duration) => PositionData(position, duration ?? Duration.zero),
      );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class PositionData {
  final Duration position;
  final Duration duration;

  PositionData(this.position, this.duration);
}
