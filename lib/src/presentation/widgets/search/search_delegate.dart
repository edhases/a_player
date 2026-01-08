import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../data/datasources/app_database.dart';
import '../../../core/services/audio_handler.dart';
import '../../../core/services/innertube_service.dart';
import '../../../core/services/youtube_helper.dart';
import '../../../core/services/youtube_audio_source.dart';
import '../../../domain/entities/youtube_song.dart';
import '../common_artwork.dart';

class MusicSearchDelegate extends SearchDelegate<Track?> {
  final AppDatabase db;
  final MyAudioHandler _audioHandler = GetIt.I<MyAudioHandler>();

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

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // YouTube Results
        _YouTubeSearchSection(query: query, audioHandler: _audioHandler, onClose: () => close(context, null)),

        const Divider(),

        // Local Library Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Local Library', style: Theme.of(context).textTheme.titleMedium),
        ),
        FutureBuilder<List<Track>>(
          future: _searchLocalTracks(query),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
               return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No local results found.', style: TextStyle(color: Colors.grey)),
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
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
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
    final mediaItems = tracks.map((track) => MediaItem(
      id: track.path,
      album: track.album ?? '',
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.duration),
      extras: track.mediaStoreId != null ? {'mediaStoreId': track.mediaStoreId} : null,
    )).toList();

    await _audioHandler.updateQueue(mediaItems);
    await _audioHandler.skipToQueueItem(startIndex);
  }
}

class _YouTubeSearchSection extends StatefulWidget {
  final String query;
  final MyAudioHandler audioHandler;
  final VoidCallback onClose;

  const _YouTubeSearchSection({required this.query, required this.audioHandler, required this.onClose});

  @override
  State<_YouTubeSearchSection> createState() => _YouTubeSearchSectionState();
}

class _YouTubeSearchSectionState extends State<_YouTubeSearchSection> {
  final InnerTubeService _innerTubeService = GetIt.I<InnerTubeService>();
  final YouTubeHelper _ytHelper = GetIt.I<YouTubeHelper>(); // Changed from YoutubeExplode
  Timer? _debounceTimer;
  
  late Future<List<YouTubeSong>> _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchFuture = _innerTubeService.search(widget.query);
  }

  @override
  void didUpdateWidget(covariant _YouTubeSearchSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _debounceSearch();
    }
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchFuture = _innerTubeService.search(widget.query);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('YouTube Music', style: Theme.of(context).textTheme.titleMedium),
        ),
        FutureBuilder<List<YouTubeSong>>(
          future: _searchFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ));
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No results found online.', style: TextStyle(color: Colors.grey)),
              );
            }

            final onlineTracks = snapshot.data!;
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
                      errorWidget: (context, url, error) => const Icon(Icons.music_note),
                    ),
                  ),
                  title: Text(track.title),
                  subtitle: Text(track.artist),
                  trailing: const Icon(Icons.play_circle_outline),
                  onTap: () => _playYouTubeTrack(context, track),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _playYouTubeTrack(BuildContext context, YouTubeSong song) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching audio stream...'), duration: Duration(seconds: 1)));

    try {
      Duration? duration;
      String? url;
      String? userAgent;

      // 1. Prioritize YouTubeHelper (YoutubeExplode) as it handles Signature Decryption ('n' parameter)
      // This is slightly slower but MUCH more reliable against 403 errors.
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching audio stream...'), duration: Duration(seconds: 1)));
      
      try {
        debugPrint('[SearchDelegate] Fetching URL via YouTubeHelper for: ${song.videoId}');
        url = await _ytHelper.getAudioUrl(song.videoId);
        // Use a desktop Chrome User-Agent which matches YoutubeExplode's typical context
        userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36';
        debugPrint('[SearchDelegate] YouTubeHelper succeeded.');
      } catch (e) {
        debugPrint('[SearchDelegate] YouTubeHelper failed: $e');
      }

      // 2. Fallback to InnerTube if YouTubeHelper failed
      if (url == null) {
        debugPrint('[SearchDelegate] Falling back to InnerTube...');
        final songData = await _innerTubeService.getSongUrl(song.videoId);
        if (songData != null) {
          url = songData['url'];
          userAgent = songData['agent'];
        }
      }
      
      // 3. Always try to get duration/details as it fixes "00:00" UI issue
      try {
        final video = await _ytHelper.getVideoDetails(song.videoId);
        duration = video?.duration;
      } catch (e) {
        debugPrint('[SearchDelegate] Failed to fetch video details: $e');
      }

      if (url != null) {
        debugPrint('[SearchDelegate] Ready to play YouTube. URL starts with: ${url.substring(0, 50)}...');
        debugPrint('[SearchDelegate] Duration: $duration, User-Agent: $userAgent');
        
        final mediaItem = MediaItem(
          id: url, 
          title: song.title,
          artist: song.artist,
          duration: duration,
          artUri: Uri.parse(song.thumbnailUrl),
          extras: {
            'isOnline': true, 
            'videoId': song.videoId,
            if (userAgent != null) 'user_agent': userAgent, // Critical for avoiding 403
          },
        );

        await widget.audioHandler.updateQueue([mediaItem]);
        // Don't await play() here as it might hang 20s on emulators
        widget.audioHandler.play();
        widget.onClose();
      } else {
        debugPrint('[SearchDelegate] Failed to obtain URL for YouTube track: ${song.title}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load. Track might be restricted.')));
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
