import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'dart:convert';
import 'settings_service.dart';

const String kEqEnabledKey = 'eq_enabled';
const String kEqPresetKey = 'eq_preset';
const String kEqCustomLevelsKey = 'eq_custom_levels';

class EqualizerService {
  final _settingsService = GetIt.I<SettingsService>();

  // The just_audio wrapper for Android Equalizer
  AndroidEqualizer? _androidEqualizer;

  // Notifiers for UI reactivity
  final ValueNotifier<bool> isEnabled = ValueNotifier(false);
  final ValueNotifier<String> currentPreset = ValueNotifier('Custom');
  final ValueNotifier<List<double>> bandLevels = ValueNotifier([]);

  List<String> presetNames = [
    'Custom',
    'Flat',
    'Pop',
    'Rock',
    'Punk',
    'Dubstep',
    'Phonk',
    'Jazz',
    'Classical',
    'Metal',
    'Hip-Hop'
  ];
  List<int> centerFreqs = [];
  double minDecibels = -15.0;
  double maxDecibels = 15.0;

  bool get isInitialized => _androidEqualizer != null;

  /// Initialize using the AudioPipeline logic
  /// Note: just_audio's AndroidEqualizer is usually part of the AudioPipeline.
  /// We need to create it and pass it to the player's pipeline.
  /// However, if we are attaching to an existing session, we might need to construct it differently.
  /// just_audio usually constructs it linked to a module ID.
  ///
  /// ACTUALLY: just_audio 0.9.x allows creating AndroidEqualizer() standalone?
  /// No, it's typically part of AndroidAudioPipeline.
  /// But wait, we can create it if we provide the parameters?
  /// Use `AndroidEqualizer` constructor.
  Future<void> init(AndroidEqualizer equalizer) async {
    _androidEqualizer = equalizer;

    // Load initial settings
    isEnabled.value = _settingsService.loadBool(kEqEnabledKey) ?? false;
    currentPreset.value = _settingsService.loadString(kEqPresetKey) ?? 'Custom';

    // Get parameters
    final parameters = await equalizer.parameters;
    minDecibels = parameters.minDecibels;
    maxDecibels = parameters.maxDecibels;

    // Bands
    centerFreqs =
        parameters.bands.map((b) => b.centerFrequency.toInt()).toList();

    // Check initial values
    bandLevels.value = parameters.bands.map((b) => b.gain).toList();

    // Presets (AndroidEqualizer doesn't expose presets API directly in the specific wrapper??)
    // The wrapper exposes `activiePreset`?
    // Let's check parameters.presets
    // Ah, parameters might not expose presets list directly in all versions, or it does.
    // Assuming it does map presets.
    /*
      Actually, looking at just_audio source behaves differently.
      Safe bet: We implement 'Custom' manually by controlling gains.
      If presets are available in parameters, we use them.
    */
    // We will simulate presets for now or check if we can fetch them.
    // Simplify: Just support manual bands for now (Custom).

    // Apply saved
    await setEnabled(isEnabled.value);

    // Apply levels
    if (currentPreset.value == 'Custom') {
      final customLevelsJson = _settingsService.loadString(kEqCustomLevelsKey);
      if (customLevelsJson != null) {
        final customLevels =
            (jsonDecode(customLevelsJson) as List).cast<double>();
        for (int i = 0;
            i < customLevels.length && i < centerFreqs.length;
            i++) {
          await setBandGain(i, customLevels[i]);
        }
      }
    } else {
      // Re-apply the named preset to ensure bands are set
      await setPreset(currentPreset.value);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    isEnabled.value = enabled;
    await _androidEqualizer?.setEnabled(enabled);
    await _settingsService.saveBool(kEqEnabledKey, enabled);
  }

  Future<void> setBandGain(int bandIndex, double gain) async {
    if (_androidEqualizer == null) return;

    // Clamp
    if (gain < minDecibels) gain = minDecibels;
    if (gain > maxDecibels) gain = maxDecibels;

    final levels = List<double>.from(bandLevels.value);
    if (bandIndex < levels.length) {
      levels[bandIndex] = gain;
      bandLevels.value = levels;

      // Apply to effect
      final parameters = await _androidEqualizer!.parameters;
      await parameters.bands[bandIndex].setGain(gain);
    }

    // Save as custom
    if (currentPreset.value != 'Custom') {
      currentPreset.value = 'Custom';
      await _settingsService.saveString(kEqPresetKey, 'Custom');
    }
    await _saveCustomLevels();
  }

  // Presets definition (5 bands: Low, Low-Mid, Mid, High-Mid, High)
  // Values are relative gains in dB.
  static const Map<String, List<double>> _presetDefinitions = {
    'Flat': [0, 0, 0, 0, 0],
    'Pop': [3, 2, 0, 2, 4],
    'Rock': [4, 3, -1, 3, 5],
    'Punk': [5, 3, 0, 4, 5],
    'Dubstep': [8, 5, 0, 3, 5],
    'Phonk': [9, 6, 2, 4, 6],
    'Jazz': [3, 2, -1, 2, 4],
    'Classical': [4, 3, 0, 3, 4],
    'Metal': [5, 2, -2, 4, 6],
    'Hip-Hop': [6, 4, -1, 2, 4],
  };

  Future<void> setPreset(String preset) async {
    if (!_presetDefinitions.containsKey(preset)) return;

    final targetLevels = _presetDefinitions[preset]!;

    // Safety check: ensure we have bands
    if (centerFreqs.isEmpty) return;

    // Map the 5-point preset to the actual number of bands
    // Most Android devices have 5 bands, so this is 1:1.
    // If different, we do a simple mapping.
    for (int i = 0; i < centerFreqs.length; i++) {
      double targetGain;
      if (centerFreqs.length == 5) {
        targetGain = targetLevels[i];
      } else {
        // Simple interpolation logic
        // 0 -> 0%
        // i -> (i / (total-1)) %
        final percent = i / (centerFreqs.length - 1);
        // Map percent to index in targetLevels (0..4)
        final targetIndexExact = percent * (targetLevels.length - 1);
        final lowerIndex = targetIndexExact.floor();
        final upperIndex = targetIndexExact.ceil();
        final fraction = targetIndexExact - lowerIndex;

        final lowerVal = targetLevels[lowerIndex];
        final upperVal = targetLevels[upperIndex];

        targetGain = lowerVal + (upperVal - lowerVal) * fraction;
      }

      // We set bands directly here but updating 'bandLevels' notifier is crucial
      // We also update the device equalizer.
      // NOTE: We call a private helper to avoid triggering 'Custom' switch logic
      await _applyGainToBand(i, targetGain);
    }

    // Update local state and persistence
    currentPreset.value = preset;
    await _settingsService.saveString(kEqPresetKey, preset);

    // Update notifier with new values so UI slider moves
    final newLevels = <double>[];
    if (centerFreqs.length == 5) {
      newLevels.addAll(targetLevels);
    } else {
      // Re-calculate for notifier
      for (int i = 0; i < centerFreqs.length; i++) {
        final percent = i / (centerFreqs.length - 1);
        final targetIndexExact = percent * (targetLevels.length - 1);
        final lowerIndex = targetIndexExact.floor();
        final upperIndex = targetIndexExact.ceil();
        final fraction = targetIndexExact - lowerIndex;
        newLevels.add(targetLevels[lowerIndex] +
            (targetLevels[upperIndex] - targetLevels[lowerIndex]) * fraction);
      }
    }
    bandLevels.value = newLevels;
  }

  /// Helper to set gain without changing preset to 'Custom'
  Future<void> _applyGainToBand(int bandIndex, double gain) async {
    if (_androidEqualizer == null) return;

    // Clamp
    if (gain < minDecibels) gain = minDecibels;
    if (gain > maxDecibels) gain = maxDecibels;

    final parameters = await _androidEqualizer!.parameters;
    await parameters.bands[bandIndex].setGain(gain);
  }

  Future<void> _saveCustomLevels() async {
    await _settingsService.saveString(
        kEqCustomLevelsKey, jsonEncode(bandLevels.value));
  }

  void dispose() {
    // _androidEqualizer is owned by player pipeline usually, don't dispose it here?
  }
}
