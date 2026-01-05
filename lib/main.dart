import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart'; // Не забудьте додати в pubspec
import 'package:provider/provider.dart'; // Рекомендую додати provider для DI
// ... інші імпорти
import 'src/data/datasources/app_database.dart';
import 'src/core/services/audio_handler.dart';
import 'src/core/services/music_finder.dart';
import 'package:audio_service/audio_service.dart';
import 'src/presentation/pages/explorer_screen.dart';
import 'src/presentation/widgets/permission_gate.dart';

// Глобальна змінна для доступу до хендлера (або через GetIt/Provider)
late MyAudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ініціалізація читача метаданих
  await MetadataGod.initialize();

  // Ініціалізація AudioService
  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.oxide_player.channel.audio',
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: true,
    ),
  );

  // Створення інстансу БД
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
