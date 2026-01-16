import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../widgets/square_song_card.dart';
import '../../core/services/innertube_service.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/utils/localization.dart';
import '../../core/services/audio_handler.dart';
import '../../domain/entities/youtube_song.dart';
import '../widgets/common_artwork.dart';
import 'login_screen.dart';
import 'playlist_tracks_screen.dart';
import 'last_played_screen.dart';
import 'liked_songs_screen.dart';

class YouTubeHubScreen extends StatefulWidget {
  const YouTubeHubScreen({super.key});

  @override
  State<YouTubeHubScreen> createState() => _YouTubeHubScreenState();
}

class _YouTubeHubScreenState extends State<YouTubeHubScreen> {
  final _innerTube = GetIt.I<InnerTubeService>();
  final _authService = GetIt.I<GoogleAuthService>();
  final _audioHandler = GetIt.I<MyAudioHandler>();

  bool _isLoggedIn = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _playlists = []; // Added playlists variable
  String? _error;

  StreamSubscription<bool>? _loginStatusSubscription;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loginStatusSubscription =
        _authService.onLoginStatusChanged.listen((isLoggedIn) {
      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
        });
        if (isLoggedIn) {
          _loadData();
        } else {
          setState(() {
            _isLoading = false;
            _sections = [];
            _playlists = [];
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _loginStatusSubscription?.cancel();
    super.dispose();
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
      // Load both home data and user playlists
      final sectionsResult = await _innerTube.getHomeData();
      final playlists = await _innerTube.getLibraryPlaylists();

      setState(() {
        if (sectionsResult.isSuccess) {
          _sections = sectionsResult.data!;
        } else {
          _error = sectionsResult.error;
        }
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _playSong(YouTubeSong song) async {
    // If it's a container (Album/Playlist/Single), navigate to it instead of trying to play the container ID
    if (song.isPlaylist && song.playlistId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistTracksScreen(
            playlistId: song.playlistId!,
            title: song.title,
            knownArtist: song.artist,
            knownThumbnail: song.thumbnailUrl,
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Playing ${song.title}...'),
          duration: const Duration(seconds: 1)),
    );

    // Use centralized player logic
    await _audioHandler.playYouTubeSong(song);
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
    final loc = AppLocalizations.of(context);
    if (!_isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              loc.signInMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
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
              label: Text(loc.login),
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
          // Quick access shortcuts
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              loc.quickAccess,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LikedSongsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.favorite),
                  label: Text(loc.likedSongs),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LastPlayedScreen()),
                  ),
                  icon: const Icon(Icons.history),
                  label: Text(loc.lastPlayedTitle),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          const SizedBox(height: 8),

          // Error Banner
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                        child: Text('Error: $_error',
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            ),

          ..._sections.map((section) => _buildSection(section)),

          if (_playlists.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: Text(
                loc.yourLibrary,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                        loc.playlistType,
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
              return SquareSongCard(
                song: song,
                width: 150,
                onTap: () => _playSong(song),
              );
            },
          ),
        ),
      ],
    );
  }
}
