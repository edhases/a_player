import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/data/datasources/app_database.dart';
import 'src/core/services/audio_handler.dart';
import 'src/core/services/music_finder.dart';
import 'src/core/services/settings_service.dart';
import 'src/core/services/innertube_service.dart';
import 'src/core/services/youtube_audio_source.dart';
import 'src/presentation/pages/home_screen.dart';
import 'src/presentation/widgets/permission_gate.dart';
import 'src/presentation/widgets/mini_player.dart';

late MyAudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  await MetadataGod.initialize();

  final settingsService = SettingsService();
  await settingsService.init();
  GetIt.I.registerSingleton<SettingsService>(settingsService);

  // Register YouTube services
  GetIt.I.registerSingleton<InnerTubeService>(InnerTubeService());
  GetIt.I.registerSingleton<YouTubeHelper>(YouTubeHelper());

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
      child: const OxidePlayerApp(),
    ),
  );
}

class OxidePlayerApp extends StatelessWidget {
  const OxidePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final musicFinder = Provider.of<MusicFinder>(context, listen: false);

    // Poweramp-inspired color scheme
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF6B00), // Orange accent like Poweramp
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Oxide Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: colorScheme.surfaceContainerHighest,
          contentTextStyle: const TextStyle(color: Colors.white),
        ),
      ),
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
                    color: Colors.black.withValues(alpha: 0.8),
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
