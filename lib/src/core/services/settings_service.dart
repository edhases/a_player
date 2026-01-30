import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:async'; // Add async import

// Keys for storing settings
const String kShuffleModeKey = 'shuffle_mode';
const String kRepeatModeKey = 'repeat_mode';
const String kLastTrackIdKey = 'last_track_id';
const String kLastPositionKey = 'last_position';

const String kQueueKey = 'queue';
const String kMinTrackDurationKey = 'min_track_duration'; // in seconds
const String kMaxTrackDurationKey =
    'max_track_duration'; // in seconds (0 = no limit)
const String kMaxCacheSizeKey = 'max_cache_size';
const String kAutoCacheLikedKey = 'auto_cache_liked';
const String kExcludedFoldersKey = 'excluded_folders';
const String kMaxLogSizeKey = 'max_log_size'; // in bytes
const String kSaveMetadataToFileKey = 'save_metadata_to_file';

class SettingsService {
  late final SharedPreferences _prefs;
  final _settingsController = StreamController<void>.broadcast();
  Stream<void> get onSettingsChanged => _settingsController.stream;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _notify() => _settingsController.add(null);

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

  // --- Library Filters ---

  Future<void> saveSaveMetadataToFile(bool enabled) async {
    await _prefs.setBool(kSaveMetadataToFileKey, enabled);
    _notify();
  }

  bool loadSaveMetadataToFile() {
    return _prefs.getBool(kSaveMetadataToFileKey) ?? true;
  }

  // Min Duration in Seconds (default 30s to skip notifications)
  Future<void> saveMinTrackDuration(int seconds) async {
    await _prefs.setInt(kMinTrackDurationKey, seconds);
    _notify();
  }

  int loadMinTrackDuration() {
    return _prefs.getInt(kMinTrackDurationKey) ?? 30; // Default 30s
  }

  // Max Duration in Seconds (default 0 = unlimited)
  Future<void> saveMaxTrackDuration(int seconds) async {
    await _prefs.setInt(kMaxTrackDurationKey, seconds);
    _notify();
  }

  int loadMaxTrackDuration() {
    return _prefs.getInt(kMaxTrackDurationKey) ?? 0;
  }

  // Excluded Folders
  Future<void> addExcludedFolder(String path) async {
    final current = loadExcludedFolders();
    if (!current.contains(path)) {
      current.add(path);
      await _prefs.setStringList(kExcludedFoldersKey, current);
      _notify(); // Notify
    }
  }

  Future<void> removeExcludedFolder(String path) async {
    final current = loadExcludedFolders();
    if (current.contains(path)) {
      current.remove(path);
      await _prefs.setStringList(kExcludedFoldersKey, current);
      _notify(); // Notify
    }
  }

  List<String> loadExcludedFolders() {
    return _prefs.getStringList(kExcludedFoldersKey) ?? [];
  }

  Future<void> saveExcludedFolders(List<String> paths) async {
    await _prefs.setStringList(kExcludedFoldersKey, paths);
    _notify();
  }

  // --- Cache Limit ---
  Future<void> saveMaxCacheSize(int bytes) async {
    await _prefs.setInt(kMaxCacheSizeKey, bytes);
    _notify();
  }

  int loadMaxCacheSize() {
    return _prefs.getInt(kMaxCacheSizeKey) ??
        500 * 1024 * 1024; // Default 500MB
  }

  // --- Auto Cache Liked Songs ---
  Future<void> saveAutoCacheLiked(bool enabled) async {
    await _prefs.setBool(kAutoCacheLikedKey, enabled);
    _notify();
  }

  bool loadAutoCacheLiked() {
    return _prefs.getBool(kAutoCacheLikedKey) ?? true; // Default enabled
  }

  // --- Log Size ---
  Future<void> saveMaxLogSize(int bytes) async {
    await _prefs.setInt(kMaxLogSizeKey, bytes);
    _notify();
  }

  int loadMaxLogSize() {
    // Default 10MB
    return _prefs.getInt(kMaxLogSizeKey) ?? 10 * 1024 * 1024;
  }

  // --- Appearance ---
  Future<void> saveThemeMode(int mode) async {
    await _prefs.setInt('theme_mode', mode);
    _notify();
  }

  int loadThemeMode() {
    return _prefs.getInt('theme_mode') ?? 0; // 0 = System
  }

  Future<void> saveAmoledMode(bool enabled) async {
    await _prefs.setBool('amoled_mode', enabled);
    _notify();
  }

  bool loadAmoledMode() {
    return _prefs.getBool('amoled_mode') ?? false;
  }

  Future<void> saveAccentColor(int colorValue) async {
    await _prefs.setInt('accent_color', colorValue);
    _notify();
  }

  int? loadAccentColor() {
    return _prefs.getInt('accent_color');
  }

  Future<void> saveFontSizeScale(double scale) async {
    await _prefs.setDouble('font_scale', scale);
    _notify();
  }

  double loadFontSizeScale() {
    return _prefs.getDouble('font_scale') ?? 1.0;
  }

  // --- Playback ---
  Future<void> saveCrossfadeDuration(int seconds) async {
    await _prefs.setInt('crossfade_duration', seconds);
    _notify();
  }

  int loadCrossfadeDuration() {
    return _prefs.getInt('crossfade_duration') ?? 0;
  }

  // --- Network ---
  Future<void> saveWifiOnly(bool enabled) async {
    await _prefs.setBool('wifi_only', enabled);
    _notify();
  }

  bool loadWifiOnly() {
    return _prefs.getBool('wifi_only') ??
        false; // Default false for now to avoid confusion
  }

  // --- Updates ---
  Future<void> saveAutoUpdateEnabled(bool enabled) async {
    await _prefs.setBool('auto_update_enabled', enabled);
    _notify();
  }

  bool loadAutoUpdateEnabled() {
    return _prefs.getBool('auto_update_enabled') ?? true; // Default enabled
  }

  // --- Generic Storage ---
  bool? loadBool(String key) => _prefs.getBool(key);
  Future<void> saveBool(String key, bool value) => _prefs.setBool(key, value);

  String? loadString(String key) => _prefs.getString(key);
  Future<void> saveString(String key, String value) =>
      _prefs.setString(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
}
