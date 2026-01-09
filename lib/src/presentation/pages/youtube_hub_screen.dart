import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import '../../core/services/innertube_service.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/services/youtube_helper.dart';
import '../../core/services/youtube_audio_source.dart';
import '../../core/services/audio_handler.dart';
import '../../domain/entities/youtube_song.dart';
import '../widgets/common_artwork.dart';
import 'login_screen.dart';
import 'playlist_tracks_screen.dart';

class YouTubeHubScreen extends StatefulWidget {
  const YouTubeHubScreen({super.key});

  @override
  State<YouTubeHubScreen> createState() => _YouTubeHubScreenState();
}

class _YouTubeHubScreenState extends State<YouTubeHubScreen> {
  final _innerTube = GetIt.I<InnerTubeService>();
  final _authService = GetIt.I<GoogleAuthService>();
  final _ytHelper = GetIt.I<YouTubeHelper>();
  final _audioHandler = GetIt.I<MyAudioHandler>();

  bool _isLoggedIn = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _playlists = [];  // Added playlists variable
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isSignedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });
      if (isLoggedIn) {
        _loadData();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load both home data and user playlists
      final List<YouTubeSong> songs = await _innerTube.getHomeData();
      final playlists = await _innerTube.getLibraryPlaylists();

      // Convert to the format expected by the UI
      final List<Map<String, dynamic>> sections = [
        {'title': 'Recommended', 'items': songs}
      ];

      setState(() {
        _sections = sections;
        _playlists = playlists;  // Set the playlists
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _playSong(YouTubeSong song) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loading ${song.title}...'), duration: const Duration(seconds: 1)),
    );

    final url = await _ytHelper.getAudioUrl(song.videoId);
    if (url != null) {
      final mediaItem = await _ytHelper.createMediaItem(song.videoId, customTitle: song.title, customArtist: song.artist);

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
        title: const Text('YouTube Music'),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                await _innerTube.logout();
                _checkLoginStatus();
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Sign in to YouTube Music\nfor a personalized experience',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final success = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                if (success == true) _loadData();
              },
              icon: const Icon(Icons.login),
              label: const Text('Login'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick access shortcuts
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Quick Access',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildShortcut(
                  icon: Icons.favorite,
                  label: 'Liked Songs',
                  color: Colors.redAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlaylistTracksScreen(
                        playlistId: 'LM',
                        title: 'Liked Songs',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildShortcut(
                  icon: Icons.history,
                  label: 'Last Played',
                  color: Colors.blueAccent,
                  onTap: () {
                    // History logic could go here
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ..._sections.map((section) => _buildSection(section)),
          
          if (_playlists.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 24, bottom: 16),
              child: Text(
                'Your Library',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistTracksScreen(
                          playlistId: playlist['playlistId'],
                          title: playlist['title'],
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CommonArtwork(
                            url: playlist['thumbnail'],
                            size: 200,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        playlist['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Playlist',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(Map<String, dynamic> section) {
    final title = section['title'] as String;
    final List<dynamic> itemsDynamic = section['items'];
    // Convert the dynamic items to YouTubeSong objects properly
    final items = <YouTubeSong>[];
    for (final item in itemsDynamic) {
      if (item is YouTubeSong) {
        items.add(item);
      } else if (item is Map<String, dynamic>) {
        items.add(YouTubeSong(
          videoId: item['videoId'],
          title: item['title'],
          artist: item['artist'],
          thumbnailUrl: item['thumbnailUrl'],
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(
          height: 215, // Fixed overflow issues
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final song = items[index];
              return GestureDetector(
                onTap: () => _playSong(song),
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CommonArtwork(
                          url: song.thumbnailUrl,
                          size: 150,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[400], 
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShortcut({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
