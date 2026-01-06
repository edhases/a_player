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

  // Initialize and register the settings service
  final settingsService = SettingsService();
  await settingsService.init();
  GetIt.I.registerSingleton<SettingsService>(settingsService);

  // Create the database instance
  final db = AppDatabase();

  // Initialize AudioService with the handler, passing the DB instance
  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(db),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.oxide_player.channel.audio',
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: true,
    ),
  );

  // Register the handler with GetIt for UI access
  GetIt.I.registerSingleton<MyAudioHandler>(audioHandler);

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<MusicFinder>(create: (_) => MusicFinder(db)),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oxide Player',
      theme: ThemeData.dark(),
      // The PermissionGate now wraps the main app structure.
      home: const PermissionGate(
        // The main UI is a Scaffold containing the HomeScreen and MiniPlayer
        child: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: HomeScreen(),
              ),
              MiniPlayer(),
            ],
          ),
        ),
      ),
    );
  }
}
