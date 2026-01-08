import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'src/data/datasources/app_database.dart';
import 'src/core/services/audio_handler.dart';
import 'src/core/services/music_finder.dart';
import 'src/core/services/settings_service.dart';
import 'src/core/services/google_auth_service.dart';
import 'src/core/services/youtube_helper.dart';
import 'src/core/services/innertube_service.dart';
import 'src/core/services/youtube_audio_source.dart';
import 'src/core/theme/app_theme.dart';
import 'src/presentation/pages/home_screen.dart';
import 'src/presentation/widgets/permission_gate.dart';
import 'src/presentation/widgets/mini_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  debugPrint('[Main] MetadataGod initializing...');
  await MetadataGod.initialize();
  debugPrint('[Main] MetadataGod initialized.');

  // Initialize and register services in order
  final settingsService = SettingsService();
  await settingsService.init();
  GetIt.I.registerSingleton<SettingsService>(settingsService);

  final db = AppDatabase();
  GetIt.I.registerSingleton<AppDatabase>(db);

  final musicFinder = MusicFinder(db);
  GetIt.I.registerSingleton<MusicFinder>(musicFinder);

  // Register GoogleAuthService before InnerTubeService
  debugPrint('[Main] GoogleAuthService initializing...');
  final googleAuthService = GoogleAuthService();
  GetIt.I.registerSingleton<GoogleAuthService>(googleAuthService);
  debugPrint('[Main] GoogleAuthService initialized.');

  GetIt.I.registerSingleton<InnerTubeService>(InnerTubeService());
  
  // Register YouTubeHelper with database
  debugPrint('[Main] YouTubeHelper initializing...');
  final youtubeHelper = YouTubeHelper(db);
  GetIt.I.registerSingleton<YouTubeHelper>(youtubeHelper);
  debugPrint('[Main] YouTubeHelper initialized.');

  debugPrint('[Main] AudioService initializing...');
  final handler = await AudioService.init(
    builder: () => MyAudioHandler(db),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.oxide_player.channel.audio',
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: true,
    ),
  );
  debugPrint('[Main] AudioService initialized.');

  GetIt.I.registerSingleton<MyAudioHandler>(handler);

  runApp(const OxidePlayerApp());
}

class OxidePlayerApp extends StatelessWidget {
  const OxidePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final musicFinder = GetIt.I<MusicFinder>();

    return MaterialApp(
      title: 'Oxide Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: PermissionGate(
        child: Scaffold(
          body: Stack(
            children: [
              // Main content with HomeScreen
              const Column(
                children: [
                  Expanded(child: HomeScreen()),
                  MiniPlayer(),
                ],
              ),
              // Scanning overlay
              ValueListenableBuilder<bool>(
                valueListenable: musicFinder.isScanning,
                builder: (context, isScanning, child) {
                  if (!isScanning) return const SizedBox.shrink();
                  
                  return Container(
                    color: Colors.black.withOpacity(0.8),
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 24),
                              Text(
                                'Scanning for music...',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              ValueListenableBuilder<String>(
                                valueListenable: musicFinder.scanStatus,
                                builder: (context, status, _) {
                                  return Text(
                                    status.isNotEmpty ? status : 'Please wait...',
                                    style: TextStyle(color: Colors.grey[500]),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
