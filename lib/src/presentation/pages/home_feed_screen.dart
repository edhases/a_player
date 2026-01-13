import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../domain/repositories/music_repository.dart';
import '../../core/utils/localization.dart';
import '../../data/datasources/app_database.dart';
import '../../domain/entities/youtube_song.dart';
import '../../core/services/audio_handler.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final _repository = GetIt.I<MusicRepository>();
  final _audioHandler = GetIt.I<MyAudioHandler>();

  List<Track> _recentLocalTracks = [];
  List<Map<String, dynamic>> _youtubeSections = [];
  bool _isLoading = true;
  String? _error;
  String? _youtubeError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Local Recents
      final recents = await _repository.getRecentLocalTracks(limit: 10);

      // 2. Fetch YouTube Home Data
      final ytResult = await _repository.getHomeFeed();

      if (mounted) {
        setState(() {
          _recentLocalTracks = recents;
          if (ytResult.isSuccess) {
            _youtubeSections = ytResult.data!;
          } else {
            _youtubeError = ytResult.error;
            debugPrint('HomeFeed YouTube Error: ${ytResult.error}');
          }
          _isLoading = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[HomeFeed] Error loading data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getGreeting(AppLocalizations loc) {
    final hour = DateTime.now().hour;
    if (hour < 12)
      return 'Good morning'; // TODO: Localize these specifically if desired
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading home feed',
                style: Theme.of(context).textTheme.titleMedium),
            Text(_error!, style: Theme.of(context).textTheme.bodySmall),
            TextButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Greeting
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _getGreeting(loc),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // 1. Listen Again (Local Recents)
          if (_recentLocalTracks.isNotEmpty) ...[
            _buildSectionHeader(
                context, loc.listenAgain), // Use localized "Listen Again"
            SizedBox(
              height: 180,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _recentLocalTracks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final track = _recentLocalTracks[index];
                  return _buildLocalTrackCard(context, track);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 2. YouTube Error Banner
          if (_youtubeError != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text('YouTube Error: $_youtubeError',
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            ),

          // 3. YouTube Sections (Mixes, Recents, Community etc.)
          ..._youtubeSections.map((section) {
            final title = section['title'] as String? ?? '';
            final contents = section['contents'] as List<dynamic>? ?? [];

            if (contents.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, title),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: contents.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = contents[index];
                      // Determine type: Song, Video, Playlist...
                      // For simplicity, treating as Song or Playlist card
                      return _buildYouTubeCard(context, item);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }),

          // Bottom padding for MiniPlayer
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildLocalTrackCard(BuildContext context, Track track) {
    return GestureDetector(
      onTap: () async {
        // Play local track
        // We need to convert Track to MediaItem or similar for AudioHandler
        await _audioHandler.playLocalTrack(track);
      },
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[800],
                  image: track.artworkUri != null
                      ? DecorationImage(
                          image: NetworkImage(
                              track.artworkUri!), // Or FileImage if local path
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: track.artworkUri == null
                    ? const Icon(Icons.music_note, size: 48, color: Colors.grey)
                    : null,
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
              track.artist ?? 'Unknown Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYouTubeCard(BuildContext context, dynamic item) {
    // Basic extraction - adjust based on actual InnerTubeService data structure
    final title = item['title'] ?? '';
    final subtitle = item['subtitle'] ?? '';
    final thumb = item['thumbnail'] ?? '';
    final videoId = item['videoId'];
    final playlistId = item['playlistId'];

    return GestureDetector(
      onTap: () async {
        if (videoId != null) {
          // Play Song
          final song = YouTubeSong(
            videoId: videoId,
            title: title,
            artist: subtitle,
            thumbnailUrl: thumb,
            duration: 0,
          );
          await _audioHandler.playYouTubeSong(song);
        } else if (playlistId != null) {
          // Open Playlist (Not implemented yet, just print)
          debugPrint('Open playlist: $playlistId');
        }
      },
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[800],
                  image: thumb.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(thumb),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: thumb.isEmpty
                    ? const Icon(Icons.play_circle_outline,
                        size: 48, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
