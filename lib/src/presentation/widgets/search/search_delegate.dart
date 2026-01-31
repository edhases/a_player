import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/datasources/app_database.dart';
import '../../../core/services/audio_handler.dart';
import '../../../core/services/innertube/innertube.dart';
import '../../../core/services/youtube_helper.dart';
import '../../../core/theme/app_theme.dart';

import '../../../domain/entities/youtube_song.dart';
import '../common_artwork.dart';
import 'package:rxdart/rxdart.dart';
import '../../pages/playlist_tracks_screen.dart';
import '../youtube_song_menu.dart';

class MusicSearchDelegate extends SearchDelegate<Track?> {
  final AppDatabase db;
  final MyAudioHandler _audioHandler = GetIt.I<MyAudioHandler>();
  final _searchSubject = BehaviorSubject<String>();
  Stream<String> get _debouncedQuery => _searchSubject.stream
      .debounceTime(const Duration(milliseconds: 500))
      .distinct();

  MusicSearchDelegate(this.db) {
    _searchSubject.add(''); // Initial empty query
  }

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
          return Container();
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // YouTube Results
            _YouTubeSearchSection(
                query: debouncedQuery,
                audioHandler: _audioHandler,
                onClose: () => close(context, null)),

            const Divider(),

            // Local Library Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Local Library',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            FutureBuilder<List<Track>>(
              future: _searchLocalTracks(debouncedQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('No local results found.',
                        style: TextStyle(color: context.appColors.textSecondary)),
                  );
                }

                final localTracks = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: localTracks.length,
                  itemBuilder: (context, index) {
                    final track = localTracks[index];
                    return ListTile(
                      leading: SizedBox(
                        width: 50,
                        height: 50,
                        child: CommonArtwork(
                          mediaStoreId: track.mediaStoreId,
                          path: track.path,
                          size: 50,
                          radius: 4,
                        ),
                      ),
                      title: Text(track.title),
                      subtitle: Text(track.artist ?? 'Unknown'),
                      onTap: () {
                        _playLocalQueue(localTracks, index);
                        close(context, track);
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    _searchSubject.add(query);
    return buildResults(context);
  }

  @override
  void close(BuildContext context, Track? result) {
    _searchSubject.close();
    super.close(context, result);
  }

  Future<List<Track>> _searchLocalTracks(String query) async {
    final lowerCaseQuery = '%${query.toLowerCase()}%';
    return (db.select(db.tracks)
          ..where((t) =>
              t.title.lower().like(lowerCaseQuery) |
              t.artist.lower().like(lowerCaseQuery) |
              t.album.lower().like(lowerCaseQuery)))
        .get();
  }

  Future<void> _playLocalQueue(List<Track> tracks, int startIndex) async {
    final mediaItems = tracks
        .map((track) => MediaItem(
              id: track.path,
              album: track.album ?? '',
              title: track.title,
              artist: track.artist,
              duration: Duration(milliseconds: track.duration),
              extras: track.mediaStoreId != null
                  ? {'mediaStoreId': track.mediaStoreId}
                  : null,
            ))
        .toList();

    await _audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
    await _audioHandler.playQueueFromIndex(mediaItems, startIndex);
  }
}

class _YouTubeSearchSection extends StatefulWidget {
  final String query;
  final MyAudioHandler audioHandler;
  final VoidCallback onClose;

  const _YouTubeSearchSection(
      {required this.query, required this.audioHandler, required this.onClose});

  @override
  State<_YouTubeSearchSection> createState() => _YouTubeSearchSectionState();
}

class _YouTubeSearchSectionState extends State<_YouTubeSearchSection> {
  final InnerTubeService _innerTubeService = GetIt.I<InnerTubeService>();
  final YouTubeHelper _ytHelper = GetIt.I<YouTubeHelper>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('YouTube Music',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        FutureBuilder<List<YouTubeSong>>(
          future: _innerTubeService.search(widget.query),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ));
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final onlineTracks = snapshot.data!;
            if (onlineTracks.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('No results found online.',
                    style: TextStyle(color: context.appColors.textSecondary)),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: onlineTracks.length,
              itemBuilder: (context, index) {
                final track = onlineTracks[index];
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline),
                        onPressed: () => _playYouTubeTrack(track),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => YouTubeSongMenu.show(context, track),
                      ),
                    ],
                  ),
                  onTap: () => _playYouTubeTrack(track),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _playYouTubeTrack(YouTubeSong song) async {
    // 1. If it's a playlist/album, navigate to details
    if (song.isPlaylist && song.playlistId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistTracksScreen(
            playlistId: song.playlistId!,
            title: song.title,
            knownArtist: song.artist,
            knownThumbnail: song.thumbnailUrl,
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fetching audio stream...'),
        duration: Duration(seconds: 1)));

    try {
      String? url;

      // Use YouTubeHelper (YoutubeExplode) as it handles Signature Decryption ('n' parameter)
      // This is slightly slower but MUCH more reliable against 403 errors.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Fetching audio stream...'),
            duration: Duration(seconds: 1)));
      }

      try {
        debugPrint(
            '[SearchDelegate] Fetching URL via YouTubeHelper for: ${song.videoId}');
        url = await _ytHelper.getAudioUrl(song.videoId);
        debugPrint('[SearchDelegate] YouTubeHelper succeeded.');
      } catch (e) {
        debugPrint('[SearchDelegate] YouTubeHelper failed: $e');
      }

      if (url != null) {
        debugPrint(
            '[SearchDelegate] Ready to play YouTube. URL starts with: ${url.substring(0, 50)}...');

        final mediaItem = await _ytHelper.createMediaItem(song.videoId,
            customTitle: song.title, customArtist: song.artist, cachedUrl: url);

        // Use unified playback start
        // This handles stopping, queue clearing, and starting correctly.
        await widget.audioHandler.playQueueFromIndex([mediaItem], 0);
        if (mounted) {
          widget.onClose();
        }
      } else {
        debugPrint(
            '[SearchDelegate] Failed to obtain URL for YouTube track: ${song.title}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Failed to load. Track might be restricted.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
