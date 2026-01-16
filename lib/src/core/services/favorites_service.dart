import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/liked_song.dart';
import '../services/recommendation_service.dart';

class FavoritesService {
  final RecommendationService _recommendationService;
  late final Isar _isar;

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
  }

  Future<void> toggleFavorite({
    required String videoId,
    required String title,
    required String artist,
    required String thumbnailUrl,
  }) async {
    final existing =
        await _isar.likedSongs.filter().videoIdMatches(videoId).findFirst();

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
  }

  Future<bool> isLiked(String videoId) async {
    return await _isar.likedSongs.filter().videoIdMatches(videoId).isNotEmpty();
  }

  Stream<bool> isLikedStream(String videoId) {
    return _isar.likedSongs
        .filter()
        .videoIdMatches(videoId)
        .watch(fireImmediately: true)
        .map((items) => items.isNotEmpty);
  }

  Future<List<LikedSong>> getLikedSongs() async {
    return await _isar.likedSongs.where().sortByAddedAtDesc().findAll();
  }
}
