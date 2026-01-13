import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/equalizer_service.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  late final EqualizerService _equalizerService;

  @override
  void initState() {
    super.initState();
    // Attempt to get the service. It might not be ready if the audio session hasn't started.
    if (GetIt.I.isRegistered<EqualizerService>()) {
      _equalizerService = GetIt.I<EqualizerService>();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the service isn't ready, show a message.
    if (!GetIt.I.isRegistered<EqualizerService>()) {
      return Scaffold(
        appBar: AppBar(title: const Text('Equalizer')),
        body: const Center(
          child: Text('Play a track to activate the equalizer.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _equalizerService.isEnabled,
            builder: (context, isEnabled, child) {
              return Switch(
                value: isEnabled,
                onChanged: (value) {
                  _equalizerService.setEnabled(value);
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
            _buildPresetSelector(),
            const SizedBox(height: 24),
            _buildBandSliders(),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSelector() {
    return ValueListenableBuilder<String>(
      valueListenable: _equalizerService.currentPreset,
      builder: (context, currentPreset, child) {
        return DropdownButtonFormField<String>(
          value: currentPreset,
          decoration: const InputDecoration(
            labelText: 'Preset',
            border: OutlineInputBorder(),
          ),
          items: _equalizerService.presetNames
              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _equalizerService.setPreset(value);
            }
          },
        );
      },
    );
  }

  Widget _buildBandSliders() {
    return ValueListenableBuilder<List<int>>(
      valueListenable: _equalizerService.bandLevels,
      builder: (context, bandLevels, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_equalizerService.centerFreqs.length, (index) {
            final freq = _equalizerService.centerFreqs[index];
            final level = bandLevels[index];
            return Column(
              children: [
                SizedBox(
                  height: 250,
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: Slider(
                      min: _equalizerService.minDecibels.toDouble(),
                      max: _equalizerService.maxDecibels.toDouble(),
                      value: level.toDouble(),
                      onChanged: (value) {
                        _equalizerService.setBandLevel(index, value.round());
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
