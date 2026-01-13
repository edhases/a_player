import 'package:flutter/material.dart';
import 'folder_screen.dart';
import 'albums_screen.dart';
import 'artists_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Folders'),
              Tab(text: 'Albums'),
              Tab(text: 'Artists'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FolderScreen(path: '.'), // Start at root
            const AlbumsScreen(),
            const ArtistsScreen(),
          ],
        ),
      ),
    );
  }
}
