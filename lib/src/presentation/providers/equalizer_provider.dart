import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:oxide_player/main.dart';
import 'package:oxide_player/src/core/services/audio_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EqualizerProvider with ChangeNotifier {
  final MyAudioHandler _audioHandler;
  late SharedPreferences _prefs;

  bool _equalizerEnabled = false;
  bool get equalizerEnabled => _equalizerEnabled;

  List<double> _bandLevels = [];
  List<double> get bandLevels => _bandLevels;

  EqualizerProvider() : _audioHandler = getIt<MyAudioHandler>() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _equalizerEnabled = _prefs.getBool('equalizerEnabled') ?? false;
    _audioHandler.setEqualizerEnabled(_equalizerEnabled);

    final parameters = await _audioHandler.equalizer?.parameters;
    if (parameters != null) {
      _bandLevels = List.generate(
        parameters.bands.length,
        (i) => _prefs.getDouble('band_$i') ?? 0.0,
      );
      for (int i = 0; i < _bandLevels.length; i++) {
        _audioHandler.setBandLevel(i, _bandLevels[i]);
      }
    }
    notifyListeners();
  }

  Future<void> setEqualizerEnabled(bool enabled) async {
    _equalizerEnabled = enabled;
    await _audioHandler.setEqualizerEnabled(enabled);
    await _prefs.setBool('equalizerEnabled', enabled);
    notifyListeners();
  }

  Future<void> setBandLevel(int bandIndex, double level) async {
    _bandLevels[bandIndex] = level;
    await _audioHandler.setBandLevel(bandIndex, level);
    await _prefs.setDouble('band_$bandIndex', level);
    notifyListeners();
  }
}
