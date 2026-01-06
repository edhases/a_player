import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:metadata_god/metadata_god.dart';
import '../../data/datasources/app_database.dart';

// 1. New data class to represent an album.
class Album {
  final String title;
  final String? artist;
  final String artworkTrackPath; // Path to a track for fetching artwork

  Album({required this.title, this.artist, required this.artworkTrackPath});
}

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  // 2. New method to fetch and group tracks into albums.
  Future<List<Album>> _getAlbums(AppDatabase db) async {
    final allTracks = await db.select(db.tracks).get();
    final groupedByAlbum = groupBy(allTracks, (Track track) => track.album ?? 'Unknown Album');

    final albums = groupedByAlbum.entries.map((entry) {
      final firstTrack = entry.value.first;
      return Album(
        title: entry.key,
        artist: firstTrack.artist,
        artworkTrackPath: firstTrack.path,
      );
    }).toList();

    // Sort albums alphabetically
    albums.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return albums;
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
      ),
      body: FutureBuilder<List<Album>>(
        future: _getAlbums(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No albums found.'));
          }

          final albums = snapshot.data!;
          // 3. Display albums in a GridView.
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 albums per row
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildArtwork(album),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        album.title,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildArtwork(Album album) {
    return FutureBuilder<Metadata?>(
      future: MetadataGod.readMetadata(file: album.artworkTrackPath),
      builder: (context, snapshot) {
        final artwork = snapshot.data?.picture?.data;
        return Container(
          color: Colors.grey.withOpacity(0.2),
          child: artwork != null
              ? Image.memory(
                  artwork,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                )
              : const Icon(Icons.album, size: 60, color: Colors.grey),
        );
      },
    );
  }
}
