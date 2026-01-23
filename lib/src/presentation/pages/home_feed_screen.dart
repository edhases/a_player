import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../widgets/compact_quick_pick_tile.dart';
import '../widgets/paged_song_list.dart';
import '../widgets/youtube_song_menu.dart';

import '../../domain/entities/home_section.dart';
import '../../core/services/smart_play_service.dart';
import '../../domain/entities/youtube_song.dart';
import '../../core/utils/localization.dart';
import '../../data/datasources/app_database.dart';
import '../../core/services/audio_handler.dart';
import '../blocs/home/home_bloc.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final SmartPlayService _smartPlayService = GetIt.I<SmartPlayService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<HomeBloc>().add(HomeRefreshFeed());
        },
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            // Correct approach: Build the whole CustomScrollView inside BlocBuilder
            // OR use Sliver list logic properly.

            return CustomScrollView(
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
                if (state.status == HomeStatus.loading &&
                    state.sections.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.status == HomeStatus.failure &&
                    state.sections.isEmpty)
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
                            onPressed: () {
                              context.read<HomeBloc>().add(HomeRefreshFeed());
                            },
                            child: Text(AppLocalizations.of(context).retry),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (state.sections.isEmpty &&
                    state.status == HomeStatus.success)
                  SliverFillRemaining(
                    child: Center(
                        child: Text(AppLocalizations.of(context).noMatchFound)),
                  )
                else
                  ...state.sections.expand(_buildSectionSlivers),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _onSongTap(YouTubeSong song) async {
    // Handle Radio Tracks
    if (song.videoId.startsWith('radio:')) {
      final idStr = song.videoId.substring(6);
      final id = int.tryParse(idStr);
      if (id != null) {
        // Play radio
        // We need to fetch the full object or just construct it?
        // AudioHandler needs RadioStation object.
        // Fetch from DB is safest.
        final db = GetIt.I<AppDatabase>();
        // getAllRadioStations returns List. We need single.
        // Simpler: Just make a temporary RadioStation object if we have data,
        // OR fetch it. Since we only have partial data in YouTubeSong (title, art),
        // let's fetch to be safe for StreamURL.
        final stations = await db.getAllRadioStations();
        final station = stations.where((s) => s.id == id).firstOrNull;

        if (station != null) {
          final audioHandler = GetIt.I<MyAudioHandler>();
          await audioHandler.playRadioStation(station);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Playing ${station.name}...'),
                  duration: const Duration(seconds: 1)),
            );
          }
        }
      }
      return;
    }

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
    await _smartPlayService.handleSongTap(context, song);
  }

  Future<void> _showSongContextMenu(
      BuildContext context, YouTubeSong song) async {
    if (song.videoId.startsWith('radio:')) return; // No menu for radio yet
    await YouTubeSongMenu.show(context, song);
  }

  List<Widget> _buildSectionSlivers(HomeSection section) {
    if (section.songs.isEmpty) return [];

    final slivers = <Widget>[];

    // Localize Title
    String title = section.title;
    final loc = AppLocalizations.of(context);
    if (title == 'liked_songs')
      title = loc.likedSongs;
    else if (title == 'your_local_music')
      title = loc.yourLocalMusic;
    else if (title == 'radio_stations')
      title = loc.radio; // Or 'radio_stations' key
    // else, assume it's "Made For You" or other dynamic title, or simple string.

    // Section Header
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
          ),
        ),
      ),
    );

    // Section Content
    if (section.type == SectionType.vertical ||
        section.type == SectionType.grid ||
        section.type == SectionType.horizontal) {
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
