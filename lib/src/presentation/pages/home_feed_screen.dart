import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/services/innertube_service.dart';
import '../../core/services/music_finder.dart';
import '../../core/services/audio_handler.dart';
import '../../core/services/youtube_service.dart';
import '../../core/utils/localization.dart';
import '../../data/datasources/app_database.dart';
import '../widgets/common_artwork.dart';
import 'package:audio_service/audio_service.dart';
import 'playlist_tracks_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final _innerTube = GetIt.I<InnerTubeService>();
  final _audioHandler = GetIt.I<MyAudioHandler>();
  final _ytHelper = GetIt.I<YouTubeHelper>();

  bool _isLoading = true;
  List<Track> _quickPicksLocal = [];
  List<Map<String, dynamic>> _ytMixes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Safe way to get MusicFinder if Provider is used
  MusicFinder get musicFinder =>
      Provider.of<MusicFinder>(context, listen: false);

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Local Quick Picks
      _quickPicksLocal = await musicFinder.getRandomTracks(limit: 10);

      // 2. YouTube Home Data
      final homeJson = await _innerTube.getHomeData();
      _parseYouTubeHome(homeJson);
    } catch (e) {
      debugPrint('Error loading home feed: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _parseYouTubeHome(Map<String, dynamic> json) {
    try {
      final tabs =
          json['contents']?['singleColumnBrowseResultsRenderer']?['tabs'];
      if (tabs == null || tabs is! List) return;

      final content = tabs[0]?['tabRenderer']?['content']
          ?['sectionListRenderer']?['contents'];
      if (content == null || content is! List) return;

      _ytMixes.clear();

      for (var section in content) {
        final musicCarousel = section['musicCarouselShelfRenderer'];
        if (musicCarousel != null) {
          final title = musicCarousel['header']
                      ?['musicCarouselShelfBasicHeaderRenderer']?['title']
                  ?['runs']?[0]?['text'] ??
              "Mix";
          final items = musicCarousel['contents'];

          if (items != null && items is List) {
            final sectionItems = <Map<String, dynamic>>[];
            for (var item in items) {
              final mrlir = item['musicResponsiveListItemRenderer'] ??
                  item['musicTwoColumnItemRenderer'];
              if (mrlir != null) {
                // Extract basic info
                final titleText = mrlir['title']?['runs']?[0]?['text'] ?? "";
                final thumb = mrlir['thumbnail']?['musicThumbnailRenderer']
                            ?['thumbnail']?['thumbnails']
                        ?.last['url'] ??
                    "";
                final navEndpoint = mrlir['navigationEndpoint'];

                String? id;
                String type = "song";

                if (navEndpoint?['watchEndpoint'] != null) {
                  id = navEndpoint['watchEndpoint']['videoId'];
                  type = "song";
                } else if (navEndpoint?['browseEndpoint'] != null) {
                  id = navEndpoint['browseEndpoint']['browseId'];
                  type = "playlist";
                }

                if (titleText.isNotEmpty && id != null) {
                  sectionItems.add({
                    'title': titleText,
                    'thumbnail': thumb,
                    'id': id,
                    'type': type,
                    'subtitle': mrlir['subtitle']?['runs']?[0]?['text'] ?? "",
                  });
                }
              }
            }

            if (sectionItems.isNotEmpty) {
              _ytMixes.add({
                'title': title,
                'items': sectionItems,
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing YT Home: $e');
    }
  }

  Future<void> _playLocalTrack(Track track) async {
    final mediaItem = MediaItem(
      id: track.path,
      album: track.album ?? '',
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
      extras: track.mediaStoreId != null
          ? {'mediaStoreId': track.mediaStoreId}
          : null,
    );
    await _audioHandler.updateQueue([mediaItem]);
    await _audioHandler.play();
  }

  Future<void> _onYoutubeItemTap(Map<String, dynamic> item) async {
    final id = item['id'];
    final type = item['type'];
    final title = item['title'];

    if (type == 'playlist') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PlaylistTracksScreen(playlistId: id, title: title),
        ),
      );
    } else {
      // Assume song
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Loading $title...')));
      final mediaItem = await _ytHelper.createMediaItem(id);
      await _audioHandler.updateQueue([mediaItem]);
      _audioHandler.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of('nav_home')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Quick Picks (Local)
              if (_quickPicksLocal.isNotEmpty) ...[
                _buildSectionHeader(AppLocalizations.of('quick_picks')),
                SizedBox(
                  height: 210, // Increased from 180 to prevent overflow
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _quickPicksLocal.length,
                    itemBuilder: (context, index) {
                      final track = _quickPicksLocal[index];
                      return _buildLocalTrackCard(track);
                    },
                  ),
                ),
              ],

              // 2. YouTube Mixes
              for (var mixSection in _ytMixes) ...[
                _buildSectionHeader(mixSection['title']),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: (mixSection['items'] as List).length,
                    itemBuilder: (context, index) {
                      final item = (mixSection['items'] as List)[index];
                      return _buildYoutubeCard(item);
                    },
                  ),
                ),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildLocalTrackCard(Track track) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => _playLocalTrack(track),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CommonArtwork(
                  mediaStoreId: track.mediaStoreId,
                  path: track.path,
                  size: 140,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              track.artist ?? 'Unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYoutubeCard(Map<String, dynamic> item) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => _onYoutubeItemTap(item),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item['thumbnail'],
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Container(color: Colors.grey[800]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['title'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              item['subtitle'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
