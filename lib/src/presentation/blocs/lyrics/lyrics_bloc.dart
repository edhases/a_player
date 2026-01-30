import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:audio_service/audio_service.dart';
import '../../../core/models/lyrics_model.dart';
import '../../../core/services/lyrics_service.dart';
import '../../../core/services/audio_handler.dart';

// Events
abstract class LyricsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchLyrics extends LyricsEvent {
  final MediaItem mediaItem;
  FetchLyrics(this.mediaItem);

  @override
  List<Object?> get props => [mediaItem];
}

class _LyricsPrefetched extends LyricsEvent {
  final LyricsModel? lyrics;
  final String trackId;
  _LyricsPrefetched(this.lyrics, this.trackId);
}

// State
abstract class LyricsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LyricsInitial extends LyricsState {}

class LyricsLoading extends LyricsState {}

class LyricsLoaded extends LyricsState {
  final LyricsModel lyrics;
  LyricsLoaded(this.lyrics);

  @override
  List<Object?> get props => [lyrics];
}

class LyricsNotFound extends LyricsState {}

class LyricsError extends LyricsState {
  final String message;
  LyricsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class LyricsBloc extends Bloc<LyricsEvent, LyricsState> {
  final LyricsService _lyricsService;
  final MyAudioHandler? _audioHandler;
  StreamSubscription? _mediaItemSubscription;

  // Track currently prefetching track
  String? _currentTrackId;

  LyricsBloc(this._lyricsService, [this._audioHandler])
      : super(LyricsInitial()) {
    on<FetchLyrics>(_onFetchLyrics);
    on<_LyricsPrefetched>(_onLyricsPrefetched);

    // Subscribe to mediaItem changes for prefetching
    _initPrefetch();
  }

  void _initPrefetch() {
    if (_audioHandler == null) return;

    _mediaItemSubscription = _audioHandler!.mediaItem.listen((item) {
      if (item != null) {
        _prefetchLyricsForItem(item);
      }
    });
  }

  Future<void> _prefetchLyricsForItem(MediaItem item) async {
    final trackId = item.id;

    // Skip if already prefetching this track
    if (_currentTrackId == trackId) return;
    _currentTrackId = trackId;

    // Check cache first - if cached, nothing to do
    if (_lyricsService.hasCachedLyrics(item.title, item.artist ?? '')) {
      return;
    }

    // Prefetch in background (fire-and-forget)
    _lyricsService.prefetchLyrics(
      trackName: item.title,
      artistName: item.artist ?? '',
      albumName: item.album ?? '',
      duration: item.duration?.inSeconds.toDouble() ?? 0,
      videoId: item.extras?['isOnline'] == true ? item.id : null,
    );
  }

  void _onLyricsPrefetched(_LyricsPrefetched event, Emitter<LyricsState> emit) {
    // Prefetch event is handled - lyrics are already cached in service
  }

  Future<void> _onFetchLyrics(
      FetchLyrics event, Emitter<LyricsState> emit) async {
    final item = event.mediaItem;

    // Check if we have prefetched lyrics for this track
    final cachedLyrics = _lyricsService.getCachedLyrics(
      item.title,
      item.artist ?? '',
    );

    if (cachedLyrics != null) {
      emit(LyricsLoaded(cachedLyrics));
      return;
    }

    // Not cached, fetch now
    emit(LyricsLoading());

    try {
      final lyrics = await _lyricsService.getLyrics(
        trackName: item.title,
        artistName: item.artist ?? '',
        albumName: item.album ?? '',
        duration: item.duration?.inSeconds.toDouble() ?? 0,
        videoId: item.extras?['isOnline'] == true ? item.id : null,
      );

      if (lyrics != null) {
        emit(LyricsLoaded(lyrics));
      } else {
        emit(LyricsNotFound());
      }
    } catch (e) {
      emit(LyricsError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _mediaItemSubscription?.cancel();
    return super.close();
  }
}
