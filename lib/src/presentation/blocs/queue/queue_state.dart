part of 'queue_bloc.dart';

enum QueueStatus { initial, loading, success, failure }

class QueueState extends Equatable {
  final QueueStatus status;
  final List<MediaItem> queue;

  const QueueState({
    this.status = QueueStatus.initial,
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
