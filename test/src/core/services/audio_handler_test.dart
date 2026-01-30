import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:oxide_player/src/core/services/audio_handler.dart';
import 'package:oxide_player/src/core/services/settings_service.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:oxide_player/src/core/services/audio_source_factory.dart';
import 'package:oxide_player/src/core/services/recommendation_service.dart';
import 'package:oxide_player/src/core/services/innertube_service.dart';
import 'package:oxide_player/src/core/services/metadata_matching_service.dart';

import 'package:oxide_player/src/core/services/widget_service.dart';
import 'package:oxide_player/src/core/services/tag_editor_service.dart';

// Mocks
class MockAppDatabase extends Mock implements AppDatabase {}

class MockSettingsService extends Mock implements SettingsService {}

class MockAudioSourceFactory extends Mock implements AudioSourceFactory {}

class MockRecommendationService extends Mock implements RecommendationService {}

class MockInnerTubeService extends Mock implements InnerTubeService {}

class MockMetadataMatchingService extends Mock
    implements MetadataMatchingService {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockWidgetService extends Mock implements WidgetService {}

class MockTagEditorService extends Mock implements TagEditorService {}

// Fakes
class FakeMediaItem extends Fake implements MediaItem {}

class FakeAudioSource extends Fake implements AudioSource {}

void main() {
  late MyAudioHandler audioHandler;
  late MockAppDatabase mockDb;
  late MockSettingsService mockSettings;
  late MockAudioSourceFactory mockAudioSourceFactory;
  late MockRecommendationService mockRecommendationService;
  late MockInnerTubeService mockInnerTubeService;
  late MockMetadataMatchingService mockMetadataMatchingService;

  late MockAudioPlayer mockAudioPlayer;
  late MockWidgetService mockWidgetService;
  late MockTagEditorService mockTagEditorService;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(FakeAudioSource());
  });

  setUp(() {
    // Clear GetIt before each test
    if (GetIt.I.isRegistered<SettingsService>()) {
      GetIt.I.unregister<SettingsService>();
    }

    mockDb = MockAppDatabase();
    mockSettings = MockSettingsService();
    mockAudioSourceFactory = MockAudioSourceFactory();
    mockRecommendationService = MockRecommendationService();
    mockInnerTubeService = MockInnerTubeService();
    mockMetadataMatchingService = MockMetadataMatchingService();

    mockAudioPlayer = MockAudioPlayer();
    mockWidgetService = MockWidgetService();
    mockTagEditorService = MockTagEditorService();

    // Register mock SettingsService in GetIt for equalizer init
    GetIt.I.registerSingleton<SettingsService>(mockSettings);

    // Setup default behaviors for Settings
    when(() => mockSettings.loadQueue()).thenReturn([]);
    when(() => mockSettings.loadLastTrackId()).thenReturn(null);
    when(() => mockSettings.saveLastTrackId(any())).thenAnswer((_) async {});
    when(() => mockSettings.saveLastPosition(any())).thenAnswer((_) async {});
    when(() => mockSettings.saveQueue(any())).thenAnswer((_) async {});

    // Setup WidgetService mock
    when(() => mockWidgetService.init()).thenAnswer((_) async {});
    when(() => mockWidgetService.updateWidget(any())).thenAnswer((_) async {});
    when(() => mockWidgetService.updatePlaybackState(any())).thenAnswer((_) async {});

    // Setup AudioPlayer mocks to prevent crashes during _init
    when(() => mockAudioPlayer.playbackEventStream)
        .thenAnswer((_) => Stream.empty());
    when(() => mockAudioPlayer.shuffleModeEnabledStream)
        .thenAnswer((_) => Stream.empty());
    when(() => mockAudioPlayer.loopModeStream)
        .thenAnswer((_) => Stream.empty());
    when(() => mockAudioPlayer.currentIndexStream)
        .thenAnswer((_) => Stream.empty());
    when(() => mockAudioPlayer.durationStream)
        .thenAnswer((_) => Stream.empty());
    when(() => mockAudioPlayer.icyMetadataStream)
        .thenAnswer((_) => Stream.empty());
    when(() => mockAudioPlayer.positionStream)
        .thenAnswer((_) => Stream.empty());
    when(() => mockAudioPlayer.setAudioSource(any(),
        preload: any(named: 'preload'))).thenAnswer((_) async => null);

    // Add missing property getters used in _broadcastState
    when(() => mockAudioPlayer.playbackEvent).thenReturn(PlaybackEvent());
    when(() => mockAudioPlayer.processingState)
        .thenReturn(ProcessingState.idle);
    when(() => mockAudioPlayer.playing).thenReturn(false);
    when(() => mockAudioPlayer.position).thenReturn(Duration.zero);
    when(() => mockAudioPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(() => mockAudioPlayer.speed).thenReturn(1.0);
    when(() => mockAudioPlayer.loopMode).thenReturn(LoopMode.off);
    when(() => mockAudioPlayer.shuffleModeEnabled).thenReturn(false);

    // We inject the mock player
    audioHandler = MyAudioHandler(
      db: mockDb,
      settingsService: mockSettings,
      audioSourceFactory: mockAudioSourceFactory,
      recommendationService: mockRecommendationService,
      innerTubeService: mockInnerTubeService,
      metadataMatchingService: mockMetadataMatchingService,
      audioPlayer: mockAudioPlayer,
      widgetService: mockWidgetService,
      tagEditorService: mockTagEditorService,
    );
  });

  group('MyAudioHandler Tests', () {
    test('Initialization loads saved state', () async {
      // Arrange
      when(() => mockSettings.loadQueue()).thenReturn(['/path/to/song.mp3']);
    });

    test('addQueueItem adds item to queue', () async {
      final item = MediaItem(id: '1', title: 'Test Song', album: 'Test Album');
      when(() => mockAudioSourceFactory.createSource(item)).thenAnswer(
          (_) async => AudioSource.uri(Uri.parse('http://example.com')));

      await audioHandler.addQueueItem(item);

      expect(audioHandler.queue.value.length, 1);
      expect(audioHandler.queue.value.first, item);
      verify(() => mockAudioSourceFactory.createSource(item)).called(1);
    });

    test('updateQueue replaces queue', () async {
      final item1 = MediaItem(id: '1', title: 'Song 1');
      final item2 = MediaItem(id: '2', title: 'Song 2');
      final queue = [item1, item2];

      when(() => mockAudioSourceFactory.createSource(any())).thenAnswer(
          (_) async => AudioSource.uri(Uri.parse('http://example.com')));

      // Init might have called saveQueue already. Reset mocks.
      verify(() => mockSettings.saveQueue(any())).called(1);
      clearInteractions(mockSettings);

      await audioHandler.updateQueue(queue);

      expect(audioHandler.queue.value.length, 2);
      expect(audioHandler.queue.value, queue);
      verify(() => mockSettings.saveQueue(any())).called(1);
    });

    test('play, pause, stop delegate to player', () async {
      when(() => mockAudioPlayer.play()).thenAnswer((_) async {});
      when(() => mockAudioPlayer.pause()).thenAnswer((_) async {});
      when(() => mockAudioPlayer.stop()).thenAnswer((_) async {});

      await audioHandler.play();
      verify(() => mockAudioPlayer.play()).called(1);

      await audioHandler.pause();
      verify(() => mockAudioPlayer.pause()).called(1);

      await audioHandler.stop();
      verify(() => mockAudioPlayer.stop()).called(1);
    });

    test('skipToNext delegates to player', () async {
      when(() => mockAudioPlayer.seekToNext()).thenAnswer((_) async {});

      await audioHandler.skipToNext();
      verify(() => mockAudioPlayer.seekToNext()).called(1);
    });

    test('skipToPrevious delegates to player', () async {
      when(() => mockAudioPlayer.seekToPrevious()).thenAnswer((_) async {});

      await audioHandler.skipToPrevious();
      verify(() => mockAudioPlayer.seekToPrevious()).called(1);
    });
  });
}
