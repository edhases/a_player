import 'package:flutter/material.dart';
import 'package:oxide_player/src/core/services/audio_handler.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:oxide_player/src/presentation/pages/folder_list_screen.dart';
import 'package:oxide_player/src/presentation/widgets/permission_gate.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';

late AudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _audioHandler = await initAudioService();
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (context) => AppDatabase(),
          dispose: (context, db) => db.close(),
        ),
        Provider<AudioHandler>(
          create: (context) => _audioHandler,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oxide Player',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: PermissionGate(
        child: FolderListScreen(),
      ),
    );
  }
}
