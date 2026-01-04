import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:oxide_player/main.dart';
import 'package:oxide_player/src/core/services/audio_handler.dart';
import 'package:oxide_player/src/presentation/providers/equalizer_provider.dart';
import 'package:provider/provider.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioHandler = getIt<MyAudioHandler>();

    return ChangeNotifierProvider(
      create: (_) => EqualizerProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Equalizer'),
        ),
        body: Consumer<EqualizerProvider>(
          builder: (context, provider, child) {
            return FutureBuilder<AndroidEqualizerParameters?>(
              future: audioHandler.equalizer?.parameters,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final parameters = snapshot.data!;
                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Equalizer'),
                      value: provider.equalizerEnabled,
                      onChanged: provider.setEqualizerEnabled,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(parameters.bands.length, (i) {
                          final band = parameters.bands[i];
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${band.centerFrequency.round()} Hz'),
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: -1,
                                  child: Slider(
                                    min: parameters.minDecibels,
                                    max: parameters.maxDecibels,
                                    value: provider.bandLevels.isNotEmpty ? provider.bandLevels[i] : 0.0,
                                    onChanged: (value) {
                                      provider.setBandLevel(i, value);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                    const Text('Speed'),
                    StreamBuilder<PlaybackState>(
                      stream: audioHandler.playbackState,
                      builder: (context, snapshot) {
                        return Slider(
                          min: 0.5,
                          max: 2.0,
                          value: snapshot.data?.speed ?? 1.0,
                          onChanged: audioHandler.setSpeed,
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
