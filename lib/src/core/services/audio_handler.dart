import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/datasources/app_database.dart';
import 'settings_service.dart';
import 'equalizer_service.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  final _settingsService = GetIt.I<SettingsService>();
  final AppDatabase _db;

  StreamSubscription<int?>? _audioSessionIdSubscription;

  MyAudioHandler(this._db) {
    _init();
  }

  Future<void> _init() async {
    _audioSessionIdSubscription = player.androidAudioSessionIdStream.listen((sessionId) {
      if (sessionId != null) {
        _initEqualizer(sessionId);
      }
    });

    player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    mediaItem.stream.listen((item) {
      if (item != null) {
        _settingsService.saveLastTrackId(item.id);
      }
    });

    player.positionStream
      .debounceTime(const Duration(seconds: 5))
      .listen((position) {
        _settingsService.saveLastPosition(position);
    });

    queue.stream.listen((q) {
      final trackIds = q.map((item) => item.id).toList();
      _settingsService.saveQueue(trackIds);
    });

    await _loadInitialState();

    await player.setAudioSource(_playlist, preload: false);
  }

  Future<void> _initEqualizer(int sessionId) async {
    if (GetIt.I.isRegistered<EqualizerService>()) return;

    final equalizerService = EqualizerService();
    await equalizerService.init(sessionId);
    GetIt.I.registerSingleton<EqualizerService>(equalizerService);
  }

  Future<void> _loadInitialState() async {
    // ... (logic is the same)
  }

  // ... (rest of the methods are the same)

  @override
  Future<void> stop() async {
    if (GetIt.I.isRegistered<EqualizerService>()) {
      GetIt.I<EqualizerService>().dispose();
      GetIt.I.unregister<EqualizerService>();
    }
    _audioSessionIdSubscription?.cancel();
    await player.stop();
    await super.stop();
  }
}
