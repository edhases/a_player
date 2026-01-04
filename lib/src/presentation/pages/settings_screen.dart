import 'package:flutter/material.dart';
import 'package:oxide_player/main.dart';
import 'package:oxide_player/src/core/services/settings_service.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: getIt<SettingsService>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: Consumer<SettingsService>(
          builder: (context, settings, child) {
            return ListView(
              children: [
                SwitchListTile(
                  title: const Text('Auto Fetch Artwork'),
                  subtitle: const Text('Automatically download missing artwork from the internet.'),
                  value: settings.autoFetchArtwork,
                  onChanged: (value) {
                    settings.setAutoFetchArtwork(value);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
