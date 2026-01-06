import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart'; // 1. Додайте цей імпорт

import 'src/data/datasources/app_database.dart';
import 'src/core/services/audio_handler.dart';
import 'src/core/services/music_finder.dart';
import 'package:audio_service/audio_service.dart';
import 'src/presentation/pages/explorer_screen.dart';
import 'src/presentation/widgets/permission_gate.dart';

late MyAudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MetadataGod.initialize();

  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.oxide_player.channel.audio',
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: true,
    ),
  );

  // 2. Зареєструйте хендлер в GetIt
  GetIt.I.registerSingleton<MyAudioHandler>(audioHandler);

  final db = AppDatabase();

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
      home: PermissionGate(child: ExplorerScreen()),
    );
  }
}
