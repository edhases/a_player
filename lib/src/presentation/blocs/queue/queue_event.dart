part of 'queue_bloc.dart';

sealed class QueueEvent extends Equatable {
  const QueueEvent();

  @override
  List<Object?> get props => [];
}

class QueueLoad extends QueueEvent {
  final List<MediaItem> queue;
  const QueueLoad(this.queue);

  @override
  List<Object> get props => [queue];
}

class QueueAddTrack extends QueueEvent {
  final MediaItem track;
  const QueueAddTrack(this.track);

  @override
  List<Object> get props => [track];
}

class QueueRemoveTrack extends QueueEvent {
  final int index;
  const QueueRemoveTrack(this.index);

  @override
  List<Object> get props => [index];
}

class QueueReorder extends QueueEvent {
  final int oldIndex;
  final int newIndex;
  const QueueReorder(this.oldIndex, this.newIndex);

  @override
  List<Object> get props => [oldIndex, newIndex];
}

class QueueClear extends QueueEvent {}

class _QueueStateChanged extends QueueEvent {
  final List<MediaItem> queue;
  const _QueueStateChanged(this.queue);

  @override
  List<Object> get props => [queue];
}
