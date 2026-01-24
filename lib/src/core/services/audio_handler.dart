import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import 'package:audio_session/audio_session.dart';
import '../../data/datasources/app_database.dart';
import 'settings_service.dart';
import 'equalizer_service.dart';
import 'log_service.dart';
import '../../core/services/youtube_helper.dart';

import '../../domain/entities/youtube_song.dart';
import '../utils/media_item_adapter.dart';
import 'audio_source_factory.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/services/metadata_matching_service.dart';
import '../../core/services/innertube_service.dart';

/// The main audio handler that bridges just_audio with audio_service.
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _equalizer = AndroidEqualizer();
  late final AudioPlayer player;

  // Note: We use the player's session ID if needed, but internal equalizer logic handles itself.
  int? get audioSessionId => player.androidAudioSessionId;

  final _playlist = ConcatenatingAudioSource(children: []);

  final AppDatabase _db;
  final SettingsService _settingsService;
  final AudioSourceFactory _audioSourceFactory;
  final RecommendationService _recommendationService;
  final InnerTubeService _innerTubeService;
  final MetadataMatchingService? _metadataMatchingService;
  final LogService? _logService;

  StreamSubscription<int?>? _audioSessionIdSubscription;
  StreamSubscription<TrackOverride?>? _currentOverrideSubscription;
  bool _isInitialized = false;

  // YouTube playback history tracking
  final Set<String> _reportedVideoIds = {};
  int? _lastReportedIndex;

  MyAudioHandler({
    required AppDatabase db,
    required SettingsService settingsService,
    required AudioSourceFactory audioSourceFactory,
    required RecommendationService recommendationService,
    required InnerTubeService innerTubeService,
    MetadataMatchingService? metadataMatchingService,
    LogService? logService,
    AudioPlayer? audioPlayer, // DI for testing
  })  : _db = db,
        _settingsService = settingsService,
        _audioSourceFactory = audioSourceFactory,
        _recommendationService = recommendationService,
        _innerTubeService = innerTubeService,
        _metadataMatchingService = metadataMatchingService,
        _logService = logService {
    player = audioPlayer ??
        AudioPlayer(
          audioPipeline: AudioPipeline(
            androidAudioEffects: [
              _equalizer,
            ],
          ),
        );
    _init();
  }

  void _logError(String message, [Object? error]) {
    debugPrint(message);
    _logService?.error(message, error: error);
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final initStart = DateTime.now();
    debugPrint('[AudioHandler] _init started');

    _initEqualizer();

    // Dependencies are now injected via constructor

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
    player.currentIndexStream.distinct().listen((index) {
      if (index != null && index < queue.value.length) {
        final item = queue.value[index];
        debugPrint(
            '[AudioHandler] 🎵 Current index changed to: $index ("${item.title}")');

        // Check if metadata matches source
        final previousItem = mediaItem.value;
        if (previousItem != null && previousItem.id != item.id) {
          debugPrint(
              '[AudioHandler] Transition: "${previousItem.title}" -> "${item.title}"');
        }

        mediaItem.add(item);
        _setupOverrideWatcher(item.id);
      } else {
        debugPrint(
            '[AudioHandler] ⚠️ Current index is null or out of bounds: $index (Queue len: ${queue.value.length})');
        _currentOverrideSubscription?.cancel();
      }
    });

    // Separately update duration when it becomes available
    player.durationStream.listen((duration) {
      if (duration != null && duration > Duration.zero) {
        final index = player.currentIndex;
        if (index != null && index < queue.value.length) {
          final item = queue.value[index];
          // Only update if duration is significantly different or item duration was zero
          if (item.duration != duration) {
            // Check if we already had a valid duration (e.g. > 10s) and new one represents known length
            // just_audio might emit precise duration after buffering.
            debugPrint(
                '[AudioHandler] Duration updated for ${item.title}: $duration (was ${item.duration})');
            mediaItem.add(item.copyWith(duration: duration));

            // Should we also update the queue item?
            // Yes, otherwise switching back to this track might revert duration.
            final newItem = item.copyWith(duration: duration);
            final newQueue = List<MediaItem>.from(queue.value);
            newQueue[index] = newItem;
            queue.add(newQueue);
            // Also update current MediaItem to reflect change in UI
            mediaItem.add(newItem);
          }
        }
      }
    });

    // ICY Metadata Listener for Radio
    player.icyMetadataStream.listen((metadata) {
      if (metadata != null && metadata.info != null) {
        debugPrint(
            '[AudioHandler] ICY Metadata: ${metadata.info?.title} - ${metadata.info?.url}');

        final current = mediaItem.value;
        if (current != null && current.extras?['isRadio'] == true) {
          final title = metadata.info?.title;
          if (title != null && title.isNotEmpty) {
            final newItem = current.copyWith(
              artist: title,
            );
            mediaItem.add(newItem);
          }
        }
      }
    });

    // Initialize InnerTubeService for playback history reporting
    // Injected: _innerTubeService

    // Save state persistence
    mediaItem.stream.listen((item) {
      if (item != null) _settingsService.saveLastTrackId(item.id);
    });

    player.positionStream
        .debounceTime(const Duration(seconds: 5))
        .listen((position) => _settingsService.saveLastPosition(position));

    // YouTube playback history tracking - report after 30 seconds
    player.positionStream
        .where((pos) => pos.inSeconds >= 30)
        .distinct()
        .listen((position) => _reportPlaybackHistory());

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

  Future<void> _initEqualizer() async {
    try {
      if (!GetIt.I.isRegistered<EqualizerService>()) {
        final eqService = EqualizerService();
        await eqService.init(_equalizer);
        GetIt.I.registerSingleton<EqualizerService>(eqService);
        debugPrint(
            '[AudioHandler] EqualizerService initialized with AndroidEqualizer');
      }
    } catch (e) {
      debugPrint('[AudioHandler] Failed to init equalizer: $e');
    }
  }

  /// Report current playing YouTube track to YouTube history
  void _reportPlaybackHistory() {
    final index = player.currentIndex;
    if (index == null) return;

    // Don't report same track twice in this session
    if (_lastReportedIndex == index) return;

    if (index >= queue.value.length) return;
    final item = queue.value[index];

    // Only report YouTube tracks (online or cached)
    final videoId = item.extras?['videoId'] as String?;

    if (videoId == null) return;

    // Check if we are online before reporting?
    // InnerTubeService handles errors, so we can just fire and forget.
    // Ideally we should check connectivity to avoid log spam, but Dio handles it.

    // Don't report same video twice
    if (_reportedVideoIds.contains(videoId)) return;

    debugPrint(
        '[AudioHandler] Reporting playback history for: $videoId (${item.title}), Cached: ${!(item.extras?['isOnline'] ?? false)}');
    _lastReportedIndex = index;
    _reportedVideoIds.add(videoId);

    // Fire-and-forget reporting
    _innerTubeService.getPlaybackTrackingUrl(videoId).then((trackingUrl) {
      if (trackingUrl != null) {
        _innerTubeService.reportPlayback(trackingUrl);
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    if (playbackState.isClosed) return;

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[player.processingState] ??
          AudioProcessingState.idle,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
      repeatMode: const {
            LoopMode.off: AudioServiceRepeatMode.none,
            LoopMode.one: AudioServiceRepeatMode.one,
            LoopMode.all: AudioServiceRepeatMode.all,
          }[player.loopMode] ??
          AudioServiceRepeatMode.none,
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
      // GetIt.I.unregister<EqualizerService>(); // Usually better to keep singleton?
      // User might re-init, so maybe keep it.
    }
    _audioSessionIdSubscription?.cancel();
    _currentOverrideSubscription?.cancel();
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

    // NON-BLOCKING: Don't await these to avoid UI hang on emulators
    player.seek(Duration.zero, index: index);
    player.play();
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
    debugPrint('[AudioHandler] updateQueue called with ${queue.length} items');

    if (const ListEquality().equals(this.queue.value, queue)) {
      debugPrint('[AudioHandler] updateQueue: identical, skipping');
      return;
    }

    try {
      // 1. Pre-create all sources to ensure validity
      final sources = await Future.wait(
          queue.map((item) => _audioSourceFactory.createSource(item)));

      // 2. Update Queue (UI) FIRST - CRITICAL!
      // This must happen BEFORE playlist modification so that
      // currentIndexStream listener has valid queue data when just_audio
      // auto-seeks to index 0 after playlist clear/add.
      this.queue.add(queue);

      // 3. Update Playlist
      await _playlist.clear();
      await _playlist.addAll(sources);

      debugPrint('[AudioHandler] updateQueue: queue and _playlist updated');
    } catch (e) {
      debugPrint('[AudioHandler] updateQueue error: $e');
      // Rollback queue on failure
      this.queue.add([]);
    }
  }

  /// Atomically set queue and start playing from a specific index.
  /// This prevents the ExoPlayer init race condition where index resets to 0.
  Future<void> playQueueFromIndex(
      List<MediaItem> newQueue, int startIndex) async {
    debugPrint(
        '[AudioHandler] playQueueFromIndex: ${newQueue.length} items, startIndex=$startIndex');

    if (newQueue.isEmpty) return;
    final safeIndex = startIndex.clamp(0, newQueue.length - 1);

    try {
      // 1. Update UI queue first
      queue.add(newQueue);

      // 2. Create audio sources
      final sources = await Future.wait(
          newQueue.map((item) => _audioSourceFactory.createSource(item)));

      // 3. Clear and rebuild playlist
      await _playlist.clear();
      await _playlist.addAll(sources);

      // 4. Set audio source with initial index - THIS IS THE KEY!
      // Using setAudioSource instead of just seek ensures ExoPlayer
      // initializes with the correct starting position.
      await player.setAudioSource(_playlist, initialIndex: safeIndex);

      // 5. Start playback
      await player.play();

      debugPrint(
          '[AudioHandler] playQueueFromIndex: started at index $safeIndex');
    } catch (e) {
      debugPrint('[AudioHandler] playQueueFromIndex error: $e');
    }
  }

  Future<TrackOverride?> _getOverride(String path) async {
    try {
      if (_metadataMatchingService != null) {
        return await _metadataMatchingService!.getTrackOverride(path);
      }
    } catch (e) {
      // Service might not be ready
    }
    return null;
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    debugPrint(
        '[AudioHandler] addQueueItem: ${mediaItem.title}, duration IN QUEUE=${mediaItem.duration}');
    try {
      // 1. Create source
      final source = await _audioSourceFactory.createSource(mediaItem);

      // 2. Add to Playlist
      await _playlist.add(source);

      // 3. Update Queue
      await super.addQueueItem(mediaItem);

      debugPrint(
          '[AudioHandler] addQueueItem: Added ${mediaItem.title} to _playlist and queue');
    } catch (e) {
      debugPrint('[AudioHandler] addQueueItem error: $e');
    }
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem item) async {
    debugPrint('[AudioHandler] insertQueueItem at $index: ${item.title}');
    try {
      // 1. Create source
      final source = await _audioSourceFactory.createSource(item);

      // 2. Insert into Playlist
      await _playlist.insert(index, source);

      // 3. Update Queue
      await super.insertQueueItem(index, item);
    } catch (e) {
      debugPrint('[AudioHandler] insertQueueItem error: $e');
    }
  }

  @override
  Future<void> removeQueueItem(MediaItem item) async {
    final index = queue.value.indexWhere((i) => i.id == item.id);
    debugPrint('[AudioHandler] removeQueueItem at $index: ${item.title}');
    await super.removeQueueItem(item);

    if (index != -1) {
      try {
        await _playlist.removeAt(index);
      } catch (e) {
        debugPrint('[AudioHandler] removeQueueItem error: $e');
      }
    }
  }

  Future<void> addToQueue(Track track) async {
    final override = await _getOverride(track.path);
    final item = MediaItemAdapter.fromTrack(track, override);
    await addQueueItem(item);
  }

  Future<void> playNext(Track track) async {
    final override = await _getOverride(track.path);
    final item = MediaItemAdapter.fromTrack(track, override);
    final index = player.currentIndex ?? 0;

    // Use insertQueueItem which now handles both Queue and Playlist safely
    await insertQueueItem(index + 1, item);
    debugPrint('[AudioHandler] Playing next: ${track.title}');
  }

  Future<void> playLocalTrack(Track track) async {
    final override = await _getOverride(track.path);
    final mediaItem = MediaItemAdapter.fromTrack(track, override);

    debugPrint('[AudioHandler] playLocalTrack: ${mediaItem.title}');

    // Clear and set new queue
    queue.add([mediaItem]);

    try {
      await _playlist.clear();
      final source = await _audioSourceFactory.createSource(mediaItem);
      await _playlist.add(source);

      // Seek to beginning and play
      await player.seek(Duration.zero, index: 0);
      await player.play();
    } catch (e) {
      debugPrint('[AudioHandler] playLocalTrack error: $e');
    }
  }

  Future<void> addYouTubeToQueue(YouTubeSong song) async {
    final mediaItem = MediaItemAdapter.fromYouTubeSong(song);
    debugPrint('[AudioHandler] addYouTubeToQueue: ${song.title}');
    await addQueueItem(mediaItem);
  }

  Future<void> playYouTubeSong(YouTubeSong song,
      {bool loadRadioQueue = true}) async {
    final mediaItem = MediaItemAdapter.fromYouTubeSong(song);
    debugPrint('[AudioHandler] playYouTubeSong: ${song.title}');

    // Record history
    _recommendationService
        .addToHistoryManual(
      videoId: song.videoId,
      title: song.title,
      artist: song.artist,
      thumbnailUrl: song.thumbnailUrl,
    )
        .catchError((e) {
      debugPrint('[AudioHandler] Error adding to history: $e');
    });

    queue.add([mediaItem]);

    try {
      await _playlist.clear();
      final source = await _audioSourceFactory.createSource(mediaItem);
      await _playlist.add(source);

      await player.seek(Duration.zero, index: 0);

      if (loadRadioQueue && song.videoId.length == 11) {
        _loadRadioQueue(song.videoId);
      }

      await player.play();
    } catch (e) {
      debugPrint('[AudioHandler] playYouTubeSong error: $e');
    }
  }

  Future<void> playRadioStation(RadioStation station) async {
    debugPrint('[AudioHandler] playing radio station: ${station.name}');

    final mediaItem = MediaItem(
      id: station.streamUrl,
      album: 'Radio',
      title: station.name,
      artist: 'Live Stream',
      artUri: station.imageUrl != null ? Uri.parse(station.imageUrl!) : null,
      extras: {
        'isOnline': true,
        'isRadio': true,
        'radioId': station.id,
      },
    );

    queue.add([mediaItem]);

    try {
      await _playlist.clear();
      final source = await _audioSourceFactory.createSource(mediaItem);
      await _playlist.add(source);

      await player.seek(Duration.zero, index: 0);
      await player.play();
    } catch (e) {
      _logError('[AudioHandler] playRadioStation error', e);
    }
  }

  Future<void> _loadRadioQueue(String videoId) async {
    try {
      debugPrint('[AudioHandler] Loading radio queue for $videoId...');
      // Using injected service
      final radioTracks = await _innerTubeService.getRadioTracks(videoId);

      if (radioTracks.isEmpty) {
        debugPrint('[AudioHandler] No radio tracks found');
        return;
      }

      final currentIds = queue.value.map((m) => m.id).toSet();
      final tracksToAdd = radioTracks
          .where((t) => !currentIds.contains(t.videoId))
          .take(25)
          .toList();

      for (final track in tracksToAdd) {
        final mi = MediaItemAdapter.fromYouTubeSong(track);
        await addQueueItem(mi);
      }
    } catch (e) {
      debugPrint('[AudioHandler] Error loading radio queue: $e');
    }
  }

  void _setupOverrideWatcher(String trackPath) {
    _currentOverrideSubscription?.cancel();

    final currentItem = mediaItem.value;
    if (currentItem?.extras?['isOnline'] == true) return;

    if (_metadataMatchingService != null) {
      _currentOverrideSubscription = _metadataMatchingService!
          .watchTrackOverride(trackPath)
          .listen((override) {
        if (override == null) return;

        final currentItem = mediaItem.value;
        if (currentItem?.id == trackPath) {
          String? newArtist = override.correctArtist;
          if ((newArtist == 'Unknown' ||
                  newArtist == null ||
                  newArtist.isEmpty) &&
              currentItem?.artist != null &&
              currentItem!.artist != 'Unknown') {
            newArtist = currentItem.artist;
          }

          final newItem = currentItem!.copyWith(
            title: override.correctTitle ?? currentItem.title,
            artist: newArtist ?? currentItem.artist,
            artUri: override.thumbnailUrl != null &&
                    override.thumbnailUrl!.isNotEmpty
                ? Uri.parse(override.thumbnailUrl!)
                : currentItem.artUri,
          );
          mediaItem.add(newItem);

          final index = queue.value.indexWhere((i) => i.id == trackPath);
          if (index != -1) {
            final newQueue = List<MediaItem>.from(queue.value);
            newQueue[index] = newItem;
            queue.add(newQueue);
          }
        }
      });
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

    final overrides = await Future.wait(
      sortedTracks.map((t) => _getOverride(t.path)),
    );

    final mediaItems = List<MediaItem>.generate(sortedTracks.length, (index) {
      return MediaItemAdapter.fromTrack(sortedTracks[index], overrides[index]);
    });

    queue.add(mediaItems);
    try {
      if (mediaItems.isNotEmpty) {
        if (!_isInitialized) await _init();
        final sources = await Future.wait(
            mediaItems.map((item) => _audioSourceFactory.createSource(item)));
        await _playlist.addAll(sources);
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
