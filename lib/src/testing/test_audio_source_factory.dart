import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../core/services/audio_source_factory.dart';

class TestAudioSourceFactory extends AudioSourceFactory {
  TestAudioSourceFactory(super.ytHelper, super.cacheService);

  @override
  Future<AudioSource> createSource(MediaItem item) async {
    // Always use bundled asset for test playback to avoid network/file IO.
    return AudioSource.asset('assets/audio/temp.mp3', tag: item);
  }
}
