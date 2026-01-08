import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_session/audio_session.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
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

    final initStart = DateTime.now();
    debugPrint('[AudioHandler] _init started');

    // DISABLE AudioSession configuration on emulators as it often hangs
    /*
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      debugPrint('[AudioHandler] AudioSession configured');
    } catch (e) {
      debugPrint('[AudioHandler] AudioSession error: $e');
    }
    */

    // Broadcast playback state changes
    player.playbackEventStream.listen((event) {
      _broadcastState(event);
    }, onError: (Object e, StackTrace st) {
      debugPrint('[AudioHandler] PLAYER ERROR: $e');
    });
    
    player.shuffleModeEnabledStream.listen((_) => _broadcastState(player.playbackEvent));
    player.loopModeStream.listen((_) => _broadcastState(player.playbackEvent));

    // Update current song info immediately when index changes
    player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        final item = queue.value[index];
        debugPrint('[AudioHandler] Current index changed to: $index (${item.title})');
        mediaItem.add(item);
      }
    });

    // Separately update duration when it becomes available
    player.durationStream.listen((duration) {
      if (duration != null) {
        final index = player.currentIndex;
        if (index != null && index < queue.value.length) {
          final item = queue.value[index];
          if (item.duration != duration) {
            debugPrint('[AudioHandler] Duration updated for ${item.title}: $duration');
            mediaItem.add(item.copyWith(duration: duration));
          }
        }
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

    try {
      await player.setAudioSource(_playlist, preload: false);
    } catch (e) {}
    
    await _loadInitialState();
    debugPrint('[AudioHandler] _init completed in ${DateTime.now().difference(initStart).inMilliseconds}ms');
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
    final item = queue.value[index];
    debugPrint('[AudioHandler] Playing item: ${item.title} with URI: ${item.id}');
    
    final start = DateTime.now();
    debugPrint('[AudioHandler] skipToQueueItem started at $start');
    
    // NON-BLOCKING: Don't await these to avoid UI hang on emulators
    player.seek(Duration.zero, index: index).then((_) {
      debugPrint('[AudioHandler] seek finished after ${DateTime.now().difference(start).inMilliseconds}ms');
    });
    
    player.play().then((_) {
      debugPrint('[AudioHandler] play completed after ${DateTime.now().difference(start).inMilliseconds}ms total');
    }).catchError((e) {
      debugPrint('[AudioHandler] play error: $e');
    });
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
    final start = DateTime.now();
    debugPrint('[AudioHandler] updateQueue called with ${newQueue.length} items');
    
    if (const ListEquality().equals(queue.value, newQueue)) {
      debugPrint('[AudioHandler] updateQueue: identical, skipping');
      return;
    }

    queue.add(newQueue);
    
    // Perform the heavy setAudioSource operation in the background
    // to avoid potential main-thread stalls on emulators.
    _updateSourceInBackground(newQueue, start);
  }

  Future<void> _updateSourceInBackground(List<MediaItem> newQueue, DateTime start) async {
    try {
      debugPrint('[AudioHandler] Background: Preparing ConcatenatingAudioSource...');
      final newSource = ConcatenatingAudioSource(
        children: newQueue.map(_createAudioSource).toList(),
        useLazyPreparation: true,
      );

      debugPrint('[AudioHandler] Background: Setting audio source...');
      await player.setAudioSource(newSource, preload: false);
      debugPrint('[AudioHandler] Background: Source set in ${DateTime.now().difference(start).inMilliseconds}ms');
    } catch (e) {
      debugPrint('[AudioHandler] Background Error: $e');
    }
  }

  AudioSource _createAudioSource(MediaItem item) {
    debugPrint('[AudioHandler] Creating AudioSource for ${item.title}');
    
    if (item.id.startsWith('content://')) {
      debugPrint('[AudioHandler] Source: Content URI: ${item.id}');
      return AudioSource.uri(Uri.parse(item.id), tag: item);
    }
    
    if (item.id.startsWith('http')) {
      final headers = <String, String>{};
      
      if (item.extras != null && item.extras!.containsKey('user_agent')) {
        headers['User-Agent'] = item.extras!['user_agent'];
      }
      else if (item.id.contains('googlevideo.com')) {
         // Standard mobile YouTube Music User-Agent often works well with these headers
         headers['User-Agent'] = 'com.google.android.apps.youtube.music/6.33.51 (Linux; U; Android 11; US) gzip';
         headers['Origin'] = 'https://www.youtube.com';
         headers['Referer'] = 'https://www.youtube.com/';
      }
      
      debugPrint('[AudioHandler] Source: HTTP URL: ${item.id.substring(0, item.id.length > 100 ? 100 : item.id.length)}...');
      debugPrint('[AudioHandler] Headers: $headers');
      
      return AudioSource.uri(Uri.parse(item.id), tag: item, headers: headers.isEmpty ? null : headers);
    }
    
    debugPrint('[AudioHandler] Source: File path: ${item.id}');
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
        final extras = <String, dynamic>{};
        if ((track as dynamic).mediaStoreId != null) {
          extras['mediaStoreId'] = (track as dynamic).mediaStoreId;
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
