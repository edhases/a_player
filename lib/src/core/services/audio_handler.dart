import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

Future<MyAudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  late AudioPlayer _player;
  final _playlist = ConcatenatingAudioSource(children: []);
  AndroidEqualizer? _equalizer;
  AndroidLoudnessEnhancer? _loudnessEnhancer;

  MyAudioHandler() {
    if (Platform.isAndroid) {
      _equalizer = AndroidEqualizer();
      _loudnessEnhancer = AndroidLoudnessEnhancer();
      _player = AudioPlayer(
        audioPipeline: AudioPipeline(
          androidAudioEffects: [
            _equalizer!,
            _loudnessEnhancer!,
          ],
        ),
      );
    } else {
      _player = AudioPlayer();
    }

    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    // Propagate the current item to the audio service stream.
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        mediaItem.add(queue.value[index]);
      }
    });
    _player.setAudioSource(_playlist);
  }

  AndroidEqualizer? get equalizer => _equalizer;

  Future<void> setEqualizerEnabled(bool enabled) async {
    if (Platform.isAndroid) {
      await _equalizer?.setEnabled(enabled);
    }
  }

  Future<void> setBandLevel(int bandIndex, double level) async {
    if (Platform.isAndroid) {
      final parameters = await _equalizer!.parameters;
      parameters.bands[bandIndex].setGain(level);
    }
  }

  Future<double> getBandLevel(int bandIndex) async {
    if (Platform.isAndroid) {
      final parameters = await _equalizer!.parameters;
      return parameters.bands[bandIndex].gain;
    }
    return 0.0;
  }

  Future<double> getCenterFreq(int bandIndex) async {
    if (Platform.isAndroid) {
      final parameters = await _equalizer!.parameters;
      return parameters.bands[bandIndex].centerFrequency;
    }
    return 0.0;
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    await _playlist.clear();
    final audioSources = mediaItems
        .map((item) => AudioSource.uri(Uri.file(item.id), tag: item))
        .toList();
    await _playlist.addAll(audioSources);
    queue.add(mediaItems);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: _getProcessingState(event.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  AudioProcessingState _getProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }
}
