import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import '../../data/datasources/app_database.dart';
import '../../core/services/audio_handler.dart';

class MusicSearchDelegate extends SearchDelegate<Track?> {
  final AppDatabase db;

  MusicSearchDelegate(this.db);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Container();
    }

    final audioHandler = GetIt.I<MyAudioHandler>();

    return FutureBuilder<List<Track>>(
      future: _searchTracks(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found.'));
        }

        final tracks = snapshot.data!;
        return ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return ListTile(
              title: Text(track.title),
              subtitle: Text('${track.artist ?? 'Unknown'} - ${track.album ?? 'Unknown'}'),
              onTap: () {
                _playQueue(audioHandler, tracks, index);
                close(context, track);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // We can show recent searches here in the future.
    // For now, just show an empty container.
    return Container();
  }

  Future<List<Track>> _searchTracks(String query) async {
    final lowerCaseQuery = '%${query.toLowerCase()}%';
    return (db.select(db.tracks)
          ..where((t) =>
              t.title.toLowerCase().like(lowerCaseQuery) |
              t.artist.toLowerCase().like(lowerCaseQuery) |
              t.album.toLowerCase().like(lowerCaseQuery)))
        .get();
  }

  void _playQueue(MyAudioHandler audioHandler, List<Track> tracks, int startIndex) {
    final mediaItems = tracks.map((track) => MediaItem(
      id: track.path,
      album: track.album ?? '',
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
    )).toList();

    audioHandler.updateQueue(mediaItems);
    audioHandler.skipToQueueItem(startIndex);
  }
}
