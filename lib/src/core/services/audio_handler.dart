import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:collection/collection.dart';
import 'package:audio_session/audio_session.dart';
import '../../data/datasources/app_database.dart';
import 'settings_service.dart';
import 'equalizer_service.dart';
import 'widget_service.dart';
import 'tag_editor_service.dart';
import 'log_service.dart';

import '../../domain/entities/youtube_song.dart';
import '../utils/media_item_adapter.dart';
import 'audio_source_factory.dart';
import 'youtube_audio_source.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/services/metadata_matching_service.dart';
import '../../core/services/innertube/innertube.dart';
import 'prefetch_manager.dart';
import 'audio/audio.dart';

/// Головний аудіо-хендлер, що поєднує just_audio з audio_service.
///
/// ## Архітектура
///
/// `MyAudioHandler` є центральним сервісом для управління відтворенням аудіо.
/// Він реалізує шаблон [BaseAudioHandler] з audio_service та інтегрує:
///
/// - **just_audio** — низькорівневе відтворення аудіо
/// - **audio_service** — системні медіа-контролі (notification, lock screen)
/// - **audio_session** — управління аудіо-сесією Android/iOS
///
/// ## Залежності (DI)
///
/// Всі залежності інжектуються через конструктор для тестування:
///
/// | Сервіс | Призначення |
/// |--------|-------------|
/// | [AppDatabase] | Збереження історії відтворення |
/// | [SettingsService] | Налаштування користувача |
/// | [AudioSourceFactory] | Створення аудіо-джерел |
/// | [RecommendationService] | Рекомендації треків |
/// | [InnerTubeService] | YouTube API |
/// | [MetadataMatchingService]? | Пошук метаданих (опційно) |
/// | [PrefetchManager]? | Попередня буферизація (опційно) |
/// | [WidgetService]? | Віджет головного екрану (опційно) |
/// | [TagEditorService]? | Редагування тегів (опційно) |
///
/// ## Підсистеми
///
/// Аудіо-хендлер розділений на три виділені підсистеми:
///
/// - [PlaybackHistoryReporter] — звітування історії в YouTube
/// - [RadioQueueLoader] — завантаження радіо-черги
/// - [PlaybackStatePersistence] — збереження/відновлення стану
///
/// ## Приклад використання
///
/// ```dart
/// final handler = await AudioService.init(
///   builder: () => MyAudioHandler(
///     db: getIt<AppDatabase>(),
///     settingsService: getIt<SettingsService>(),
///     audioSourceFactory: getIt<AudioSourceFactory>(),
///     // ...
///   ),
/// );
///
/// await handler.addQueueItems([mediaItem1, mediaItem2]);
/// await handler.play();
/// ```
///
/// ## Потоки даних
///
/// - [playbackState] — стан відтворення (playing, paused, etc.)
/// - [mediaItem] — поточний трек
/// - [queue] — черга треків
/// - [player.positionStream] — позиція в треку
///
/// @see [BaseAudioHandler] для базових методів
/// @see [audio/audio.dart] для підсистем
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _equalizer = AndroidEqualizer();
  late final AudioPlayer player;

  // Note: We use the player's session ID if needed, but internal equalizer logic handles itself.
  int? get audioSessionId => player.androidAudioSessionId;

  final AppDatabase _db;
  final SettingsService _settingsService;
  final AudioSourceFactory _audioSourceFactory;
  final RecommendationService _recommendationService;
  final InnerTubeService _innerTubeService;
  final MetadataMatchingService? _metadataMatchingService;
  final PrefetchManager? _prefetchManager;
  final WidgetService? _widgetService;
  final TagEditorService? _tagEditorService;

  StreamSubscription<int?>? _audioSessionIdSubscription;
  StreamSubscription<TrackOverride?>? _currentOverrideSubscription;
  bool _isInitialized = false;

  // Extracted subsystem services
  late final PlaybackHistoryReporter _historyReporter;
  late final RadioQueueLoader _radioLoader;
  late final PlaybackStatePersistence _statePersistence;

  MyAudioHandler({
    required AppDatabase db,
    required SettingsService settingsService,
    required AudioSourceFactory audioSourceFactory,
    required RecommendationService recommendationService,
    required InnerTubeService innerTubeService,
    MetadataMatchingService? metadataMatchingService,
    PrefetchManager? prefetchManager,
    WidgetService? widgetService,
    TagEditorService? tagEditorService,
    AudioPlayer? audioPlayer, // DI for testing
  })  : _db = db,
        _settingsService = settingsService,
        _audioSourceFactory = audioSourceFactory,
        _recommendationService = recommendationService,
        _innerTubeService = innerTubeService,
        _metadataMatchingService = metadataMatchingService,
        _prefetchManager = prefetchManager,
        _widgetService = widgetService,
        _tagEditorService = tagEditorService {
    player = audioPlayer ??
        AudioPlayer(
          audioPipeline: AudioPipeline(
            androidAudioEffects: [
              _equalizer,
            ],
          ),
        );

    // Initialize extracted subsystems
    _historyReporter = PlaybackHistoryReporter(
      innerTubeService: _innerTubeService,
    );

    _radioLoader = RadioQueueLoader(
      innerTubeService: _innerTubeService,
      addToQueue: addQueueItems,
    );

    _statePersistence = PlaybackStatePersistence(
      db: _db,
      settingsService: _settingsService,
      audioSourceFactory: _audioSourceFactory,
      metadataMatchingService: _metadataMatchingService,
    );

    _init();
  }

  /// Ініціалізує аудіо-хендлер.
  ///
  /// Цей метод викликається автоматично після створення і:
  /// 1. Налаштовує аудіо-сесію для музичного режиму
  /// 2. Підписується на зміни черги для prefetch
  /// 3. Ініціалізує віджет головного екрану
  /// 4. Налаштовує обробку помилок відтворення
  /// 5. Відновлює попередній стан, якщо увімкнено
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

    // Subscribe to Queue changes for PrefetchManager
    queue.listen((newQueue) {
      _prefetchManager?.updateQueue(newQueue);
    });

    // Initialize WidgetService
    _widgetService?.init();

    // Listen to media item changes to update widget
    mediaItem.listen((item) {
      _widgetService?.updateWidget(item);
    });

    // Listen to playback state to update widget icon
    playbackState.listen((state) {
      _widgetService?.updatePlaybackState(state.playing);
    });

    // Broadcast playback state changes
    player.playbackEventStream.listen((event) {
      _broadcastState(event);
    }, onError: (Object e, StackTrace st) {
      debugPrint('[AudioHandler] PLAYER ERROR: $e. Skipping to the next item.');

      // Log to analytics
      if (GetIt.I.isRegistered<LogService>()) {
        GetIt.I<LogService>().errorWithCategory(
          ErrorCategory.playback,
          'Player error: $e',
          error: e,
          stackTrace: st,
        );
      }

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

        // Notify PrefetchManager
        _prefetchManager?.updateIndex(index);

        // Track song play in analytics
        _recordSongPlayAnalytics(item);
      } else {
        // This can happen during queue transitions, only log if queue is not empty
        if (queue.value.isNotEmpty) {
          debugPrint(
              '[AudioHandler] ! Current index is null or out of bounds: $index (Queue len: ${queue.value.length})');
        }
        _currentOverrideSubscription?.cancel();
      }

      // Auto-load more radio tracks if approaching end of queue
      if (index != null && player.loopMode == LoopMode.off) {
        final effectiveIndices = player.effectiveIndices;
        if (effectiveIndices.isNotEmpty) {
          final currentPos = effectiveIndices.indexOf(index);
          if (currentPos != -1 && currentPos >= effectiveIndices.length - 3) {
            _checkAndLoadMoreRadio();
          }
        } else {
          // Fallback if effectiveIndices is unavailable
          if (index >= queue.value.length - 3) {
            _checkAndLoadMoreRadio();
          }
        }
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

    // Save state persistence - removed, handled by _statePersistence.setupListeners()

    // YouTube playback history tracking - report after 30 seconds
    player.positionStream
        .where((pos) => pos.inSeconds >= 30)
        .distinct()
        .listen((position) => _reportPlaybackHistory());

    // State persistence listeners
    _statePersistence.setupListeners(
      mediaItemStream: mediaItem,
      queueStream: queue,
      positionStream: player.positionStream,
    );

    // Player is initialized without any audio source
    // Sources will be added via setAudioSources/addAudioSource methods

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
    if (index == null || index >= queue.value.length) return;

    final item = queue.value[index];
    final videoId = item.extras?['videoId'] as String?;
    if (videoId == null) return;

    _historyReporter.reportPlayback(
      currentIndex: index,
      videoId: videoId,
      title: item.title,
      isCached: !(item.extras?['isOnline'] ?? false),
    );
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

  // ============================================================
  // БАЗОВІ МЕТОДИ УПРАВЛІННЯ ВІДТВОРЕННЯМ
  // ============================================================

  /// Починає або продовжує відтворення.
  @override
  Future<void> play() => player.play();

  /// Призупиняє відтворення.
  @override
  Future<void> pause() => player.pause();

  /// Переміщує позицію відтворення до вказаної [position].
  @override
  Future<void> seek(Duration position) => player.seek(position);

  /// Повністю зупиняє відтворення та звільняє ресурси.
  ///
  /// Також зберігає поточний стан для відновлення пізніше,
  /// якщо це увімкнено в налаштуваннях.
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

  /// Викликається коли додаток видаляється з recent apps.
  /// Повністю звільняє всі ресурси плеєра.
  @override
  Future<void> onTaskRemoved() async {
    debugPrint('[AudioHandler] onTaskRemoved - cleaning up resources');
    _audioSessionIdSubscription?.cancel();
    _currentOverrideSubscription?.cancel();
    _historyReporter.reset();

    // Properly dispose the player to release MediaCodec resources
    await player.dispose();
    await super.onTaskRemoved();
  }

  /// Переходить до наступного треку в черзі.
  @override
  Future<void> skipToNext() => player.seekToNext();

  /// Переходить до попереднього треку в черзі.
  @override
  Future<void> skipToPrevious() => player.seekToPrevious();

  /// Переходить до треку за вказаним індексом [index] в черзі.
  ///
  /// Використовується при натисканні на трек у списку.
  /// Не блокує UI для кращої реакції на емуляторах.
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;

    // NON-BLOCKING: Don't await these to avoid UI hang on emulators
    player.seek(Duration.zero, index: index);
    player.play();
  }

  // ============================================================
  // РЕЖИМИ ВІДТВОРЕННЯ
  // ============================================================

  /// Встановлює режим повтору.
  ///
  /// - [AudioServiceRepeatMode.none] — без повтору
  /// - [AudioServiceRepeatMode.one] — повтор одного треку
  /// - [AudioServiceRepeatMode.all] — повтор усієї черги
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

  /// Встановлює режим перемішування.
  ///
  /// При увімкненні спочатку перемішує чергу, потім активує режим.
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    if (enabled) {
      await player.shuffle();
    }
    await player.setShuffleModeEnabled(enabled);
  }

  // ============================================================
  // УПРАВЛІННЯ ЧЕРГОЮ
  // ============================================================

  /// Оновлює чергу відтворення.
  ///
  /// Важливо: оновлення [queue] відбувається ПЕРЕД модифікацією плейлиста,
  /// щоб уникнути race condition при автоматичному переході на індекс 0.
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

      // 3. Update Playlist using new API (just_audio 0.10.x)
      await player.setAudioSources(sources, preload: false);

      debugPrint(
          '[AudioHandler] updateQueue: queue and player sources updated');
    } catch (e) {
      debugPrint('[AudioHandler] updateQueue error: $e');
      // Rollback queue on failure
      this.queue.add([]);
    }
  }

  /// Атомарно встановлює чергу та починає відтворення з вказаного індексу.
  ///
  /// Цей метод запобігає race condition в ExoPlayer, коли індекс
  /// скидається до 0 при модифікації плейлиста.
  ///
  /// [newQueue] — нова черга треків
  /// [startIndex] — індекс треку для початку відтворення
  Future<void> playQueueFromIndex(
      List<MediaItem> newQueue, int startIndex) async {
    debugPrint(
        '[AudioHandler] playQueueFromIndex: ${newQueue.length} items, startIndex=$startIndex');

    if (newQueue.isEmpty) return;
    final safeIndex = startIndex.clamp(0, newQueue.length - 1);

    // Reset radio loader debounce for new playback session
    _radioLoader.reset();

    try {
      // 1. Update UI queue first
      queue.add(newQueue);

      // 2. Create audio sources
      final sources = await Future.wait(
          newQueue.map((item) => _audioSourceFactory.createSource(item)));

      // 3. Prefetch initial track URL to prevent "Loading interrupted" error
      if (sources.isNotEmpty &&
          safeIndex < sources.length &&
          sources[safeIndex] is YoutubeAudioSource) {
        final ytSource = sources[safeIndex] as YoutubeAudioSource;
        debugPrint(
            '[AudioHandler] Prefetching initial track at index $safeIndex');
        await ytSource.prefetch();
      }

      // 4. Set audio sources with initial index using new API (just_audio 0.10.x)
      await player.setAudioSources(sources, initialIndex: safeIndex);

      // 5. Start playback
      await player.play();

      debugPrint(
          '[AudioHandler] playQueueFromIndex: started at index $safeIndex');
    } catch (e) {
      debugPrint('[AudioHandler] playQueueFromIndex error: $e');

      // Log error for analytics
      if (GetIt.I.isRegistered<LogService>()) {
        GetIt.I<LogService>().errorWithCategory(
          ErrorCategory.playback,
          'playQueueFromIndex error at index $safeIndex: $e',
          error: e,
        );
      }

      // Try to recover by skipping to next track if available
      if (newQueue.length > 1 && safeIndex < newQueue.length - 1) {
        debugPrint(
            '[AudioHandler] playQueueFromIndex: Attempting recovery, skipping to next track');
        try {
          await player.seek(Duration.zero, index: safeIndex + 1);
          await player.play();
          debugPrint(
              '[AudioHandler] playQueueFromIndex: Recovery successful, now playing index ${safeIndex + 1}');
        } catch (recoveryError) {
          debugPrint(
              '[AudioHandler] playQueueFromIndex: Recovery failed: $recoveryError');
        }
      }
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

      // 2. Add to Playlist using new API (just_audio 0.10.x)
      await player.addAudioSource(source);

      // 3. Update Queue
      await super.addQueueItem(mediaItem);

      debugPrint(
          '[AudioHandler] addQueueItem: Added ${mediaItem.title} to player and queue');
    } catch (e) {
      debugPrint('[AudioHandler] addQueueItem error: $e');
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    debugPrint(
        '[AudioHandler] addQueueItems: Adding ${mediaItems.length} items');
    try {
      // 1. Create sources in parallel
      final sources = await Future.wait(
          mediaItems.map((item) => _audioSourceFactory.createSource(item)));

      // 2. Batch add to Player using new API (just_audio 0.10.x)
      for (final source in sources) {
        await player.addAudioSource(source);
      }

      // 3. Update Queue (Batch)
      final newQueue = queue.value + mediaItems;
      queue.add(newQueue);

      debugPrint('[AudioHandler] addQueueItems: Batch add complete');
    } catch (e) {
      debugPrint('[AudioHandler] addQueueItems error: $e');
    }
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    debugPrint('[AudioHandler] insertQueueItem at $index: ${mediaItem.title}');
    try {
      // 1. Create source
      final source = await _audioSourceFactory.createSource(mediaItem);

      // 2. Insert into Player using new API (just_audio 0.10.x)
      await player.insertAudioSource(index, source);

      // 3. Update Queue
      await super.insertQueueItem(index, mediaItem);
    } catch (e) {
      debugPrint('[AudioHandler] insertQueueItem error: $e');
    }
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final index = queue.value.indexWhere((i) => i.id == mediaItem.id);
    debugPrint('[AudioHandler] removeQueueItem at $index: ${mediaItem.title}');
    await super.removeQueueItem(mediaItem);

    if (index != -1) {
      try {
        // Use new API (just_audio 0.10.x)
        await player.removeAudioSourceAt(index);
      } catch (e) {
        debugPrint('[AudioHandler] removeQueueItem error: $e');
      }
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    debugPrint('[AudioHandler] removeQueueItemAt index: $index');

    if (index < 0 || index >= queue.value.length) {
      debugPrint('[AudioHandler] removeQueueItemAt: invalid index $index');
      return;
    }

    // 1. Update UI Queue
    final newQueue = List<MediaItem>.from(queue.value);
    newQueue.removeAt(index);
    queue.add(newQueue);

    // 2. Update Player using new API (just_audio 0.10.x)
    try {
      await player.removeAudioSourceAt(index);
    } catch (e) {
      debugPrint('[AudioHandler] removeQueueItemAt error: $e');
      // If player fails, we might technically be out of sync.
      // But since queue is source of truth for UI, we accept this risk regarding phantom tracks.
    }
  }

  /// Efficiently move a queue item from oldIndex to newIndex.
  /// Uses player.moveAudioSource() for O(1) playlist reordering (just_audio 0.10.x)
  /// instead of rebuilding the entire queue.
  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    final currentQueue = queue.value;

    // Validate indices
    if (oldIndex < 0 || oldIndex >= currentQueue.length) {
      debugPrint('[AudioHandler] moveQueueItem: invalid oldIndex $oldIndex');
      return;
    }
    if (newIndex < 0 || newIndex > currentQueue.length) {
      debugPrint('[AudioHandler] moveQueueItem: invalid newIndex $newIndex');
      return;
    }
    if (oldIndex == newIndex) return;

    debugPrint('[AudioHandler] moveQueueItem: $oldIndex -> $newIndex');

    try {
      // 1. Calculate actual insert position (Flutter ReorderableListView convention)
      int insertIndex = newIndex;
      if (newIndex > oldIndex) {
        insertIndex -= 1;
      }

      // 2. Update UI queue first (in-place modification)
      final newQueue = List<MediaItem>.from(currentQueue);
      final item = newQueue.removeAt(oldIndex);
      newQueue.insert(insertIndex, item);
      queue.add(newQueue);

      // 3. Move in player using new API (just_audio 0.10.x) - O(1) operation!
      await player.moveAudioSource(oldIndex, insertIndex);

      debugPrint('[AudioHandler] moveQueueItem: completed successfully');
    } catch (e) {
      debugPrint('[AudioHandler] moveQueueItem error: $e');
      // Revert UI if player move fails
      queue.add(currentQueue);
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

    // Force tag update with permission request (User initiated action)
    // Await to ensure file is closed before player opens it
    await updateFileTags(mediaItem, requestPermission: true);

    try {
      final source = await _audioSourceFactory.createSource(mediaItem);

      // Set single audio source using new API (just_audio 0.10.x)
      await player.setAudioSources([source]);

      // Seek to beginning and play
      await player.seek(Duration.zero, index: 0);
      player.play();
    } catch (e) {
      debugPrint('[AudioHandler] playLocalTrack error: $e');
    }
  }

  /// Attempts to write the metadata from [item] into the file at [item.id] (path).
  /// This repairs missing or incorrect tags in the file itself.
  Future<void> updateFileTags(MediaItem item,
      {bool requestPermission = false}) async {
    // Only for local files
    if (item.extras?['isOnline'] == true) return;

    final path = item.id;
    if (_tagEditorService == null) {
      debugPrint('[AudioHandler] TagEditorService not initialized');
      return;
    }

    debugPrint('[AudioHandler] repairFileMetadata for $path');
    final success = await _tagEditorService!.writeTags(
      path: path,
      title: item.title,
      artist: item.artist ?? 'Unknown Artist',
      album: item.album ?? 'Unknown Album',
      requestPermission: requestPermission,
      // artworkPath: ... we don't have a local artwork path easily unless we extracted it or user picked it.
      // For DB tracks, artwork might be a MediaStore URI content://... which audiotagger might not handle for WRITING.
      // So we skip artwork writing for this auto-fix.
    );

    if (success) {
      debugPrint('[AudioHandler] Metadata repair successful for $path');
    } else {
      debugPrint('[AudioHandler] Metadata repair failed for $path');
    }
  }

  Future<void> addYouTubeToQueue(YouTubeSong song) async {
    final mediaItem = MediaItemAdapter.fromYouTubeSong(song);
    debugPrint('[AudioHandler] addYouTubeToQueue: ${song.title}');
    await addQueueItem(mediaItem);
  }

  Future<void> playYouTubeSong(YouTubeSong song) async {
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

    // Use unified playback start
    // Radio queue will be loaded automatically by currentIndexStream listener
    // when we approach end of queue (handled in _checkAndLoadMoreRadio)
    await playQueueFromIndex([mediaItem], 0);
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

    // Use unified playback start
    await playQueueFromIndex([mediaItem], 0);
  }

  Future<void> _checkAndLoadMoreRadio() async {
    final index = player.currentIndex;
    await _radioLoader.checkAndLoadMore(
      currentQueue: queue.value,
      currentIndex: index ?? 0,
      loopEnabled: player.loopMode != LoopMode.off,
    );
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
    final restored = await _statePersistence.restoreState();
    if (restored == null) return;

    queue.add(restored.mediaItems);

    try {
      if (restored.sources != null && restored.sources!.isNotEmpty) {
        // Use new API (just_audio 0.10.x)
        await player.setAudioSources(restored.sources!, preload: false);
      } else if (restored.mediaItems.isNotEmpty) {
        // Fallback: create sources if not pre-created
        final sources = await Future.wait(restored.mediaItems
            .map((item) => _audioSourceFactory.createSource(item)));
        // Use new API (just_audio 0.10.x)
        await player.setAudioSources(sources, preload: false);
      }
    } catch (e) {
      debugPrint('[AudioHandler] Error loading initial playlist: $e');
    }

    if (restored.initialIndex != null) {
      await player.seek(
        restored.initialPosition ?? Duration.zero,
        index: restored.initialIndex,
      );
    }
  }

  /// Record song play in analytics
  void _recordSongPlayAnalytics(MediaItem item) {
    try {
      if (!GetIt.I.isRegistered<LogService>()) return;

      final logService = GetIt.I<LogService>();
      final extras = item.extras ?? {};
      final isOnline = extras['isOnline'] == true;
      final isCached = !isOnline && item.id.contains('/');

      logService.recordSongPlayed(fromCache: isCached);
    } catch (e) {
      // Ignore analytics errors
    }
  }
}
