import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/youtube_song.dart';
import '../../presentation/pages/playlist_tracks_screen.dart';
import 'audio_handler.dart';
import 'innertube/innertube.dart';

/// Result of a Smart Play operation
enum SmartPlayResultType {
  /// Single track played directly
  playedDirectly,

  /// Navigated to playlist/album screen
  navigatedToPlaylist,

  /// Error occurred during operation
  error,
}

class SmartPlayResult {
  final SmartPlayResultType type;
  final String? errorMessage;
  final List<YouTubeSong>? tracks;

  SmartPlayResult._({
    required this.type,
    this.errorMessage,
    this.tracks,
  });

  factory SmartPlayResult.playedDirectly() =>
      SmartPlayResult._(type: SmartPlayResultType.playedDirectly);

  factory SmartPlayResult.navigatedToPlaylist(List<YouTubeSong> tracks) =>
      SmartPlayResult._(
        type: SmartPlayResultType.navigatedToPlaylist,
        tracks: tracks,
      );

  factory SmartPlayResult.error(String message) =>
      SmartPlayResult._(type: SmartPlayResultType.error, errorMessage: message);
}

/// Centralized service for handling "Smart Play" logic.
///
/// This service unifies the playback behavior across all screens:
/// - Detects if a YouTubeSong is a playlist/album/single
/// - Fetches tracks if needed
/// - Plays directly for singles
/// - Navigates to playlist screen for multi-track albums
class SmartPlayService {
  final InnerTubeService _innerTube;
  final MyAudioHandler _audioHandler;
  
  // Debounce and duplicate prevention
  String? _currentlyLoadingPlaylistId;
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  SmartPlayService({
    InnerTubeService? innerTube,
    MyAudioHandler? audioHandler,
  })  : _innerTube = innerTube ?? GetIt.I<InnerTubeService>(),
        _audioHandler = audioHandler ?? GetIt.I<MyAudioHandler>();

  /// Determines if a song needs playlist resolution.
  ///
  /// Returns true if:
  /// - song.isPlaylist is true
  /// - videoId is not 11 characters (likely an album/playlist ID)
  ///
  /// Note: playlistId alone does NOT mean it needs resolution.
  /// Songs from "Listen Again" have playlistId for context but are still songs.
  /// A valid YouTube video ID is always 11 characters.
  bool needsPlaylistResolution(YouTubeSong song) {
    // If explicitly marked as playlist, resolve it
    if (song.isPlaylist) return true;
    
    // If videoId is 11 chars, it's a regular YouTube video - play directly
    if (song.videoId.length == 11) return false;
    
    // If videoId is not 11 chars and not empty, it's likely a playlist/album ID
    if (song.videoId.isNotEmpty) return true;
    
    return false;
  }

  /// Gets the effective playlist ID from a song.
  String? getPlaylistId(YouTubeSong song) {
    // If explicitly a playlist and has playlistId, use it
    if (song.isPlaylist && song.playlistId != null) return song.playlistId;
    
    // If videoId is not a standard 11-char ID, it's likely a playlist/album ID
    if (song.videoId.length != 11 && song.videoId.isNotEmpty) {
      return song.videoId;
    }
    
    // For regular songs with playlistId, this is just context, not for resolution
    return null;
  }

  /// Handles song tap with Smart Play logic.
  ///
  /// If the song is a container (Album/Playlist/Single):
  /// - Fetches tracks
  /// - If single track: plays directly
  /// - If multiple tracks: navigates to playlist screen
  ///
  /// If the song is a regular track: plays directly
  Future<SmartPlayResult> handleSongTap(
    BuildContext context,
    YouTubeSong song, {
    bool showSnackbars = true,
  }) async {
    debugPrint('[SmartPlay] ========================================');
    debugPrint('[SmartPlay] handleSongTap CALLED for: ${song.title}');
    debugPrint(
        '[SmartPlay] videoId: ${song.videoId}, length: ${song.videoId.length}');
    debugPrint(
        '[SmartPlay] isPlaylist: ${song.isPlaylist}, playlistId: ${song.playlistId}');
    debugPrint('[SmartPlay] artistId: ${song.artistId}, artist: ${song.artist}');

    // Check if it needs playlist resolution
    if (!needsPlaylistResolution(song)) {
      debugPrint('[SmartPlay] Regular song, playing directly');
      await _audioHandler.playYouTubeSong(song);

      if (showSnackbars && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing ${song.title}...'),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      return SmartPlayResult.playedDirectly();
    }

    // It's a container - resolve it
    final playlistId = getPlaylistId(song);
    if (playlistId == null) {
      debugPrint('[SmartPlay] No playlist ID found');
      return SmartPlayResult.error('Could not determine playlist ID');
    }

    // Prevent duplicate requests for the same playlist
    if (_currentlyLoadingPlaylistId == playlistId) {
      debugPrint('[SmartPlay] Already loading $playlistId, skipping duplicate request');
      return SmartPlayResult.error('Already loading this playlist');
    }

    debugPrint('[SmartPlay] Resolving playlist: $playlistId');
    _currentlyLoadingPlaylistId = playlistId;

    // Show loading feedback
    if (showSnackbars && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loading ${song.title}...'),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    try {
      final tracks = await _innerTube.getPlaylistTracks(playlistId);
      debugPrint('[SmartPlay] Fetched ${tracks.length} tracks');
      
      // Clear loading state
      _currentlyLoadingPlaylistId = null;

      if (!context.mounted) {
        return SmartPlayResult.error('Context no longer mounted');
      }

      // Smart Play: single track = play directly
      if (tracks.length == 1) {
        debugPrint('[SmartPlay] Single track album, playing directly');

        var singleTrack = tracks.first;

        // Merge metadata from container if useful
        // Include original playlistId for like synchronization
        // Also preserve original title if API returned placeholder
        final isPlaceholderTitle =
            singleTrack.title == 'Radio Mix Track' || singleTrack.title.isEmpty;

        singleTrack = singleTrack.copyWith(
          title: isPlaceholderTitle ? song.title : singleTrack.title,
          artist:
              (singleTrack.artist == 'Unknown' || singleTrack.artist.isEmpty)
                  ? song.artist
                  : singleTrack.artist,
          thumbnailUrl: singleTrack.thumbnailUrl.isEmpty
              ? song.thumbnailUrl
              : singleTrack.thumbnailUrl,
          playlistId:
              playlistId, // Keep original album/playlist ID for like sync
          // Preserve artistId from original song if not present in resolved track
          artistId: singleTrack.artistId ?? song.artistId,
        );

        if (showSnackbars) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playing ${singleTrack.title}...'),
              duration: const Duration(seconds: 1),
            ),
          );
        }

        await _audioHandler.playYouTubeSong(singleTrack);
        return SmartPlayResult.playedDirectly();
      }

      // Multiple tracks - navigate to playlist screen
      debugPrint('[SmartPlay] Multi-track album, navigating');

      if (showSnackbars) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlaylistTracksScreen(
            playlistId: playlistId,
            title: song.title,
            knownArtist: song.artist,
            knownThumbnail: song.thumbnailUrl,
            preloadedTracks: tracks,
          ),
        ),
      );

      return SmartPlayResult.navigatedToPlaylist(tracks);
    } catch (e) {
      debugPrint('[SmartPlay] Error: $e');
      _currentlyLoadingPlaylistId = null; // Clear on error

      if (showSnackbars && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }

      return SmartPlayResult.error(e.toString());
    }
  }

  /// Play a song directly without Smart Play resolution.
  /// Use this when you already know it's a single track.
  Future<void> playDirectly(YouTubeSong song) async {
    await _audioHandler.playYouTubeSong(song);
  }
  
  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
  }
}
