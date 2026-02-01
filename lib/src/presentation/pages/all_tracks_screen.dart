import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import '../../data/datasources/app_database.dart';
import '../../core/services/music_finder.dart';
import '../../core/services/audio_handler.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/localization.dart';
import '../../core/utils/media_item_adapter.dart';
import '../../core/theme/app_theme.dart';

import '../widgets/track_list_tile.dart';

/// Screen displaying all tracks with album art thumbnails.
/// Poweramp-inspired design with smooth aesthetics.
class AllTracksScreen extends StatelessWidget {
  const AllTracksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = GetIt.I<AppDatabase>();
    final musicFinder = GetIt.I<MusicFinder>();
    final audioHandler = GetIt.I<MyAudioHandler>();
    final settingsService = GetIt.I<SettingsService>();

    return Scaffold(
      key: const Key('all_tracks_screen'),
      body: StreamBuilder<void>(
        stream: settingsService.onSettingsChanged,
        builder: (context, _) {
          return StreamBuilder<List<Track>>(
            stream: db.watchFilteredTracks(
              minDurationSeconds: settingsService.loadMinTrackDuration(),
              maxDurationSeconds: settingsService.loadMaxTrackDuration(),
              excludedFolders: settingsService.loadExcludedFolders(),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final tracks = snapshot.data ?? [];

              if (tracks.isEmpty) {
                final colors = context.appColors;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_music_outlined,
                          size: 80,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppLocalizations.of(context).noTracksFound,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context).scanDesc,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: () => musicFinder.scanAllMusic(),
                          icon: const Icon(Icons.refresh),
                          label: Text(AppLocalizations.of(context).scanMusic),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Sort tracks alphabetically by title
              tracks.sort((a, b) =>
                  a.title.toLowerCase().compareTo(b.title.toLowerCase()));

              return ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final isCurrentTrack =
                      audioHandler.mediaItem.value?.id == track.path;

                  return TrackListTile(
                    track: track,
                    isCurrentTrack: isCurrentTrack,
                    onTap: () => _playQueue(audioHandler, tracks, index),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _playQueue(
    MyAudioHandler audioHandler, List<Track> tracks, int startIndex) async {
  // Optimization: Don't load 2000+ songs into the player queue at once.
  // This causes huge delays (15s+) and Android Binder Transaction errors.
  // Instead, load a "window" of tracks around the current one.

  const windowSize = 20; // Load 20 tracks before and after (total 40)
  final start = (startIndex - windowSize).clamp(0, tracks.length);
  final end = (startIndex + windowSize + 1).clamp(0, tracks.length);

  final subset = tracks.sublist(start, end);
  final relativeIndex = startIndex - start;

  // Get overrides for the subset
  final db = GetIt.I<AppDatabase>();
  final paths = subset.map((t) => t.path).toList();
  final overridesQuery = await (db.select(db.trackOverrides)
        ..where((tbl) => tbl.filePath.isIn(paths)))
      .get();

  final overridesMap = <String, TrackOverride>{
    for (var o in overridesQuery) o.filePath: o
  };

  final mediaItems = subset.map((track) {
    final override = overridesMap[track.path];
    return MediaItemAdapter.fromTrack(track, override);
  }).toList();

  await audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
  await audioHandler.playQueueFromIndex(mediaItems, relativeIndex);
}
