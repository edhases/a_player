import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/datasources/app_database.dart';
import 'settings_service.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  final _settingsService = GetIt.I<SettingsService>();
  final AppDatabase _db;

  MyAudioHandler(this._db) {
    _init();
  }

  Future<void> _init() async {
    // Listen for state changes to persist them.
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Listen for media item changes.
    mediaItem.stream.listen((item) {
      if (item != null) {
        _settingsService.saveLastTrackId(item.id);
      }
    });

    // Listen for position changes to save them periodically.
    _player.positionStream
      .debounceTime(const Duration(seconds: 5))
      .listen((position) {
        _settingsService.saveLastPosition(position);
    });

    // Listen for queue changes.
    queue.stream.listen((q) {
      final trackIds = q.map((item) => item.id).toList();
      _settingsService.saveQueue(trackIds);
    });

    // Load the initial state from storage.
    await _loadInitialState();

    // Set the audio source.
    await _player.setAudioSource(_playlist, preload: false);
  }

  Future<void> _loadInitialState() async {
    final lastQueueIds = _settingsService.loadQueue();
    final lastTrackId = _settingsService.loadLastTrackId();
    final lastPosition = _settingsService.loadLastPosition();

    if (lastQueueIds.isNotEmpty) {
      // Fetch the full track data from the database.
      final tracks = await (_db.select(_db.tracks)..where((t) => t.path.isIn(lastQueueIds))).get();
      // Maintain the saved order
      final orderedTracks = lastQueueIds
          .map((id) => tracks.firstWhere((track) => track.path == id, orElse: () => null))
          .where((t) => t != null)
          .cast<Track>()
          .toList();

      final mediaItems = orderedTracks.map(_trackToMediaItem).toList();
      await updateQueue(mediaItems);

      final lastIndex = lastTrackId != null ? lastQueueIds.indexOf(lastTrackId) : -1;
      if (lastIndex != -1) {
        await _player.seek(lastPosition, index: lastIndex);
      }
    }

    // Load and apply shuffle/repeat modes.
    final shuffleMode = _settingsService.loadShuffleMode();
    await setShuffleMode(shuffleMode);

    final repeatMode = _settingsService.loadRepeatMode();
    await setRepeatMode(repeatMode);
  }

  MediaItem _trackToMediaItem(Track track) {
    return MediaItem(
      id: track.path,
      album: track.album,
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
    );
  }

  AudioSource _createAudioSource(MediaItem mediaItem) {
    return AudioSource.uri(Uri.file(mediaItem.id), tag: mediaItem);
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    final audioSources = newQueue.map(_createAudioSource).toList();
    await _playlist.clear();
    await _playlist.addAll(audioSources);
    queue.add(newQueue);
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final audioSources = mediaItems.map(_createAudioSource).toList();
    await _playlist.addAll(audioSources);
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.seek(Duration.zero, index: index);
    play();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(shuffleMode == AudioServiceShuffleMode.all);
    await _settingsService.saveShuffleMode(shuffleMode);
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final justAudioMode = repeatMode == AudioServiceRepeatMode.one ? LoopMode.one :
                          repeatMode == AudioServiceRepeatMode.all ? LoopMode.all : LoopMode.off;
    await _player.setLoopMode(justAudioMode);
    await _settingsService.saveRepeatMode(repeatMode);
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _getProcessingState(event.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
      shuffleMode: _player.shuffleModeEnabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      repeatMode: _getAudioServiceRepeatMode(_player.loopMode),
    );
  }

  AudioProcessingState _getProcessingState(ProcessingState state) {
    // ... (same as before)
    switch (state) {
      case ProcessingState.idle: return AudioProcessingState.idle;
      case ProcessingState.loading: return AudioProcessingState.loading;
      case ProcessingState.buffering: return AudioProcessingState.buffering;
      case ProcessingState.ready: return AudioProcessingState.ready;
      case ProcessingState.completed: return AudioProcessingState.completed;
    }
  }

  AudioServiceRepeatMode _getAudioServiceRepeatMode(LoopMode loopMode) {
    // ... (same as before)
    switch (loopMode) {
      case LoopMode.off: return AudioServiceRepeatMode.none;
      case LoopMode.one: return AudioServiceRepeatMode.one;
      case LoopMode.all: return AudioServiceRepeatMode.all;
    }
  }
}
