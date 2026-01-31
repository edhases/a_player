import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get_it/get_it.dart';
import '../../core/services/equalizer_service.dart';
import '../../core/utils/localization.dart';
import '../../core/theme/app_theme.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  EqualizerService? _equalizerService;
  bool _isLoading = true;
  Timer? _retryTimer;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _tryInitEqualizer();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _tryInitEqualizer() async {
    // 1. Check if already registered
    if (GetIt.I.isRegistered<EqualizerService>()) {
      _equalizerService = GetIt.I<EqualizerService>();
      setState(() => _isLoading = false);
      return;
    }

    // 2. Poll
    if (_retryCount < 6) {
      _retryCount++;
      _retryTimer = Timer(const Duration(milliseconds: 500), _tryInitEqualizer);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).equalizer)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_equalizerService == null) {
      final colors = context.appColors;
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).equalizer)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note, size: 48, color: colors.textMuted),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).equalizerNotActive,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).equalizerActivateMusic,
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

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
                onChanged: eq.setEnabled,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPresetSelector(eq, context),
            const SizedBox(height: 24),
            _buildBandSliders(eq),
            const SizedBox(height: 24),
            _buildResetButton(eq, context),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(EqualizerService eq, BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        eq.setPreset('Flat').catchError((_) {});
        for (int i = 0; i < eq.centerFreqs.length; i++) {
          eq.setBandGain(i, 0.0);
        }
      },
      icon: const Icon(Icons.refresh),
      label: Text(AppLocalizations.of(context).resetToFlat),
    );
  }

  Widget _buildPresetSelector(EqualizerService eq, BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: eq.currentPreset,
      builder: (context, currentPreset, child) {
        return DropdownButtonFormField<String>(
          value: eq.presetNames.contains(currentPreset)
              ? currentPreset
              : eq.presetNames.first,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).preset,
            border: const OutlineInputBorder(),
          ),
          dropdownColor: context.appColors.sheetBackground,
          items: eq.presetNames
              .map((name) => DropdownMenuItem(
                  value: name,
                  child: Text(_getLocalizedPresetName(context, name))))
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

  String _getLocalizedPresetName(BuildContext context, String key) {
    final loc = AppLocalizations.of(context);
    switch (key) {
      case 'Custom':
        return loc.presetCustom;
      case 'Flat':
        return loc.presetFlat;
      case 'Pop':
        return loc.presetPop;
      case 'Rock':
        return loc.presetRock;
      case 'Punk':
        return loc.presetPunk;
      case 'Dubstep':
        return loc.presetDubstep;
      case 'Phonk':
        return loc.presetPhonk;
      case 'Jazz':
        return loc.presetJazz;
      case 'Classical':
        return loc.presetClassical;
      case 'Metal':
        return loc.presetMetal;
      case 'Hip-Hop':
        return loc.presetHipHop;
      default:
        return key;
    }
  }

  Widget _buildBandSliders(EqualizerService eq) {
    return ValueListenableBuilder<List<double>>(
      valueListenable: eq.bandLevels,
      builder: (context, bandLevels, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(eq.centerFreqs.length, (index) {
            final freq = eq.centerFreqs[index];
            final level = index < bandLevels.length ? bandLevels[index] : 0.0;
            final freqLabel = freq < 1000 ? '$freq Hz' : '${freq ~/ 1000} kHz';

            return Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 14),
                        ),
                        child: Slider(
                          min: eq.minDecibels,
                          max: eq.maxDecibels,
                          value: level.clamp(eq.minDecibels, eq.maxDecibels),
                          onChanged: (value) {
                            eq.setBandGain(index, value);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(freqLabel, style: const TextStyle(fontSize: 10)),
                  Text('${level.toStringAsFixed(1)}dB',
                      style:
                          TextStyle(fontSize: 10, color: context.appColors.textSecondary)),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
