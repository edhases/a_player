import 'package:flutter/material.dart';
import 'package:equalizer_flutter/equalizer_flutter.dart';
import 'package:get_it/get_it.dart';
import 'dart:convert';
import 'settings_service.dart';

const String kEqEnabledKey = 'eq_enabled';
const String kEqPresetKey = 'eq_preset';
const String kEqCustomLevelsKey = 'eq_custom_levels';

class EqualizerService {
  final _settingsService = GetIt.I<SettingsService>();

  // Notifiers for UI reactivity
  final ValueNotifier<bool> isEnabled = ValueNotifier(false);
  final ValueNotifier<String> currentPreset = ValueNotifier('Custom');
  final ValueNotifier<List<int>> bandLevels = ValueNotifier([]);

  List<String> presetNames = ['Custom'];
  List<int> centerFreqs = [];
  int minDecibels = -15;
  int maxDecibels = 15;

  Future<void> init(int audioSessionId) async {
    await EqualizerFlutter.init(audioSessionId);

    // Load initial settings from storage
    isEnabled.value = _settingsService.loadBool(kEqEnabledKey) ?? false;
    currentPreset.value = _settingsService.loadString(kEqPresetKey) ?? 'Custom';

    // Fetch device EQ capabilities
    final bandLevelRange = await EqualizerFlutter.getBandLevelRange();
    minDecibels = bandLevelRange[0];
    maxDecibels = bandLevelRange[1];

    centerFreqs = await EqualizerFlutter.getCenterBandFreqs();
    bandLevels.value = List.filled(centerFreqs.length, 0);

    presetNames.addAll(await EqualizerFlutter.getPresetNames());

    // Apply saved settings
    await setEnabled(isEnabled.value);
    if (currentPreset.value == 'Custom') {
      final customLevelsJson = _settingsService.loadString(kEqCustomLevelsKey);
      if (customLevelsJson != null) {
        final customLevels = (jsonDecode(customLevelsJson) as List).cast<int>();
        for (int i = 0; i < customLevels.length; i++) {
          await setBandLevel(i, customLevels[i]);
        }
      }
    } else {
      await EqualizerFlutter.setPreset(currentPreset.value);
    }
    _updateBandLevelsFromDevice();
  }

  Future<void> setEnabled(bool enabled) async {
    isEnabled.value = enabled;
    await EqualizerFlutter.setEnabled(enabled);
    await _settingsService.saveBool(kEqEnabledKey, enabled);
  }

  Future<void> setBandLevel(int bandId, int level) async {
    bandLevels.value[bandId] = level;
    await EqualizerFlutter.setBandLevel(bandId, level);

    // If we change a band, it's a custom preset
    currentPreset.value = 'Custom';
    await _settingsService.saveString(kEqPresetKey, 'Custom');
    await _saveCustomLevels();

    // Force a redraw
    bandLevels.value = List.from(bandLevels.value);
  }

  Future<void> setPreset(String preset) async {
    currentPreset.value = preset;
    await EqualizerFlutter.setPreset(preset);
    await _settingsService.saveString(kEqPresetKey, preset);
    await _updateBandLevelsFromDevice();
  }

  Future<void> _updateBandLevelsFromDevice() async {
    final newLevels = <int>[];
    for (int i = 0; i < centerFreqs.length; i++) {
      newLevels.add(await EqualizerFlutter.getBandLevel(i));
    }
    bandLevels.value = newLevels;
  }

  Future<void> _saveCustomLevels() async {
    await _settingsService.saveString(kEqCustomLevelsKey, jsonEncode(bandLevels.value));
  }

  void dispose() {
    EqualizerFlutter.release();
  }
}
