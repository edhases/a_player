import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metadata_god/metadata_god.dart';
import '../../data/datasources/app_database.dart';
import 'detail_screen.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
      ),
      body: FutureBuilder<List<AlbumWithArtwork>>(
        future: db.getAllAlbums(),
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

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              final heroTag = 'album_art_${album.title}';

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        type: DetailScreenType.album,
                        title: album.title,
                      ),
                    ),
                  );
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Hero(
                          tag: heroTag,
                          child: _buildArtwork(album),
                        ),
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
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildArtwork(AlbumWithArtwork album) {
    if (album.artworkPath == null) {
      return const Icon(Icons.album, size: 60, color: Colors.grey);
    }

    return FutureBuilder<Metadata?>(
      future: MetadataGod.readMetadata(file: album.artworkPath!),
      builder: (context, snapshot) {
        final artwork = snapshot.data?.picture?.data;
        return Container(
          color: Colors.grey.withValues(alpha: 0.2),
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
