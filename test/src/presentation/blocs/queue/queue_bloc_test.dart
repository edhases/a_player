import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:oxide_player/src/presentation/blocs/queue/queue_bloc.dart';
import 'package:oxide_player/src/core/services/audio_handler.dart';

// Mock Classes
class MockAudioHandler extends Mock implements MyAudioHandler {}

void main() {
  late QueueBloc queueBloc;
  late MockAudioHandler mockAudioHandler;

  // Test Data
  final mediaItem1 = MediaItem(id: '1', title: 'Track 1');
  final mediaItem2 = MediaItem(id: '2', title: 'Track 2');
  final mediaItem3 = MediaItem(id: '3', title: 'Track 3');

  setUp(() {
    mockAudioHandler = MockAudioHandler();

    // Default stream behavior
    when(() => mockAudioHandler.queue)
        .thenAnswer((_) => BehaviorSubject<List<MediaItem>>.seeded([]));

    queueBloc = QueueBloc(audioHandler: mockAudioHandler);
  });

  tearDown(() {
    queueBloc.close();
  });

  group('QueueBloc Tests', () {
    test('Initial state is empty', () {
      expect(queueBloc.state.queue, isEmpty);
      expect(queueBloc.state.status, QueueStatus.success);
    });

    blocTest<QueueBloc, QueueState>(
      'QueueLoad updates audio handler',
      build: () {
        when(() => mockAudioHandler.updateQueue(any()))
            .thenAnswer((_) async {});
        return queueBloc;
      },
      act: (bloc) => bloc.add(QueueLoad([mediaItem1, mediaItem2])),
      verify: (_) {
        verify(() => mockAudioHandler.updateQueue([mediaItem1, mediaItem2]))
            .called(1);
      },
    );

    blocTest<QueueBloc, QueueState>(
      'QueueReorder calls moveQueueItem on audio handler',
      build: () {
        when(() => mockAudioHandler.moveQueueItem(any(), any()))
            .thenAnswer((_) async {});
        return queueBloc;
      },
      act: (bloc) => bloc.add(const QueueReorder(0, 2)),
      verify: (_) {
        // Verify O(1) move method is called, NOT updateQueue with broken list
        verify(() => mockAudioHandler.moveQueueItem(0, 2)).called(1);
        verifyNever(() => mockAudioHandler.updateQueue(any()));
      },
    );

    blocTest<QueueBloc, QueueState>(
      'QueueClear calls updateQueue with empty list',
      build: () {
        when(() => mockAudioHandler.updateQueue(any()))
            .thenAnswer((_) async {});
        when(() => mockAudioHandler.stop()).thenAnswer((_) async {});
        return queueBloc;
      },
      act: (bloc) => bloc.add(QueueClear()),
      verify: (_) {
        verify(() => mockAudioHandler.updateQueue([])).called(1);
        verify(() => mockAudioHandler.stop()).called(1);
      },
    );
  });
}
