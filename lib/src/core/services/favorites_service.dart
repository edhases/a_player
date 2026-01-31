import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import '../../data/datasources/app_database.dart';
import '../../domain/entities/youtube_song.dart';
import '../services/recommendation_service.dart';
import '../services/innertube/innertube.dart';

class FavoritesService {
  final RecommendationService _recommendationService;
  final AppDatabase _db;
  final InnerTubeService? _innerTubeService;

  FavoritesService(
    this._recommendationService, {
    required AppDatabase db,
    InnerTubeService? innerTubeService,
  })  : _db = db,
        _innerTubeService = innerTubeService ?? 
            (GetIt.I.isRegistered<InnerTubeService>() 
                ? GetIt.I<InnerTubeService>() 
                : null);

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

  /// Fetches new liked songs from YouTube Music that are not yet in local database
  /// Returns list of new songs (not yet imported)
  Future<List<YouTubeSong>> fetchNewLikedFromYouTube() async {
    if (_innerTubeService == null) {
      debugPrint('[FavoritesService] Cannot sync - InnerTube not initialized');
      return [];
    }

    debugPrint('[FavoritesService] Fetching new liked songs from YouTube Music...');
    
    try {
      // Fetch liked songs from YouTube Music
      final youTubeLiked = await _innerTubeService!.getYouTubeLikedSongs();
      debugPrint('[FavoritesService] Fetched ${youTubeLiked.length} liked songs from YouTube');

      if (youTubeLiked.isEmpty) {
        debugPrint('[FavoritesService] No liked songs found on YouTube');
        return [];
      }

      // Get current local liked songs
      final localLiked = await getLikedSongs();
      final localLikedIds = localLiked.map((t) => t.videoId).toSet();

      // Filter only new songs
      final newSongs = youTubeLiked.where((song) => !localLikedIds.contains(song.videoId)).toList();
      debugPrint('[FavoritesService] Found ${newSongs.length} new songs to import');
      
      return newSongs;
    } catch (e) {
      debugPrint('[FavoritesService] Fetch error: $e');
      return [];
    }
  }

  /// Imports specific songs to local database as liked
  /// [songs] - list of songs to import
  /// Returns the number of imported songs
  Future<int> importLikedSongs(List<YouTubeSong> songs) async {
    int imported = 0;
    
    for (final song in songs) {
      try {
        await _db.into(_db.youTubeTracks).insertOnConflictUpdate(
          YouTubeTracksCompanion(
            videoId: Value(song.videoId),
            title: Value(song.title),
            artist: Value(song.artist),
            thumbnailUrl: Value(song.thumbnailUrl),
            isFavorite: const Value(true),
            likedAt: Value(DateTime.now()),
            duration: const Value(0),
            cachedAt: Value(DateTime.now()),
          ),
        );
        imported++;
        debugPrint('[FavoritesService] Imported: ${song.title} - ${song.artist}');
      } catch (e) {
        debugPrint('[FavoritesService] Failed to import ${song.title}: $e');
      }
    }
    
    debugPrint('[FavoritesService] Import complete. Imported $imported songs.');
    return imported;
  }

  /// Syncs liked songs FROM YouTube Music TO local database
  /// Returns the number of new songs imported
  Future<int> syncFromYouTube() async {
    final newSongs = await fetchNewLikedFromYouTube();
    if (newSongs.isEmpty) return 0;
    return await importLikedSongs(newSongs);
  }
}
