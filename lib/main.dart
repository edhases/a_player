import 'package:flutter/material.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:oxide_player/src/presentation/pages/folder_list_screen.dart';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:oxide_player/src/core/services/audio_handler.dart';
import 'package:oxide_player/src/presentation/widgets/permission_gate.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final audioHandler = await initAudioService();
  getIt.registerSingleton<AudioHandler>(audioHandler);
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (context) => AppDatabase(),
          dispose: (context, db) => db.close(),
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
