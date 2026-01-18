import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/liked_song.dart';
import '../services/recommendation_service.dart';
import '../services/innertube_service.dart';

class FavoritesService {
  final RecommendationService _recommendationService;
  late final Isar _isar;
  InnerTubeService? _innerTubeService;

  FavoritesService(this._recommendationService);

  Future<void> init() async {
    // Isar is already initialized in RecommendationService, reusing it or its instance if shared.
    // However, LikedSongSchema needs to be loaded.
    // IF RecommendationService opened Isar with ONLY ListenHistorySchema, we have a problem.
    // We should probably move Isar opening to a central DatabaseService or update RecommendationService to include LikedSong.
    // For now, assuming we will update RecommendationService to include LikedSongSchema in the open() call.

    if (_recommendationService.isar != null) {
      _isar = _recommendationService.isar!;
    }

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
    final existing =
        await _isar.likedSongs.filter().videoIdMatches(videoId).findFirst();

    final isAdding = existing == null;

    // Update local Isar DB
    await _isar.writeTxn(() async {
      if (existing != null) {
        await _isar.likedSongs.delete(existing.id);
      } else {
        final newEntry = LikedSong()
          ..videoId = videoId
          ..title = title
          ..artist = artist
          ..thumbnailUrl = thumbnailUrl
          ..addedAt = DateTime.now();
        await _isar.likedSongs.put(newEntry);
      }
    });

    // Sync with YouTube Music account (fire-and-forget, don't block UI)
    // Only sync if it's an actual video ID (not a playlist/album/channel ID)
    final isValidVideoId = _isValidYouTubeVideoId(videoId);
    if (_innerTubeService != null &&
        !videoId.startsWith('local:') &&
        isValidVideoId) {
      final rating = isAdding ? 'LIKE' : 'INDIFFERENT';
      debugPrint(
          '[FavoritesService] Syncing with YouTube: videoId=$videoId, rating=$rating');
      _innerTubeService!.rateSong(videoId, rating).then((success) {
        debugPrint(
            '[FavoritesService] YouTube sync ${success ? 'succeeded' : 'failed'} for $videoId');
      });
    } else if (!isValidVideoId) {
      debugPrint(
          '[FavoritesService] Skipping YouTube sync for non-video ID: $videoId');
    }
  }

  /// Check if the ID looks like a valid YouTube video ID (11 chars, alphanumeric + _ -)
  /// and NOT a playlist/album/channel ID (MPRE, VL, PL, UC, RD prefixes)
  bool _isValidYouTubeVideoId(String id) {
    // Known non-video ID prefixes
    if (id.startsWith('MPRE') ||
        id.startsWith('VL') ||
        id.startsWith('PL') ||
        id.startsWith('UC') ||
        id.startsWith('RD') ||
        id.startsWith('OLAK') ||
        id.startsWith('local:')) {
      return false;
    }
    // YouTube video IDs are typically 11 characters
    if (id.length != 11) return false;
    // Allow alphanumeric, underscore, hyphen
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id);
  }

  Future<bool> isLiked(String videoId) async {
    return await _isar.likedSongs.filter().videoIdMatches(videoId).isNotEmpty();
  }

  Stream<bool> isLikedStream(String videoId) {
    return _isar.likedSongs
        .filter()
        .videoIdMatches(videoId)
        .watch(fireImmediately: true)
        .map((items) {
      final result = items.isNotEmpty;
      return result;
    });
  }

  Future<List<LikedSong>> getLikedSongs() async {
    final songs = await _isar.likedSongs.where().sortByAddedAtDesc().findAll();
    return songs;
  }
}
