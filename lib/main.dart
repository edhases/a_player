import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';

import 'src/data/datasources/app_database.dart';
import 'src/core/services/audio_handler.dart';
import 'src/core/services/music_finder.dart';
import 'src/core/services/settings_service.dart';
import 'src/presentation/pages/home_screen.dart';
import 'src/presentation/widgets/permission_gate.dart';
import 'src/presentation/widgets/mini_player.dart';

late MyAudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MetadataGod.initialize();

  final settingsService = SettingsService();
  await settingsService.init();
  GetIt.I.registerSingleton<SettingsService>(settingsService);

  final db = AppDatabase();
  final musicFinder = MusicFinder(db);

  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(db),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.oxide_player.channel.audio',
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: true,
    ),
  );

  GetIt.I.registerSingleton<MyAudioHandler>(audioHandler);

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<MusicFinder>.value(value: musicFinder),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final musicFinder = Provider.of<MusicFinder>(context, listen: false);

    return MaterialApp(
      title: 'Oxide Player',
      theme: ThemeData.dark(),
      home: PermissionGate(
        child: Scaffold(
          // Using a Stack to overlay the progress indicator on top of the main UI
          body: Stack(
            children: [
              // Main content
              const Column(
                children: [
                  Expanded(
                    child: HomeScreen(),
                  ),
                  MiniPlayer(),
                ],
              ),
              // Global scanning progress indicator
              ValueListenableBuilder<bool>(
                valueListenable: musicFinder.isScanning,
                builder: (context, isScanning, child) {
                  if (isScanning) {
                    return Container(
                      color: Colors.black.withOpacity(0.7),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Scanning for music...',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
