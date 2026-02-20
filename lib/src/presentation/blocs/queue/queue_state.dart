part of 'queue_bloc.dart';

/// @deprecated Use [BlocStatus] instead
typedef QueueStatus = BlocStatus;

class QueueState extends Equatable {
  final BlocStatus status;
  final List<MediaItem> queue;

  const QueueState({
    this.status = BlocStatus.initial,
    this.queue = const [],
  });

  QueueState copyWith({
    QueueStatus? status,
    List<MediaItem>? queue,
  }) {
    return QueueState(
      status: status ?? this.status,
      queue: queue ?? this.queue,
    );
  }

  @override
  List<Object?> get props => [status, queue];
}
