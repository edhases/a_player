import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  static const _autoFetchArtworkKey = 'autoFetchArtwork';

  late SharedPreferences _prefs;
  bool _autoFetchArtwork = false;

  bool get autoFetchArtwork => _autoFetchArtwork;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _autoFetchArtwork = _prefs.getBool(_autoFetchArtworkKey) ?? false;
    notifyListeners();
  }

  Future<void> setAutoFetchArtwork(bool value) async {
    _autoFetchArtwork = value;
    await _prefs.setBool(_autoFetchArtworkKey, value);
    notifyListeners();
  }
}
