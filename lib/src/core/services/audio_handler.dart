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
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  final _settingsService = GetIt.I<SettingsService>();
  final AppDatabase _db;

  StreamSubscription<int?>? _audioSessionIdSubscription;
  bool _isInitialized = false;

  MyAudioHandler(this._db) {
    _init();
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Configure audio session
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Init equalizer
    _audioSessionIdSubscription = player.androidAudioSessionIdStream.listen((sessionId) {
      if (sessionId != null) _initEqualizer(sessionId);
    });

    // Broadcast playback state changes
    player.playbackEventStream.listen(_broadcastState);
    
    // Update state when shuffle/loop modes change
    player.shuffleModeEnabledStream.listen((_) => _broadcastState(player.playbackEvent));
    player.loopModeStream.listen((_) => _broadcastState(player.playbackEvent));

    // Sync mediaItem duration with actual player duration (fixes incorrect metadata)
    CombineLatestStream.combine2<int?, Duration?, MediaItem?>(
      player.currentIndexStream,
      player.durationStream,
      (index, duration) {
        if (index != null && index < queue.value.length) {
          final item = queue.value[index];
          if (duration != null && (item.duration == null || item.duration != duration)) {
            return item.copyWith(duration: duration);
          }
          return item;
        }
        return null;
      },
    ).listen((item) {
      if (item != null && (mediaItem.value?.id != item.id || mediaItem.value?.duration != item.duration)) {
        mediaItem.add(item);
      }
    });

    // Save state persistence
    mediaItem.stream.listen((item) {
      if (item != null) _settingsService.saveLastTrackId(item.id);
    });

    player.positionStream
        .debounceTime(const Duration(seconds: 5))
        .listen((position) => _settingsService.saveLastPosition(position));

    queue.stream.listen((q) {
      final trackIds = q.map((item) => item.id).toList();
      _settingsService.saveQueue(trackIds);
    });

    // Load initial state
    try {
      await player.setAudioSource(_playlist, preload: false);
    } catch (e) {
      // Error setting empty source is fine
    }
    await _loadInitialState();
  }

  void _broadcastState(PlaybackEvent event) {
    if (playbackState.isClosed) return;

    playbackState.add(PlaybackState(
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
      repeatMode: const {
        LoopMode.off: AudioServiceRepeatMode.none,
        LoopMode.one: AudioServiceRepeatMode.one,
        LoopMode.all: AudioServiceRepeatMode.all,
      }[player.loopMode]!,
      shuffleMode: (player.shuffleModeEnabled)
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    ));
  }

  Future<void> _initEqualizer(int sessionId) async {
    if (GetIt.I.isRegistered<EqualizerService>()) return;
    try {
      final service = EqualizerService();
      await service.init(sessionId);
      GetIt.I.registerSingleton<EqualizerService>(service);
    } catch (e) {
      // Ignore eq errors
    }
  }

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
    if (enabled) {
      await player.shuffle();
    }
    await player.setShuffleModeEnabled(enabled);
  }

  Future<void> updateQueue(List<MediaItem> newQueue) async {
    // Avoid resetting if queue is identical to prevent lag
    // if (const ListEquality().equals(queue.value, newQueue)) return;

    await _playlist.clear();
    await _playlist.addAll(newQueue.map(_createAudioSource).toList());
    queue.add(newQueue);
  }

  AudioSource _createAudioSource(MediaItem item) {
    if (item.id.startsWith('content://') || item.id.startsWith('http')) {
      return AudioSource.uri(Uri.parse(item.id), tag: item);
    }
    return AudioSource.uri(Uri.file(item.id), tag: item);
  }

  Future<void> _loadInitialState() async {
    final lastQueueIds = _settingsService.loadQueue();
    if (lastQueueIds.isEmpty) return;

    final lastTracks = await (_db.select(_db.tracks)
          ..where((t) => t.path.isIn(lastQueueIds)))
        .get();

    final sortedTracks = lastQueueIds
        .map((id) => lastTracks.firstWhereOrNull((t) => t.path == id))
        .whereNotNull()
        .toList();

    if (sortedTracks.isEmpty) return;

    final mediaItems = sortedTracks.map((track) {
        // Safely access mediaStoreId if it exists in the track object (dynamic check for now or assume generated)
        final extras = <String, dynamic>{};
        try {
           // We use dynamic access because code generation might not represent new fields yet
           // But actually we access the Drift Table class, which we just updated in app_database.dart
           if ((track as dynamic).mediaStoreId != null) {
             extras['mediaStoreId'] = (track as dynamic).mediaStoreId;
           }
        } catch (e) {
          // Field doesn't exist yet
        }

        return MediaItem(
          id: track.path,
          album: track.album ?? '',
          title: track.title,
          artist: track.artist,
          duration: Duration(milliseconds: track.duration),
          extras: extras.isEmpty ? null : extras,
        );
    }).toList();

    queue.add(mediaItems);
    try {
      await _playlist.addAll(mediaItems.map(_createAudioSource).toList());
    } catch (e) {
      // ignore
    }

    final lastTrackId = _settingsService.loadLastTrackId();
    if (lastTrackId != null) {
      final index = mediaItems.indexWhere((item) => item.id == lastTrackId);
      if (index != -1) {
        final lastPosition = _settingsService.loadLastPosition();
        await player.seek(lastPosition, index: index);
      }
    }
  }
}
