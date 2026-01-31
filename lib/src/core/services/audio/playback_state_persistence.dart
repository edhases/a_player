import 'package:audio_service/audio_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../../../data/datasources/app_database.dart';
import '../settings_service.dart';
import '../metadata_matching_service.dart';
import '../../utils/media_item_adapter.dart';
import '../audio_source_factory.dart';

/// Handles saving and restoring playback state across app restarts.
///
/// Responsibilities:
/// - Save current track ID and position periodically
/// - Save queue state
/// - Restore queue and position on startup
class PlaybackStatePersistence {
  final AppDatabase _db;
  final SettingsService _settingsService;
  final MetadataMatchingService? _metadataMatchingService;
  final AudioSourceFactory _audioSourceFactory;

  PlaybackStatePersistence({
    required AppDatabase db,
    required SettingsService settingsService,
    required AudioSourceFactory audioSourceFactory,
    MetadataMatchingService? metadataMatchingService,
  })  : _db = db,
        _settingsService = settingsService,
        _audioSourceFactory = audioSourceFactory,
        _metadataMatchingService = metadataMatchingService;

  /// Set up listeners for state persistence
  void setupListeners({
    required BehaviorSubject<MediaItem?> mediaItemStream,
    required BehaviorSubject<List<MediaItem>> queueStream,
    required Stream<Duration> positionStream,
  }) {
    // Save current track ID
    mediaItemStream.stream.listen((item) {
      if (item != null) _settingsService.saveLastTrackId(item.id);
    });

    // Save position periodically (debounced)
    positionStream
        .debounceTime(const Duration(seconds: 5))
        .listen((position) => _settingsService.saveLastPosition(position));

    // Save queue
    queueStream.stream.listen((q) {
      final trackIds = q.map((item) => item.id).toList();
      _settingsService.saveQueue(trackIds);
    });
  }

  /// Restore saved queue and position
  ///
  /// Returns the restored media items and initial index/position
  Future<RestoredState?> restoreState() async {
    final lastQueueIds = _settingsService.loadQueue();
    if (lastQueueIds.isEmpty) return null;

    // NOTE: Currently only restores LOCAL tracks from database.
    // YouTube tracks would require additional serialization.
    final lastTracks = await (_db.select(_db.tracks)
          ..where((t) => t.path.isIn(lastQueueIds)))
        .get();

    final sortedTracks = lastQueueIds
        .map((id) => lastTracks.firstWhereOrNull((t) => t.path == id))
        .nonNulls
        .toList();

    if (sortedTracks.isEmpty) return null;

    // Get overrides for all tracks
    final overrides = await Future.wait(
      sortedTracks.map((t) => _getOverride(t.path)),
    );

    // Convert to MediaItems
    final mediaItems = List<MediaItem>.generate(sortedTracks.length, (index) {
      return MediaItemAdapter.fromTrack(sortedTracks[index], overrides[index]);
    });

    // Find last played track and position
    final lastTrackId = _settingsService.loadLastTrackId();
    int? initialIndex;
    Duration? initialPosition;

    if (lastTrackId != null) {
      initialIndex = mediaItems.indexWhere((item) => item.id == lastTrackId);
      if (initialIndex != -1) {
        initialPosition = _settingsService.loadLastPosition();
      } else {
        initialIndex = null;
      }
    }

    // Pre-create audio sources
    List<AudioSource>? sources;
    try {
      sources = await Future.wait(
          mediaItems.map((item) => _audioSourceFactory.createSource(item)));
    } catch (e) {
      debugPrint('[PlaybackStatePersistence] Error creating sources: $e');
    }

    return RestoredState(
      mediaItems: mediaItems,
      sources: sources,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
    );
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
}

/// Restored playback state
class RestoredState {
  final List<MediaItem> mediaItems;
  final List<AudioSource>? sources;
  final int? initialIndex;
  final Duration? initialPosition;

  const RestoredState({
    required this.mediaItems,
    this.sources,
    this.initialIndex,
    this.initialPosition,
  });
}
