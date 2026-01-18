import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../widgets/compact_quick_pick_tile.dart';
import '../widgets/paged_song_list.dart';
import '../widgets/youtube_song_menu.dart';

import '../../domain/entities/home_section.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/services/smart_play_service.dart';
import '../../domain/entities/youtube_song.dart';
import '../../core/utils/localization.dart';
import '../../data/datasources/app_database.dart';
import '../../core/services/audio_handler.dart';
import '../../core/services/metadata_matching_service.dart';
import '../../data/models/local_track_override.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final RecommendationService _recommendationService =
      GetIt.I<RecommendationService>();
  final SmartPlayService _smartPlayService = GetIt.I<SmartPlayService>();

  List<HomeSection> _sections = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sections = await _recommendationService.getPersonalizedFeed();

      if (mounted) {
        setState(() {
          _sections = sections;
        });

        // Load local tracks separately to append as a new section
        try {
          final db = GetIt.I<AppDatabase>();
          final localTracks = await db.getRandomTracks(limit: 20);

          if (localTracks.isNotEmpty) {
            // Unify metadata: Fetch overrides for enhanced info (Internet art, corrected tags)
            List<YouTubeSong> convertedSongs = [];
            final metadataService =
                GetIt.I.isRegistered<MetadataMatchingService>()
                    ? GetIt.I<MetadataMatchingService>()
                    : null;

            // Fetch all overrides in parallel if service is available
            Map<String, LocalTrackOverride?> overrides = {};
            if (metadataService != null) {
              final futures = localTracks.map((t) async {
                final override = await metadataService.getTrackOverride(t.path);
                return MapEntry(t.path, override);
              });
              final results = await Future.wait(futures);
              overrides = Map.fromEntries(results);
            }

            for (var t in localTracks) {
              String title = t.title;
              String artist = t.artist ?? 'Unknown Artist';
              String thumb = '';

              // Apply Metadata Override if available
              final override = overrides[t.path];
              if (override != null) {
                title = override.correctTitle ?? title;
                artist = override.correctArtist ?? artist;
                if (override.thumbnailUrl != null &&
                    override.thumbnailUrl!.isNotEmpty) {
                  thumb = override.thumbnailUrl!;
                }
              }

              // Fallback artwork logic
              if (thumb.isEmpty) {
                if (t.artworkUri != null && t.artworkUri!.isNotEmpty) {
                  thumb = t.artworkUri!;
                } else if (t.mediaStoreId != null) {
                  thumb = 'mediastore:${t.mediaStoreId}';
                }
              }

              convertedSongs.add(YouTubeSong(
                videoId: 'local:${t.path}',
                title: title,
                artist: artist,
                thumbnailUrl: thumb,
              ));
            }

            final localSection = HomeSection(
              title: AppLocalizations.of(context).yourLocalMusic,
              type: SectionType.horizontal,
              songs: convertedSongs,
            );

            if (mounted) {
              setState(() {
                _sections.add(localSection);
              });
            }
          }
        } catch (e) {
          debugPrint('Error loading local tracks for home: $e');
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load recommendations: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onSongTap(YouTubeSong song) async {
    // Handle Local Tracks
    if (song.videoId.startsWith('local:')) {
      final path = song.videoId.substring(6); // Remove 'local:' prefix
      try {
        final db = GetIt.I<AppDatabase>();
        final track = await (db.select(db.tracks)
              ..where((t) => t.path.equals(path)))
            .getSingleOrNull();

        if (track != null) {
          final audioHandler = GetIt.I<MyAudioHandler>();
          await audioHandler.playLocalTrack(track);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Playing ${track.title}...'),
                  duration: const Duration(seconds: 1)),
            );
          }
        }
      } catch (e) {
        debugPrint('Error playing local track from home: $e');
      }
      return;
    }

    // Handle YouTube Tracks
    // Використовуємо централізований SmartPlayService
    await _smartPlayService.handleSongTap(context, song);
  }

  Future<void> _showSongContextMenu(
      BuildContext context, YouTubeSong song) async {
    // Використовуємо централізоване контекстне меню
    await YouTubeSongMenu.show(context, song);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadRecommendations,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: true,
              title: Text(AppLocalizations.of(context).madeForYou),
              centerTitle: false,
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Oops!',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Could not load your feed.',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRecommendations,
                        child: Text(AppLocalizations.of(context).retry),
                      ),
                    ],
                  ),
                ),
              )
            else if (_sections.isEmpty)
              SliverFillRemaining(
                child: Center(
                    child: Text(AppLocalizations.of(context).noMatchFound)),
              )
            else
              ..._sections.expand(_buildSectionSlivers),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSectionSlivers(HomeSection section) {
    if (section.songs.isEmpty) return [];

    final slivers = <Widget>[];

    // Section Header
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            section.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
          ),
        ),
      ),
    );

    // Section Content - Use PagedSongList for song type sections
    if (section.type == SectionType.vertical ||
        section.type == SectionType.grid ||
        section.type == SectionType.horizontal) {
      // All song sections now use the paged layout (YouTube Music style)
      if (section.songs.isNotEmpty) {
        slivers.add(SliverToBoxAdapter(
          child: PagedSongList(
            songs: section.songs,
            itemsPerPage: 5,
            onSongTap: _onSongTap,
            onPlayTap: _onSongTap,
            onMenuTap: (song) => _showSongContextMenu(context, song),
          ),
        ));
      }
    } else {
      // Fallback for unknown types (though currently all are treated same)
      // keeping previous list logic just in case, but practically unreachable with current logic
      slivers.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return CompactQuickPickTile(
              song: section.songs[index],
              onTap: () => _onSongTap(section.songs[index]),
              onPlayTap: () => _onSongTap(section.songs[index]),
              onMenuTap: () =>
                  _showSongContextMenu(context, section.songs[index]),
            );
          },
          childCount: section.songs.length,
        ),
      ));
    }

    return slivers;
  }
}
