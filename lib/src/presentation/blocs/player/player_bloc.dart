import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc_status.dart';
import '../../../core/services/audio_handler.dart';

part 'player_event.dart';
part 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final MyAudioHandler _audioHandler;
  StreamSubscription? _playbackStateSubscription;
  StreamSubscription? _mediaItemSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  PlayerBloc({required MyAudioHandler audioHandler})
      : _audioHandler = audioHandler,
        super(const PlayerState()) {
    on<PlayerPlay>(_onPlay);
    on<PlayerPause>(_onPause);
    on<PlayerStop>(_onStop);
    on<PlayerSeek>(_onSeek);
    on<PlayerSkipNext>(_onSkipNext);
    on<PlayerSkipPrevious>(_onSkipPrevious);
    on<PlayerSetShuffleMode>(_onSetShuffleMode);
    on<PlayerSetRepeatMode>(_onSetRepeatMode);
    on<_PlayerStateChanged>(_onPlayerStateChanged);

    _initSubscriptions();
  }

  void _initSubscriptions() {
    _playbackStateSubscription = _audioHandler.playbackState.listen((state) {
      add(_PlayerStateChanged(playbackState: state));
    });

    _mediaItemSubscription = _audioHandler.mediaItem.listen((item) {
      add(_PlayerStateChanged(mediaItem: item));
    });

    // We rely on playbackState.position for snapshots
  }

  Future<void> _onPlay(PlayerPlay event, Emitter<PlayerState> emit) async {
    await _audioHandler.play();
  }

  Future<void> _onPause(PlayerPause event, Emitter<PlayerState> emit) async {
    await _audioHandler.pause();
  }

  Future<void> _onStop(PlayerStop event, Emitter<PlayerState> emit) async {
    await _audioHandler.stop();
  }

  Future<void> _onSeek(PlayerSeek event, Emitter<PlayerState> emit) async {
    await _audioHandler.seek(event.position);
  }

  Future<void> _onSkipNext(
      PlayerSkipNext event, Emitter<PlayerState> emit) async {
    await _audioHandler.skipToNext();
  }

  Future<void> _onSkipPrevious(
      PlayerSkipPrevious event, Emitter<PlayerState> emit) async {
    await _audioHandler.skipToPrevious();
  }

  Future<void> _onSetShuffleMode(
      PlayerSetShuffleMode event, Emitter<PlayerState> emit) async {
    await _audioHandler.setShuffleMode(event.shuffleMode);
  }

  Future<void> _onSetRepeatMode(
      PlayerSetRepeatMode event, Emitter<PlayerState> emit) async {
    await _audioHandler.setRepeatMode(event.repeatMode);
  }

  void _onPlayerStateChanged(
      _PlayerStateChanged event, Emitter<PlayerState> emit) {
    if (event.playbackState != null) {
      final playbackState = event.playbackState!;

      // Determine processing state
      AudioProcessingState processingState = AudioProcessingState.idle;
      // map from AudioService processing state
      if (playbackState.processingState == AudioProcessingState.idle) {
        processingState = AudioProcessingState.idle;
      } else if (playbackState.processingState ==
          AudioProcessingState.loading) {
        processingState = AudioProcessingState.loading;
      } else if (playbackState.processingState ==
          AudioProcessingState.buffering) {
        processingState = AudioProcessingState.buffering;
      } else if (playbackState.processingState == AudioProcessingState.ready) {
        processingState = AudioProcessingState.ready;
      } else if (playbackState.processingState ==
          AudioProcessingState.completed) {
        processingState = AudioProcessingState.completed;
      }

      emit(state.copyWith(
        status: PlayerStatus.success,
        isPlaying: playbackState.playing,
        processingState: processingState,
        shuffleMode: playbackState.shuffleMode,
        repeatMode: playbackState.repeatMode,
        position: playbackState.updatePosition,
      ));
    }

    if (event.mediaItem != null) {
      final item = event.mediaItem!;
      emit(state.copyWith(
        mediaItem: item,
        duration: item.duration ?? Duration.zero,
      ));
    }
  }

  @override
  Future<void> close() {
    _playbackStateSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    return super.close();
  }

  Stream<Duration> get positionStream => _audioHandler.player.positionStream;
  Stream<Duration?> get durationStream =>
      _audioHandler.mediaItem.map((item) => item?.duration);
}
