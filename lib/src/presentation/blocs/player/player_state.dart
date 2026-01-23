part of 'player_bloc.dart';

enum PlayerStatus { initial, loading, success, failure }

class PlayerState extends Equatable {
  final PlayerStatus status;
  final MediaItem? mediaItem;
  final bool isPlaying;
  final AudioProcessingState processingState;
  final Duration position;
  final Duration duration;
  final AudioServiceShuffleMode shuffleMode;
  final AudioServiceRepeatMode repeatMode;

  const PlayerState({
    this.status = PlayerStatus.initial,
    this.mediaItem,
    this.isPlaying = false,
    this.processingState = AudioProcessingState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.shuffleMode = AudioServiceShuffleMode.none,
    this.repeatMode = AudioServiceRepeatMode.none,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    MediaItem? mediaItem,
    bool? isPlaying,
    AudioProcessingState? processingState,
    Duration? position,
    Duration? duration,
    AudioServiceShuffleMode? shuffleMode,
    AudioServiceRepeatMode? repeatMode,
  }) {
    return PlayerState(
      status: status ?? this.status,
      mediaItem: mediaItem ?? this.mediaItem,
      isPlaying: isPlaying ?? this.isPlaying,
      processingState: processingState ?? this.processingState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }

  @override
  List<Object?> get props => [
        status,
        mediaItem,
        isPlaying,
        processingState,
        position,
        duration,
        shuffleMode,
        repeatMode,
      ];
}
