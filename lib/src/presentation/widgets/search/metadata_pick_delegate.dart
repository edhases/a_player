import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/services/innertube/innertube.dart';
import '../../../domain/entities/youtube_song.dart';

class MetadataPickDelegate extends SearchDelegate<YouTubeSong?> {
  final _searchSubject = BehaviorSubject<String>();
  Stream<String> get _debouncedQuery => _searchSubject.stream
      .debounceTime(const Duration(milliseconds: 500))
      .distinct();

  final InnerTubeService _innerTubeService = GetIt.I<InnerTubeService>();

  MetadataPickDelegate();

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
    _searchSubject.add(query);

    return StreamBuilder<String>(
      stream: _debouncedQuery,
      builder: (context, snapshot) {
        final debouncedQuery = snapshot.data ?? '';
        if (debouncedQuery.isEmpty) {
          return const Center(child: Text("Type to search..."));
        }

        return FutureBuilder<List<YouTubeSong>>(
          future: _innerTubeService.search(debouncedQuery),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No results found'));
            }

            final songs = snapshot.data!;
            if (songs.isEmpty) {
              return const Center(child: Text('No results found'));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final track = songs[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: track.thumbnailUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.music_note),
                    ),
                  ),
                  title: Text(track.title),
                  subtitle: Text(track.artist),
                  trailing: const Icon(Icons.check_circle_outline),
                  onTap: () {
                    close(context, track);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Show results immediately as suggestions
    _searchSubject.add(query);
    return buildResults(context);
  }

  @override
  void close(BuildContext context, YouTubeSong? result) {
    debugPrint('MetadataPickDelegate closing with result: ${result?.title}');
    _searchSubject.close();
    super.close(context, result);
  }
}
