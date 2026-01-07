import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';

// Keys for storing settings
const String kShuffleModeKey = 'shuffle_mode';
const String kRepeatModeKey = 'repeat_mode';
const String kLastTrackIdKey = 'last_track_id';
const String kLastPositionKey = 'last_position';
const String kQueueKey = 'queue';

class SettingsService {
  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Shuffle Mode ---
  Future<void> saveShuffleMode(AudioServiceShuffleMode mode) async {
    await _prefs.setInt(kShuffleModeKey, mode.index);
  }

  AudioServiceShuffleMode loadShuffleMode() {
    final index = _prefs.getInt(kShuffleModeKey) ?? 0;
    return AudioServiceShuffleMode.values[index];
  }

  // --- Repeat Mode ---
  Future<void> saveRepeatMode(AudioServiceRepeatMode mode) async {
    await _prefs.setInt(kRepeatModeKey, mode.index);
  }

  AudioServiceRepeatMode loadRepeatMode() {
    final index = _prefs.getInt(kRepeatModeKey) ?? 0;
    return AudioServiceRepeatMode.values[index];
  }

  // --- Last Track ID ---
  Future<void> saveLastTrackId(String id) async {
    await _prefs.setString(kLastTrackIdKey, id);
  }

  String? loadLastTrackId() {
    return _prefs.getString(kLastTrackIdKey);
  }

  // --- Last Position ---
  Future<void> saveLastPosition(Duration position) async {
    await _prefs.setInt(kLastPositionKey, position.inMilliseconds);
  }

  Duration loadLastPosition() {
    final milliseconds = _prefs.getInt(kLastPositionKey) ?? 0;
    return Duration(milliseconds: milliseconds);
  }

  // --- Queue ---
  // Note: Storing a complex queue in SharedPreferences is simplistic.
  // For a real app, a database or a more robust serialization is better.
  Future<void> saveQueue(List<String> trackIds) async {
    await _prefs.setStringList(kQueueKey, trackIds);
  }

  List<String> loadQueue() {
    return _prefs.getStringList(kQueueKey) ?? [];
  }

  // --- Generic Storage ---
  bool? loadBool(String key) => _prefs.getBool(key);
  Future<void> saveBool(String key, bool value) => _prefs.setBool(key, value);
  
  String? loadString(String key) => _prefs.getString(key);
  Future<void> saveString(String key, String value) => _prefs.setString(key, value);
}
