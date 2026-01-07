import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_session/audio_session.dart';
import 'package:collection/collection.dart';
import '../../data/datasources/app_database.dart';
import 'settings_service.dart';
import 'equalizer_service.dart';

/// The main audio handler that bridges just_audio with audio_service.
/// 
/// This class manages all audio playback, queue management, and state persistence.
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  final _settingsService = GetIt.I<SettingsService>();
  final AppDatabase _db;

  StreamSubscription<int?>? _audioSessionIdSubscription;
  
  // Flag to prevent multiple initializations
  bool _isInitialized = false;

  MyAudioHandler(this._db) {
    _init();
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Configure audio session for music playback
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Listen for Android audio session ID to init equalizer
    _audioSessionIdSubscription = player.androidAudioSessionIdStream.listen((sessionId) {
      if (sessionId != null) {
        _initEqualizer(sessionId);
      }
    });

    // Pipe player state to audio_service playback state
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Sync mediaItem with player's current index and actual duration
    CombineLatestStream.combine2<int?, Duration?, MediaItem?>(
      player.currentIndexStream,
      player.durationStream,
      (index, duration) {
        if (index != null && index < queue.value.length) {
          final item = queue.value[index];
          if (duration != null && (item.duration == null || item.duration == Duration.zero)) {
            return item.copyWith(duration: duration);
          }
          return item;
        }
        return null;
      },
    ).listen((item) {
      if (item != null && mediaItem.value?.id != item.id || mediaItem.value?.duration != item.duration) {
        mediaItem.add(item);
      }
    });

    // Persist current track ID
    mediaItem.stream.listen((item) {
      if (item != null) {
        _settingsService.saveLastTrackId(item.id);
      }
    });

    // Persist position every 5 seconds (debounced)
    player.positionStream
        .debounceTime(const Duration(seconds: 5))
        .listen((position) {
      _settingsService.saveLastPosition(position);
    });

    // Persist queue when it changes
    queue.stream.listen((q) {
      final trackIds = q.map((item) => item.id).toList();
      _settingsService.saveQueue(trackIds);
    });

    // Sync loop mode to playback state
    player.loopModeStream.listen((loopMode) {
      playbackState.add(playbackState.value.copyWith(
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[loopMode]!,
      ));
    });

    // Sync shuffle mode to playback state
    player.shuffleModeEnabledStream.listen((enabled) {
      playbackState.add(playbackState.value.copyWith(
        shuffleMode: enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      ));
    });

    // Set the audio source FIRST, then load initial state
    await player.setAudioSource(_playlist, preload: false);
    await _loadInitialState();
  }

  Future<void> _initEqualizer(int sessionId) async {
    if (GetIt.I.isRegistered<EqualizerService>()) return;

    try {
      final equalizerService = EqualizerService();
      await equalizerService.init(sessionId);
      GetIt.I.registerSingleton<EqualizerService>(equalizerService);
    } catch (e) {
      // Equalizer initialization may fail on some devices, ignore
    }
  }

  // --- Audio Service Overrides ---

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    if (GetIt.I.isRegistered<EqualizerService>()) {
      GetIt.I<EqualizerService>().dispose();
      GetIt.I.unregister<EqualizerService>();
    }
    _audioSessionIdSubscription?.cancel();
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() => player.seekToNext();

  @override
  Future<void> skipToPrevious() => player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await player.seek(Duration.zero, index: index);
    await player.play();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final loopMode = const {
      AudioServiceRepeatMode.none: LoopMode.off,
      AudioServiceRepeatMode.one: LoopMode.one,
      AudioServiceRepeatMode.all: LoopMode.all,
      AudioServiceRepeatMode.group: LoopMode.all,
    }[repeatMode] ?? LoopMode.off;
    await player.setLoopMode(loopMode);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    await player.setShuffleModeEnabled(enabled);
    if (enabled) {
      await player.shuffle();
    }
  }

  /// Updates the playback queue with new items.
  /// 
  /// This clears the current playlist and adds all new items.
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    await _playlist.clear();
    await _playlist.addAll(newQueue.map(_createAudioSource).toList());
    queue.add(newQueue);
  }

  AudioSource _createAudioSource(MediaItem item) {
    if (item.id.startsWith('content://')) {
      return AudioSource.uri(Uri.parse(item.id), tag: item);
    }
    return AudioSource.uri(Uri.file(item.id), tag: item);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    );
  }

  Future<void> _loadInitialState() async {
    final lastQueueIds = _settingsService.loadQueue();
    if (lastQueueIds.isEmpty) return;

    final lastTracks = await (_db.select(_db.tracks)
          ..where((t) => t.path.isIn(lastQueueIds)))
        .get();

    // Sort tracks to match the saved queue order
    final sortedTracks = lastQueueIds
        .map((id) => lastTracks.firstWhereOrNull((t) => t.path == id))
        .whereNotNull()
        .toList();

    if (sortedTracks.isEmpty) return;

    final mediaItems = sortedTracks
        .map((track) => MediaItem(
              id: track.path,
              album: track.album ?? '',
              title: track.title,
              artist: track.artist,
              duration: Duration(milliseconds: track.duration),
            ))
        .toList();

    queue.add(mediaItems);
    await _playlist.addAll(mediaItems.map(_createAudioSource).toList());

    // Restore last playing track and position
    final lastTrackId = _settingsService.loadLastTrackId();
    if (lastTrackId != null) {
      final index = mediaItems.indexWhere((item) => item.id == lastTrackId);
      if (index != -1) {
        final lastPosition = _settingsService.loadLastPosition();
        // Wait for the player to be ready before seeking
        await player.load();
        await player.seek(lastPosition, index: index);
      }
    }
  }
}
