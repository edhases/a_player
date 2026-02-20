import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';

import '../bloc_status.dart';
import '../../../core/services/recommendation_service.dart';
import '../../../core/services/metadata_matching_service.dart';
import '../../../data/datasources/app_database.dart';
import '../../../domain/entities/home_section.dart';
import '../../../domain/entities/youtube_song.dart';
// import '../../../core/utils/localization.dart'; // Cannot use context-based localization here easily without context

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final RecommendationService _recommendationService;
  final AppDatabase _db;

  // Stream subscriptions to be cancelled on close
  StreamSubscription? _youtubeTracksSubscription;
  StreamSubscription? _favoriteTracksSubscription;

  HomeBloc({
    required RecommendationService recommendationService,
    required AppDatabase db,
  })  : _recommendationService = recommendationService,
        _db = db,
        super(const HomeState()) {
    on<HomeLoadFeed>(_onLoadFeed);
    on<HomeRefreshFeed>(_onLoadFeed);

    // Watch for changes in YouTubeTracks (likes/history)
    _youtubeTracksSubscription =
        _db.select(_db.youTubeTracks).watch().listen((_) {
      add(HomeRefreshFeed());
    });

    // Watch for changes in Local Favorites
    _favoriteTracksSubscription = _db.watchFavoriteTracks().listen((_) {
      add(HomeRefreshFeed());
    });
  }

  @override
  Future<void> close() {
    _youtubeTracksSubscription?.cancel();
    _favoriteTracksSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadFeed(HomeEvent event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      // 1. Load Remote/Mixed Recommendations
      final sections = await _recommendationService.getPersonalizedFeed();
      final mutableSections = List<HomeSection>.from(sections);

      // 2. Load Local Favorites & Online Favorites (Merged)
      try {
        // Fetch Local Favorites
        final favoriteTracks = await _db.watchFavoriteTracks().first;

        // Helper function for local conversion (inlined logic for cleaner scope)
        Future<List<YouTubeSong>> convertLocalTracks(List<Track> tracks) async {
          List<YouTubeSong> converted = [];
          final metadataService =
              GetIt.I.isRegistered<MetadataMatchingService>()
                  ? GetIt.I<MetadataMatchingService>()
                  : null;

          Map<String, TrackOverride?> overrides = {};
          if (metadataService != null) {
            final futures = tracks.map((t) async {
              final override = await metadataService.getTrackOverride(t.path);
              return MapEntry(t.path, override);
            });
            final results = await Future.wait(futures);
            overrides = Map.fromEntries(results);
          }

          for (var t in tracks) {
            String title = t.title;
            String artist = t.artist ?? 'Unknown Artist';
            String thumb = '';

            final override = overrides[t.path];
            if (override != null) {
              title = override.correctTitle ?? title;
              artist = override.correctArtist ?? artist;
              if (override.thumbnailUrl != null &&
                  override.thumbnailUrl!.isNotEmpty) {
                thumb = override.thumbnailUrl!;
              }
            }

            if (thumb.isEmpty) {
              if (t.artworkUri != null && t.artworkUri!.isNotEmpty) {
                thumb = t.artworkUri!;
              } else if (t.mediaStoreId != null) {
                thumb = 'mediastore:${t.mediaStoreId}';
              }
            }

            converted.add(YouTubeSong(
              videoId: 'local:${t.path}',
              title: title,
              artist: artist,
              thumbnailUrl: thumb,
            ));
          }
          return converted;
        }

        final favSongsLocal = await convertLocalTracks(favoriteTracks);

        // Fetch Online Favorites from DB
        final youtubeFavorites = await (_db.select(_db.youTubeTracks)
              ..where((t) => t.isFavorite.equals(true))
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.likedAt, mode: OrderingMode.desc)
              ]))
            .get();

        final favSongsOnline = youtubeFavorites
            .map((yt) => YouTubeSong(
                  videoId: yt.videoId,
                  title: yt.title,
                  artist: yt.artist,
                  thumbnailUrl: yt.thumbnailUrl,
                ))
            .toList();

        // Merge lists
        final allFavs = [...favSongsLocal, ...favSongsOnline];

        // FILTER: Remove existing "Liked Songs" / "Favorites" from remote feed to avoid duplication
        mutableSections.removeWhere((s) {
          final t = s.title.toLowerCase();
          return t.contains('liked') ||
              t.contains('favorites') ||
              t.contains('вподобані') ||
              t.contains('понравившиеся');
        });

        // Create the Unified Favorites Section
        if (allFavs.isNotEmpty) {
          mutableSections.insert(
              0,
              HomeSection(
                title: 'liked_songs', // Use key
                type: SectionType.horizontal,
                songs: allFavs,
              ));
        }

        // 3. Load Random Local Tracks (The "Your Local Music" section)
        final localTracks = await _db.getRandomTracks(limit: 20);
        if (localTracks.isNotEmpty) {
          final converted = await convertLocalTracks(localTracks);
          mutableSections.add(HomeSection(
            title: 'your_local_music', // Use key
            type: SectionType.horizontal,
            songs: converted,
          ));
        }

        // 4. Load Radio Stations
        final radioStations = await _db.getAllRadioStations();
        if (radioStations.isNotEmpty) {
          final radioSongs = radioStations
              .map((r) => YouTubeSong(
                    videoId: 'radio:${r.id}',
                    title: r.name,
                    artist: 'Radio',
                    thumbnailUrl: r.imageUrl ?? '',
                    // specialized extras dealing
                  ))
              .toList();

          mutableSections.add(HomeSection(
            title: 'radio_stations',
            type: SectionType.horizontal, // Or grid? Horizontal is consistent.
            songs: radioSongs,
          ));
        }
      } catch (e) {
        debugPrint('Error loading local/favorite tracks: $e');
      }

      emit(state.copyWith(
        status: HomeStatus.success,
        sections: mutableSections,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
