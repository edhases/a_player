import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/datasources/app_database.dart';
import 'detail_screen.dart';

class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artists'),
      ),
      body: FutureBuilder<List<Artist>>(
        future: db.getAllArtists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No artists found.'));
          }

          final artists = snapshot.data!;
          // Sort artists alphabetically
          artists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          return ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(artist.name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        type: DetailScreenType.artist,
                        title: artist.name,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
