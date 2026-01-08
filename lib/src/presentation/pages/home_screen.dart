import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/music_finder.dart';
import '../../data/datasources/app_database.dart';
import '../widgets/search/search_delegate.dart';
import 'all_tracks_screen.dart';
import 'folder_screen.dart';
import 'albums_screen.dart';
import 'artists_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'youtube_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AllTracksScreen(),
    const YouTubeHubScreen(),
    const AlbumsScreen(),
    const ArtistsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = GetIt.I<AppDatabase>();
    final musicFinder = GetIt.I<MusicFinder>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Oxide Player',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Login to YouTube Music',
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: MusicSearchDelegate(db),
              );
            },
          ),
        ],
        bottom: ValueListenableBuilder<bool>(
          valueListenable: musicFinder.isScanning,
          builder: (context, isScanning, child) {
            return PreferredSize(
              preferredSize: Size.fromHeight(isScanning ? 36.0 : 0.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isScanning ? 36.0 : 0.0,
                child: isScanning
                    ? OverflowBox(
                        minHeight: 0,
                        maxHeight: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const LinearProgressIndicator(minHeight: 4),
                            const SizedBox(height: 4),
                            ValueListenableBuilder<String>(
                              valueListenable: musicFinder.scanStatus,
                              builder: (context, status, _) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    status,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note),
            label: 'Tracks',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle_filled),
            label: 'YouTube',
          ),
          NavigationDestination(
            icon: Icon(Icons.album_outlined),
            selectedIcon: Icon(Icons.album),
            label: 'Albums',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Artists',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
