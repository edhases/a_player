import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:audio_session/audio_session.dart';
import '../../data/datasources/app_database.dart';
import 'settings_service.dart';
import 'equalizer_service.dart';
// Add import for YouTubeHelper
import 'youtube_helper.dart';
import '../../domain/entities/youtube_song.dart';
import '../utils/media_item_adapter.dart';
import 'audio_source_factory.dart';

/// The main audio handler that bridges just_audio with audio_service.
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  final _settingsService = GetIt.I<SettingsService>();
  final AppDatabase _db;
  // Add YouTubeHelper reference
  late final YouTubeHelper _ytHelper;
  late final AudioSourceFactory _audioSourceFactory;

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

    // Initialize YouTubeHelper if not already registered
    try {
      _ytHelper = GetIt.I<YouTubeHelper>();
      _audioSourceFactory = AudioSourceFactory(_ytHelper);
    } catch (e) {
      debugPrint(
          '[AudioHandler] YouTubeHelper not yet registered, will be lazy-loaded');
    }

    // Enable AudioSession configuration safely
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      debugPrint('[AudioHandler] AudioSession configured');
    } catch (e) {
      debugPrint('[AudioHandler] AudioSession error: $e');
    }

    // Broadcast playback state changes
    player.playbackEventStream.listen((event) {
      _broadcastState(event);
    }, onError: (Object e, StackTrace st) {
      debugPrint('[AudioHandler] PLAYER ERROR: $e. Skipping to the next item.');
      // If an error occurs (e.g., 403 Forbidden on a YouTube link),
      // automatically skip to the next track in the queue.
      if (player.hasNext) {
        skipToNext();
      } else {
        // If there's no next track, stop playback.
        stop();
      }
    });

    player.shuffleModeEnabledStream
        .listen((_) => _broadcastState(player.playbackEvent));
    player.loopModeStream.listen((_) => _broadcastState(player.playbackEvent));

    // Update current song info immediately when index changes
    player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        final item = queue.value[index];
        debugPrint(
            '[AudioHandler] Current index changed to: $index (${item.title})');
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
            debugPrint(
                '[AudioHandler] Duration updated for ${item.title}: $duration');
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
    } catch (e) {
      // ignore: empty_catches
    }

    await _loadInitialState();
    debugPrint(
        '[AudioHandler] _init completed in ${DateTime.now().difference(initStart).inMilliseconds}ms');
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
    debugPrint(
        '[AudioHandler] Playing item: ${item.title} with URI: ${item.id}');

    final start = DateTime.now();
    debugPrint('[AudioHandler] skipToQueueItem started at $start');

    // NON-BLOCKING: Don't await these to avoid UI hang on emulators
    player.seek(Duration.zero, index: index).then((_) {
      debugPrint(
          '[AudioHandler] seek finished after ${DateTime.now().difference(start).inMilliseconds}ms');
    });

    player.play().then((_) {
      debugPrint(
          '[AudioHandler] play completed after ${DateTime.now().difference(start).inMilliseconds}ms total');
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
        }[repeatMode] ??
        LoopMode.off;
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

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    final start = DateTime.now();
    debugPrint('[AudioHandler] updateQueue called with ${queue.length} items');

    if (const ListEquality().equals(this.queue.value, queue)) {
      debugPrint('[AudioHandler] updateQueue: identical, skipping');
      return;
    }

    this.queue.add(queue);

    // Perform the heavy setAudioSource operation in the background
    // to avoid potential main-thread stalls on emulators.
    _updateSourceInBackground(queue, start);
  }

  Future<void> playLocalTrack(Track track) async {
    final mediaItem = MediaItemAdapter.fromTrack(track);
    await addQueueItem(mediaItem);
    await play();
    // Optional: Jump to the newly added item (last in queue)
    await skipToQueueItem(queue.value.length - 1);
  }

  Future<void> playYouTubeSong(YouTubeSong song) async {
    final mediaItem = MediaItemAdapter.fromYouTubeSong(song);
    await addQueueItem(mediaItem);
    await play();
    await skipToQueueItem(queue.value.length - 1);
  }

  Future<void> _updateSourceInBackground(
      List<MediaItem> newQueue, DateTime start) async {
    try {
      debugPrint(
          '[AudioHandler] Background: Preparing ConcatenatingAudioSource...');
      final newSource = ConcatenatingAudioSource(
        children: newQueue.map(_audioSourceFactory.createSource).toList(),
        useLazyPreparation: true,
      );

      debugPrint('[AudioHandler] Background: Setting audio source...');
      await player.setAudioSource(newSource, preload: false);
      debugPrint(
          '[AudioHandler] Background: Source set in ${DateTime.now().difference(start).inMilliseconds}ms');
    } catch (e) {
      debugPrint('[AudioHandler] Background Error: $e');
    }
  }

  Future<void> _loadInitialState() async {
    final lastQueueIds = _settingsService.loadQueue();
    if (lastQueueIds.isEmpty) return;

    final lastTracks = await (_db.select(_db.tracks)
          ..where((t) => t.path.isIn(lastQueueIds)))
        .get();

    final sortedTracks = lastQueueIds
        .map((id) => lastTracks.firstWhereOrNull((t) => t.path == id))
        .nonNulls
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
      if (mediaItems.isNotEmpty) {
        // Ensure factory is initialized if we have items
        if (!_isInitialized)
          await _init(); // Should be init by now but safe check
        // Or if helper not registered, we can't create online sources
        // Assuming persistence primarily for local tracks or YT logic handles lazy loading

        // If factory exists (init called and passed try/catch)
        // Actually _init is called in constructor.

        await _playlist
            .addAll(mediaItems.map(_audioSourceFactory.createSource).toList());
      }
    } catch (e) {
      debugPrint('[AudioHandler] Error loading initial playlist: $e');
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
