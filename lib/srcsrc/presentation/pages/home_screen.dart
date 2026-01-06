import 'package:flutter/material.dart';
import 'folder_screen.dart';
import 'all_tracks_screen.dart';
import 'albums_screen.dart';
import 'artists_screen.dart'; // Import the new screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    FolderScreen(path: '.'),
    AllTracksScreen(),
    AlbumsScreen(),
    ArtistsScreen(), // Add the new screen to the list
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        // To prevent the layout from changing when a new item is selected
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open),
            label: 'Folders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Tracks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.album),
            label: 'Albums',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Add the new tab item
            label: 'Artists',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
