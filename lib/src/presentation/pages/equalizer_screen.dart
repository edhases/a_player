import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:equalizer_flutter/equalizer_flutter.dart';
import '../../core/services/equalizer_service.dart';
import '../../core/services/audio_handler.dart';
import '../../core/utils/localization.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  EqualizerService? _equalizerService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tryInitEqualizer();
  }

  Future<void> _tryInitEqualizer() async {
    // If already registered, use it
    if (GetIt.I.isRegistered<EqualizerService>()) {
      _equalizerService = GetIt.I<EqualizerService>();
      setState(() => _isLoading = false);
      return;
    }

    // Try to force-init if audio is playing
    try {
      final audioHandler = GetIt.I<MyAudioHandler>();
      final sessionId = audioHandler.audioSessionId;

      debugPrint(
          '[EqualizerScreen] Attempting force-init with sessionId: $sessionId');

      if (sessionId != null && sessionId > 0) {
        final equalizerService = EqualizerService();
        await equalizerService.init(sessionId);
        GetIt.I.registerSingleton<EqualizerService>(equalizerService);
        _equalizerService = equalizerService;
        debugPrint('[EqualizerScreen] EqualizerService force-initialized!');
      }
    } catch (e) {
      debugPrint('[EqualizerScreen] Failed to force-init: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while we try to init
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).equalizer)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If the service isn't ready, offer to open system equalizer
    if (_equalizerService == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).equalizer)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.equalizer, size: 64, color: Colors.white54),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).equalizerActivate,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  '(Start playing a track first)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await EqualizerFlutter.open(0); // 0 = global/system EQ
                    } catch (e) {
                      debugPrint('[Equalizer] Failed to open system EQ: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppLocalizations.of(context)
                                  .serviceNotAvailable)),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(AppLocalizations.of(context).openSystemEqualizer),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Service is ready - show the equalizer UI
    final eq = _equalizerService!;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).equalizer),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: eq.isEnabled,
            builder: (context, isEnabled, child) {
              return Switch(
                value: isEnabled,
                onChanged: (value) {
                  eq.setEnabled(value);
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPresetSelector(eq),
            const SizedBox(height: 24),
            _buildBandSliders(eq),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSelector(EqualizerService eq) {
    return ValueListenableBuilder<String>(
      valueListenable: eq.currentPreset,
      builder: (context, currentPreset, child) {
        return DropdownButtonFormField<String>(
          value: currentPreset,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).preset,
            border: const OutlineInputBorder(),
          ),
          items: eq.presetNames
              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              eq.setPreset(value);
            }
          },
        );
      },
    );
  }

  Widget _buildBandSliders(EqualizerService eq) {
    return ValueListenableBuilder<List<int>>(
      valueListenable: eq.bandLevels,
      builder: (context, bandLevels, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(eq.centerFreqs.length, (index) {
            final freq = eq.centerFreqs[index];
            final level = bandLevels[index];
            return Column(
              children: [
                SizedBox(
                  height: 250,
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: Slider(
                      min: eq.minDecibels.toDouble(),
                      max: eq.maxDecibels.toDouble(),
                      value: level.toDouble(),
                      onChanged: (value) {
                        eq.setBandLevel(index, value.round());
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('${freq ~/ 1000} Hz'),
              ],
            );
          }),
        );
      },
    );
  }
}
