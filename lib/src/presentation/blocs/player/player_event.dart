part of 'player_bloc.dart';

sealed class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlayerPlay extends PlayerEvent {}

class PlayerPause extends PlayerEvent {}

class PlayerStop extends PlayerEvent {}

class PlayerSeek extends PlayerEvent {
  final Duration position;
  const PlayerSeek(this.position);

  @override
  List<Object> get props => [position];
}

class PlayerSkipNext extends PlayerEvent {}

class PlayerSkipPrevious extends PlayerEvent {}

class PlayerSetShuffleMode extends PlayerEvent {
  final AudioServiceShuffleMode shuffleMode;
  const PlayerSetShuffleMode(this.shuffleMode);

  @override
  List<Object> get props => [shuffleMode];
}

class PlayerSetRepeatMode extends PlayerEvent {
  final AudioServiceRepeatMode repeatMode;
  const PlayerSetRepeatMode(this.repeatMode);

  @override
  List<Object> get props => [repeatMode];
}

class _PlayerStateChanged extends PlayerEvent {
  final PlaybackState? playbackState;
  final MediaItem? mediaItem;
  final Duration? position;
  final Duration? duration;

  const _PlayerStateChanged({
    this.playbackState,
    this.mediaItem,
    this.position,
    this.duration,
  });

  @override
  List<Object?> get props => [playbackState, mediaItem, position, duration];
}
