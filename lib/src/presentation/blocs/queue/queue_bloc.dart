import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc_status.dart';
import '../../../core/services/audio_handler.dart';

part 'queue_event.dart';
part 'queue_state.dart';

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final MyAudioHandler _audioHandler;
  StreamSubscription? _queueSubscription;

  QueueBloc({required MyAudioHandler audioHandler})
      : _audioHandler = audioHandler,
        super(const QueueState()) {
    on<QueueLoad>(_onLoad);
    on<QueueAddTrack>(_onAddTrack);
    on<QueueRemoveTrack>(_onRemoveTrack);
    on<QueueReorder>(_onReorder);
    on<QueueClear>(_onClear);
    on<_QueueStateChanged>(_onQueueStateChanged);

    _initSubscriptions();
  }

  void _initSubscriptions() {
    _queueSubscription = _audioHandler.queue.listen((queue) {
      add(_QueueStateChanged(queue));
    });
  }

  Future<void> _onLoad(QueueLoad event, Emitter<QueueState> emit) async {
    await _audioHandler.updateQueue(event.queue);
  }

  Future<void> _onAddTrack(
      QueueAddTrack event, Emitter<QueueState> emit) async {
    await _audioHandler.addQueueItem(event.track);
  }

  Future<void> _onRemoveTrack(
      QueueRemoveTrack event, Emitter<QueueState> emit) async {
    await _audioHandler.removeQueueItemAt(event.index);
  }

  Future<void> _onReorder(QueueReorder event, Emitter<QueueState> emit) async {
    // Use efficient O(1) move operation instead of rebuilding entire queue
    await _audioHandler.moveQueueItem(event.oldIndex, event.newIndex);
  }

  Future<void> _onClear(QueueClear event, Emitter<QueueState> emit) async {
    // updateQueue with empty list
    await _audioHandler.updateQueue([]);
    await _audioHandler.stop(); // Usually clearing queue stops playback
  }

  void _onQueueStateChanged(
      _QueueStateChanged event, Emitter<QueueState> emit) {
    emit(state.copyWith(
      status: QueueStatus.success,
      queue: event.queue,
    ));
  }

  @override
  Future<void> close() {
    _queueSubscription?.cancel();
    return super.close();
  }
}
