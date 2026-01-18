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
import 'log_service.dart';
// Add import for YouTubeHelper
// Add import for YouTubeHelper

import '../../domain/entities/youtube_song.dart';
import '../utils/media_item_adapter.dart';
import 'audio_source_factory.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/services/metadata_matching_service.dart';
import '../../core/services/innertube_service.dart';
import '../../data/models/local_track_override.dart';

/// The main audio handler that bridges just_audio with audio_service.
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  final _settingsService = GetIt.I<SettingsService>();
  final AppDatabase _db;
  // Add YouTubeHelper reference
  late final AudioSourceFactory _audioSourceFactory;
  late final RecommendationService _recommendationService;

  StreamSubscription<int?>? _audioSessionIdSubscription;
  StreamSubscription<LocalTrackOverride?>? _currentOverrideSubscription;
  bool _isInitialized = false;

  // YouTube playback history tracking
  final Set<String> _reportedVideoIds = {};
  int? _lastReportedIndex;
  InnerTubeService? _innerTubeService;

  MyAudioHandler(this._db) {
    _init();
  }

  void _logError(String message, [Object? error]) {
    debugPrint(message); // Keep debug print
    if (GetIt.I.isRegistered<LogService>()) {
      GetIt.I<LogService>().error(message, error: error);
    }
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final initStart = DateTime.now();
    debugPrint('[AudioHandler] _init started');

    // Initialize YouTubeHelper if not already registered
    try {
      _audioSourceFactory = GetIt.I<AudioSourceFactory>();
      _recommendationService = GetIt.I<RecommendationService>();
    } catch (e) {
      debugPrint(
          '[AudioHandler] Dependencies not yet registered, will be lazy-loaded: $e');
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

    // Initialize Equalizer when audio session ID is available (Android only)
    _audioSessionIdSubscription =
        player.androidAudioSessionIdStream.listen((sessionId) async {
      debugPrint(
          '[AudioHandler] androidAudioSessionIdStream emitted: $sessionId');
      if (sessionId != null && sessionId > 0) {
        debugPrint(
            '[AudioHandler] Got Android audio session ID: $sessionId, initializing Equalizer...');
        try {
          // Register and initialize EqualizerService if not already done
          if (!GetIt.I.isRegistered<EqualizerService>()) {
            final equalizerService = EqualizerService();
            await equalizerService.init(sessionId);
            GetIt.I.registerSingleton<EqualizerService>(equalizerService);
            debugPrint(
                '[AudioHandler] EqualizerService initialized and registered');
          }
        } catch (e) {
          debugPrint('[AudioHandler] Failed to initialize Equalizer: $e');
        }
      } else {
        debugPrint(
            '[AudioHandler] Invalid sessionId: $sessionId (null or <= 0)');
      }
    });

    // Update current song info immediately when index changes
    player.currentIndexStream.distinct().listen((index) {
      if (index != null && index < queue.value.length) {
        final item = queue.value[index];
        debugPrint(
            '[AudioHandler] Current index changed to: $index (${item.title})');
        mediaItem.add(item);

        // Setup watcher for this new track
        _setupOverrideWatcher(item.id);
      } else {
        _currentOverrideSubscription?.cancel();
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

    // ICY Metadata Listener for Radio
    player.icyMetadataStream.listen((metadata) {
      if (metadata != null && metadata.info != null) {
        debugPrint(
            '[AudioHandler] ICY Metadata: ${metadata.info?.title} - ${metadata.info?.url}');

        final current = mediaItem.value;
        if (current != null && current.extras?['isRadio'] == true) {
          final title = metadata.info?.title;
          if (title != null && title.isNotEmpty) {
            // Update the media item with the current song from radio
            final newItem = current.copyWith(
              artist:
                  title, // Often radio sends "Artist - Song" as title, or just title
              // We might want to parse "Artist - Title" if possible, but raw title is safer for now.
            );
            mediaItem.add(newItem);
          }
        }
      }
    });

    // ... rest of init

    // Initialize InnerTubeService for playback history reporting
    if (GetIt.I.isRegistered<InnerTubeService>()) {
      _innerTubeService = GetIt.I<InnerTubeService>();
    }

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

  /// Report current playing YouTube track to YouTube history
  void _reportPlaybackHistory() {
    final index = player.currentIndex;
    if (index == null) return;

    // Don't report same track twice in this session
    if (_lastReportedIndex == index) return;

    if (index >= queue.value.length) return;
    final item = queue.value[index];

    // Only report YouTube tracks
    final isOnline = item.extras?['isOnline'] == true;
    final videoId = item.extras?['videoId'] as String?;

    if (!isOnline || videoId == null) return;

    // Don't report same video twice
    if (_reportedVideoIds.contains(videoId)) return;

    debugPrint(
        '[AudioHandler] Reporting playback history for: $videoId (${item.title})');
    _lastReportedIndex = index;
    _reportedVideoIds.add(videoId);

    // Fire-and-forget reporting
    _innerTubeService?.getPlaybackTrackingUrl(videoId).then((trackingUrl) {
      if (trackingUrl != null) {
        _innerTubeService?.reportPlayback(trackingUrl);
      }
    });
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
    debugPrint('[AudioHandler] updateQueue called with ${queue.length} items');

    if (const ListEquality().equals(this.queue.value, queue)) {
      debugPrint('[AudioHandler] updateQueue: identical, skipping');
      return;
    }

    this.queue.add(queue);

    // Reuse the existing _playlist instance to ensure future queue modifications (like playNext)
    // affect the active player source.
    try {
      await _playlist.clear();
      final sources = await Future.wait(
          queue.map((item) => _audioSourceFactory.createSource(item)));
      await _playlist.addAll(sources);
      debugPrint('[AudioHandler] updateQueue: _playlist updated');
    } catch (e) {
      debugPrint('[AudioHandler] updateQueue error: $e');
    }
  }

  Future<LocalTrackOverride?> _getOverride(String path) async {
    try {
      if (GetIt.I.isRegistered<MetadataMatchingService>()) {
        return await GetIt.I<MetadataMatchingService>().getTrackOverride(path);
      }
    } catch (e) {
      // Service might not be ready
    }
    return null;
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    await super.addQueueItem(mediaItem);
    try {
      final source = await _audioSourceFactory.createSource(mediaItem);
      await _playlist.add(source);
      debugPrint(
          '[AudioHandler] addQueueItem: Added ${mediaItem.title} to _playlist');
    } catch (e) {
      debugPrint('[AudioHandler] addQueueItem error: $e');
    }
  }

  Future<void> addToQueue(Track track) async {
    final override = await _getOverride(track.path);
    final item = MediaItemAdapter.fromTrack(track, override);

    // Use the overridden addQueueItem to ensure both queue and playlist are updated
    await addQueueItem(item);

    debugPrint(
        '[AudioHandler] Added to queue: ${track.title} (Override: ${override != null})');
  }

  Future<void> playNext(Track track) async {
    final override = await _getOverride(track.path);
    final item = MediaItemAdapter.fromTrack(track, override);
    final index = player.currentIndex ?? 0;

    // Insert after current item
    await insertQueueItem(index + 1, item);

    // Manually update the playlist source since insertQueueItem default implementation
    // only updates the queue stream.
    try {
      final source = await _audioSourceFactory.createSource(item);
      await _playlist.insert(index + 1, source);
      debugPrint(
          '[AudioHandler] Playing next: ${track.title} (Override: ${override != null})');
    } catch (e) {
      debugPrint('[AudioHandler] playNext error: $e');
    }
  }

  Future<void> playLocalTrack(Track track) async {
    final override = await _getOverride(track.path);
    final mediaItem = MediaItemAdapter.fromTrack(track, override);

    debugPrint(
        '[AudioHandler] playLocalTrack: ${mediaItem.title} (Override: ${override != null})');

    // Clear and set new queue to bypass "identical" check
    queue.add([mediaItem]);

    try {
      // CLEAR and REFILL the existing _playlist instead of setting a new source.
      // This keeps _playlist connected to the player.
      await _playlist.clear();
      final source = await _audioSourceFactory.createSource(mediaItem);
      await _playlist.add(source);

      // Seek to beginning and play
      await player.seek(Duration.zero, index: 0);
      await player.play();
      debugPrint(
          '[AudioHandler] playLocalTrack: Started playing ${track.title}');
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

    // Record history (non-blocking)
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

    // Clear and set new queue to bypass "identical" check
    queue.add([mediaItem]);

    try {
      // Mutate existing _playlist
      await _playlist.clear();
      final source = await _audioSourceFactory.createSource(mediaItem);
      await _playlist.add(source);

      // Explicitly seek to the beginning of the new track.
      // This prepares the player without strictly blocking on the full load like player.load() might.
      debugPrint('[AudioHandler] playYouTubeSong: Seeking to 0...');
      await player.seek(Duration.zero, index: 0);

      // Load radio queue in background (non-blocking) - Start this BEFORE awaiting play()
      // because just_audio's play() future completes when playback FINISHES.
      if (loadRadioQueue && song.videoId.length == 11) {
        _loadRadioQueue(song.videoId);
      }

      debugPrint('[AudioHandler] playYouTubeSong: Calling play()...');
      await player.play();
      debugPrint(
          '[AudioHandler] playYouTubeSong: Started playing ${song.title}');
    } catch (e) {
      debugPrint('[AudioHandler] playYouTubeSong error: $e');
    }
  }

  Future<void> playRadioStation(RadioStation station) async {
    debugPrint('[AudioHandler] playing radio station: ${station.name}');

    // Create MediaItem for the radio station
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

    // Clear and set new queue
    queue.add([mediaItem]);

    try {
      await _playlist.clear();
      // For radio, we might not need AudioSourceFactory if we handle it directly,
      // but let's see if AudioSourceFactory can handle HTTP URLs.
      // Yes, it has a check for 'http'.

      final source = await _audioSourceFactory.createSource(mediaItem);
      await _playlist.add(source);

      debugPrint('[AudioHandler] playRadioStation: Seeking to 0...');
      await player.seek(Duration.zero, index: 0);

      debugPrint('[AudioHandler] playRadioStation: Calling play()...');
      await player.play();
    } catch (e) {
      _logError('[AudioHandler] playRadioStation error', e);
    }
  }

  /// Load radio/recommended tracks for auto-play after current song
  Future<void> _loadRadioQueue(String videoId) async {
    try {
      debugPrint('[AudioHandler] Loading radio queue for $videoId...');
      final innerTube = GetIt.I<InnerTubeService>();
      final radioTracks = await innerTube.getRadioTracks(videoId);

      if (radioTracks.isEmpty) {
        debugPrint('[AudioHandler] No radio tracks found');
        return;
      }

      // Add radio tracks to queue (up to 25), filtering out any duplicates
      // that might already be in the queue (e.g. the seed track if API returned it).
      final currentIds = queue.value.map((m) => m.id).toSet();
      final tracksToAdd = radioTracks
          .where((t) => !currentIds.contains(t.videoId))
          .take(25)
          .toList();

      debugPrint(
          '[AudioHandler] Adding ${tracksToAdd.length} radio tracks to queue');

      for (final track in tracksToAdd) {
        final mi = MediaItemAdapter.fromYouTubeSong(track);
        await addQueueItem(mi);
      }

      debugPrint('[AudioHandler] Radio queue loaded successfully');
    } catch (e) {
      debugPrint('[AudioHandler] Error loading radio queue: $e');
    }
  }

  void _setupOverrideWatcher(String trackPath) {
    _currentOverrideSubscription?.cancel();

    final currentItem = mediaItem.value;
    // CRITICAL FIX: Do not look up overrides for online tracks (YouTube).
    // They already have correct metadata and shouldn't valid against local DB.
    if (currentItem?.extras?['isOnline'] == true) {
      debugPrint('[AudioHandler] Skipping override watcher for online track');
      return;
    }

    // Only watch if we have the service and it's a local path
    if (GetIt.I.isRegistered<MetadataMatchingService>()) {
      _currentOverrideSubscription = GetIt.I<MetadataMatchingService>()
          .watchTrackOverride(trackPath)
          .listen((override) {
        if (override == null) return;

        final currentItem = mediaItem.value;
        if (currentItem?.id == trackPath) {
          debugPrint(
              '[AudioHandler] Live override update for ${currentItem?.title}. Override: ${override.correctArtist} / ${override.thumbnailUrl}');

          // Defensive check: Don't downgrade metadata to "Unknown"
          String? newArtist = override.correctArtist;
          if ((newArtist == 'Unknown' ||
                  newArtist == null ||
                  newArtist.isEmpty) &&
              currentItem?.artist != null &&
              currentItem!.artist != 'Unknown') {
            debugPrint(
                '[AudioHandler] Ignoring override artist "$newArtist" because current is "${currentItem.artist}"');
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

          // Also update in queue
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

    // Load overrides for all tracks in parallel
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
