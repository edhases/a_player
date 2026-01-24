import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import '../../data/datasources/app_database.dart';
import '../services/recommendation_service.dart';
import '../services/innertube_service.dart';

class FavoritesService {
  final RecommendationService
      _recommendationService; // Keep just in case needed logic, but not for DB
  final AppDatabase _db =
      GetIt.I<AppDatabase>(); // Direct dependency or injected
  InnerTubeService? _innerTubeService;

  FavoritesService(this._recommendationService);

  Future<void> init() async {
    // Get InnerTubeService for YouTube sync
    if (GetIt.I.isRegistered<InnerTubeService>()) {
      _innerTubeService = GetIt.I<InnerTubeService>();
    }
  }

  Future<void> toggleFavorite({
    required String videoId,
    required String title,
    required String artist,
    required String thumbnailUrl,
  }) async {
    // Check if already is favorite
    final existingParams = await (_db.select(_db.youTubeTracks)
          ..where((t) => t.videoId.equals(videoId)))
        .getSingleOrNull();

    final isFavorite = existingParams?.isFavorite ?? false;
    final newStatus = !isFavorite;

    // Update in Drift: Upsert
    await _db.into(_db.youTubeTracks).insertOnConflictUpdate(
          YouTubeTracksCompanion(
            videoId: Value(videoId),
            title: Value(title),
            artist: Value(artist),
            thumbnailUrl: Value(thumbnailUrl),
            isFavorite: Value(newStatus),
            likedAt: Value(newStatus ? DateTime.now() : null),
            duration: const Value(0), // Default if new
            cachedAt: Value(DateTime.now()), // Refreshed metadata
          ),
        );

    // Sync with YouTube Music account
    final isValidVideoId = _isValidYouTubeVideoId(videoId);
    if (_innerTubeService != null &&
        !videoId.startsWith('local:') &&
        isValidVideoId) {
      final rating = newStatus ? 'LIKE' : 'INDIFFERENT';
      debugPrint(
          '[FavoritesService] Syncing with YouTube: videoId=$videoId, rating=$rating');
      _innerTubeService!.rateSong(videoId, rating).then((success) {
        debugPrint(
            '[FavoritesService] YouTube sync ${success ? 'succeeded' : 'failed'} for $videoId');
      });
    }
  }

  Future<void> dislikeTrack(String videoId) async {
    final isValidVideoId = _isValidYouTubeVideoId(videoId);
    if (_innerTubeService != null &&
        !videoId.startsWith('local:') &&
        isValidVideoId) {
      debugPrint('[FavoritesService] Sending DISLIKE to YouTube for: $videoId');
      _innerTubeService!.rateSong(videoId, 'DISLIKE').then((success) {
        debugPrint(
            '[FavoritesService] YouTube DISLIKE ${success ? 'succeeded' : 'failed'} for $videoId');
      });

      final isLiked = await this.isLiked(videoId);
      if (isLiked) {
        await _db.into(_db.youTubeTracks).insertOnConflictUpdate(
              YouTubeTracksCompanion(
                videoId: Value(videoId),
                isFavorite: const Value(false),
                likedAt: const Value(null),
              ),
            );
      }
    }
  }

  bool _isValidYouTubeVideoId(String id) {
    if (id.startsWith('MPRE') ||
        id.startsWith('VL') ||
        id.startsWith('PL') ||
        id.startsWith('UC') ||
        id.startsWith('RD') ||
        id.startsWith('OLAK') ||
        id.startsWith('local:')) {
      return false;
    }
    if (id.length != 11) return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id);
  }

  Future<bool> isLiked(String videoId) async {
    final track = await (_db.select(_db.youTubeTracks)
          ..where((t) => t.videoId.equals(videoId)))
        .getSingleOrNull();
    return track?.isFavorite ?? false;
  }

  Stream<bool> isLikedStream(String videoId) {
    return (_db.select(_db.youTubeTracks)
          ..where((t) => t.videoId.equals(videoId)))
        .watchSingleOrNull()
        .map((t) => t?.isFavorite ?? false);
  }

  Future<List<YouTubeTrack>> getLikedSongs() async {
    return await (_db.select(_db.youTubeTracks)
          ..where((t) => t.isFavorite.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.likedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }
}
