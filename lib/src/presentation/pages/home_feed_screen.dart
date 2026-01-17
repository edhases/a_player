import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../widgets/square_song_card.dart';
import '../widgets/paged_song_grid.dart';
import '../widgets/compact_song_tile.dart';

import '../../domain/entities/home_section.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/services/audio_handler.dart';
import '../../domain/entities/youtube_song.dart';
import '../../core/services/innertube_service.dart';
import 'playlist_tracks_screen.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/favorites_service.dart';
import '../../core/utils/localization.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final RecommendationService _recommendationService =
      GetIt.I<RecommendationService>();
  final InnerTubeService _innerTube = GetIt.I<InnerTubeService>();

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
          _isLoading = false;
        });
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
    // smart play logic
    final isSuspectId = song.videoId.length != 11 && song.videoId.isNotEmpty;
    final isPlaylist =
        song.isPlaylist || (song.playlistId != null) || isSuspectId;
    final playlistId = song.playlistId ?? (isSuspectId ? song.videoId : null);

    if (isPlaylist && playlistId != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Loading ${song.title}...'),
            duration: const Duration(seconds: 1)),
      );

      try {
        final tracks = await _innerTube.getPlaylistTracks(playlistId);
        if (!mounted) return;

        if (tracks.length == 1) {
          var singleTrack = tracks.first;
          singleTrack = singleTrack.copyWith(
            artist:
                (singleTrack.artist == 'Unknown' || singleTrack.artist.isEmpty)
                    ? song.artist
                    : singleTrack.artist,
            thumbnailUrl: (singleTrack.thumbnailUrl.isEmpty)
                ? song.thumbnailUrl
                : singleTrack.thumbnailUrl,
          );

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Playing ${singleTrack.title}...'),
                duration: const Duration(seconds: 1)),
          );
          await GetIt.I<MyAudioHandler>().playYouTubeSong(singleTrack);
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlaylistTracksScreen(
                playlistId: playlistId,
                title: song.title,
                knownArtist: song.artist,
                knownThumbnail: song.thumbnailUrl,
                preloadedTracks: tracks,
              ),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      GetIt.I<MyAudioHandler>().playYouTubeSong(song);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Playing ${song.title}...'),
              duration: const Duration(seconds: 1)),
        );
      }
    }
  }

  Future<void> _showSongContextMenu(
      BuildContext context, YouTubeSong song) async {
    final audioHandler = GetIt.I<MyAudioHandler>();
    final isLiked = await GetIt.I<FavoritesService>().isLiked(song.videoId);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: song.thumbnailUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(song.artist),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(AppLocalizations.of(context).addToQueue),
                onTap: () {
                  audioHandler.addYouTubeToQueue(song);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Added to Queue'),
                        duration: Duration(seconds: 1)),
                  );
                },
              ),
              ListTile(
                leading: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                title: Text(
                    isLiked ? 'Remove from Favorites' : 'Add to Favorites'),
                onTap: () {
                  GetIt.I<FavoritesService>().toggleFavorite(
                    videoId: song.videoId,
                    title: song.title,
                    artist: song.artist,
                    thumbnailUrl: song.thumbnailUrl,
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
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

    // Section Content
    if (section.type == SectionType.vertical) {
      // List View (Vertical) - For "Listen Again"
      slivers.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CompactSongTile(
                song: section.songs[index],
                onTap: () => _onSongTap(section.songs[index]),
                onMenuTap: () =>
                    _showSongContextMenu(context, section.songs[index]),
              ),
            );
          },
          childCount: section.songs.length,
        ),
      ));
    } else if (section.type == SectionType.grid) {
      // Grid View (Tiles) - For Albums/Mixes
      slivers.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return SquareSongCard(
                song: section.songs[index],
                width: double.infinity,
                onTap: () => _onSongTap(section.songs[index]),
              );
            },
            childCount: section.songs.length,
          ),
        ),
      ));
    } else {
      // Horizontal (Paged Grid or Carousel)
      // Check if it's "Quick Picks" -> Use Paged Grid
      // User requested "List or Tiles", so we should try to honor that for main sections.
      // But Quick Picks is special.

      Widget content;
      if (section.title.toLowerCase().contains('quick picks') ||
          section.title.toLowerCase().contains('швидкий вибір') ||
          section.title.toLowerCase().contains('start radio')) {
        content = PagedSongGrid(
          songs: section.songs,
          onSongTap: _onSongTap,
        );
      } else {
        // Fallback for generic horizontal sections if any
        content = SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: section.songs.length,
            itemBuilder: (context, index) {
              return SquareSongCard(
                song: section.songs[index],
                onTap: () => _onSongTap(section.songs[index]),
              );
            },
          ),
        );
      }

      slivers.add(SliverToBoxAdapter(child: content));
    }

    return slivers;
  }
}
