import 'package/flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:provider/provider.dart';
import 'src/data/datasources/app_database.dart';
import 'src/core/services/audio_handler.dart';
import 'src/core/services/music_finder.dart';
import 'package:audio_service/audio_service.dart';
import 'src/presentation/pages/explorer_screen.dart';
import 'src/presentation/widgets/permission_gate.dart';
import 'src/core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MetadataGod.initialize();

  final audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: kNotificationChannelId,
      androidNotificationChannelName: kNotificationChannelName,
      androidNotificationOngoing: true,
    ),
  );

  final db = AppDatabase();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<MusicFinder>(create: (_) => MusicFinder(db)),
        Provider<MyAudioHandler>.value(value: audioHandler),
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
