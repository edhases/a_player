import 'package:flutter/material.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:audio_service/audio_service.dart';
import 'package:oxide_player/main.dart';
import 'package:rxdart/rxdart.dart';

class PlayerScreen extends StatefulWidget {
  final Track track;

  const PlayerScreen({super.key, required this.track});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioHandler _audioHandler;
  late Stream<PositionData> _positionDataStream;

  @override
  void initState() {
    super.initState();
    _audioHandler = getIt<AudioHandler>();
    _positionDataStream = Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      AudioService.position,
      _audioHandler.playbackState.map((state) => state.bufferedPosition),
      _audioHandler.mediaItem.map((item) => item?.duration),
      (position, bufferedPosition, duration) =>
          PositionData(position, duration ?? Duration.zero),
    );
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
    return StreamBuilder<PlaybackState>(
      stream: _audioHandler.playbackState,
      builder: (context, snapshot) {
        final playbackState = snapshot.data;
        final playing = playbackState?.playing ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: 60,
              onPressed: _audioHandler.skipToPrevious,
            ),
            IconButton(
              icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
              iconSize: 80,
              onPressed: playing ? _audioHandler.pause : _audioHandler.play,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: 60,
              onPressed: _audioHandler.skipToNext,
            ),
          ],
        );
      },
    );
  }

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
