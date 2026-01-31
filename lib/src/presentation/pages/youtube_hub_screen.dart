import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../widgets/paged_song_list.dart';
import '../widgets/youtube_song_menu.dart';
import '../../core/services/innertube/innertube.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/utils/localization.dart';
import '../../core/services/smart_play_service.dart';
import '../../domain/entities/youtube_song.dart';
import '../widgets/common_artwork.dart';
import 'login_screen.dart';
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
  final _smartPlayService = GetIt.I<SmartPlayService>();

  bool _isLoggedIn = false;
  bool _isLoading = true;
  List<HomeShelf> _sections = [];
  List<YouTubePlaylist> _playlists = [];
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
      final sections = await _innerTube.getHomeData();
      final playlists = await _innerTube.getLibraryPlaylists();

      setState(() {
        _sections = sections;
        _playlists = playlists;
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
    // Використовуємо централізований SmartPlayService
    await _smartPlayService.handleSongTap(context, song);
  }

  Future<void> _showSongContextMenu(
      BuildContext context, YouTubeSong song) async {
    await YouTubeSongMenu.show(context, song);
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
                  key: const Key('youtube_liked_songs_button'),
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
                  key: const Key('youtube_last_played_button'),
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
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: _playlists.length,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return GestureDetector(
                  onTap: () {
                    final song = YouTubeSong(
                      videoId: playlist.id,
                      title: playlist.title,
                      artist:
                          playlist.author ?? 'Unknown', // Library playlists usually don't have artist info here
                      thumbnailUrl: playlist.thumbnailUrl ?? '',
                      isPlaylist: true,
                      playlistId: playlist.id,
                      category: 'Playlist',
                    );
                    _playSong(song);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CommonArtwork(
                            url: playlist.thumbnailUrl,
                            size: 120,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        playlist.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                      Text(
                        loc.playlistType,
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
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

  Widget _buildSection(HomeShelf section) {
    final title = section.title;
    final items = section.items;

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
        PagedSongList(
          songs: items,
          itemsPerPage: 5,
          onSongTap: _playSong,
          onPlayTap: _playSong,
          onMenuTap: (song) => _showSongContextMenu(context, song),
        ),
      ],
    );
  }
}
