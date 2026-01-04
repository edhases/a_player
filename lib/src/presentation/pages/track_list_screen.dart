import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:oxide_player/src/presentation/pages/player_screen.dart';
import 'package:provider/provider.dart';

class TrackListScreen extends StatefulWidget {
  final String folderPath;

  const TrackListScreen({super.key, required this.folderPath});

  @override
  _TrackListScreenState createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  late AppDatabase _database;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _database = Provider.of<AppDatabase>(context);
  }

  Future<List<Track>> _getTracks() async {
    final query = _database.select(_database.tracks)
      ..where((t) => t.folderPath.equals(widget.folderPath));
    return query.get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderPath.split('/').last),
      ),
      body: FutureBuilder<List<Track>>(
        future: _getTracks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tracks found.'));
          }

          final tracks = snapshot.data!;
          return ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return ListTile(
                title: Text(track.title),
                subtitle: Text(track.artist ?? 'Unknown Artist'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(track: track),
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
