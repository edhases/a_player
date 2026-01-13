import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/data/datasources/app_database.dart';
import 'src/core/services/audio_handler.dart';
import 'src/core/services/music_finder.dart';
import 'src/core/services/settings_service.dart';
import 'src/core/services/google_auth_service.dart';
import 'src/core/services/youtube_helper.dart';
import 'src/core/services/innertube_service.dart';

import 'src/core/services/localization_service.dart';
import 'src/core/utils/localization.dart';
import 'src/core/theme/app_theme.dart';
import 'src/domain/repositories/music_repository.dart';
import 'src/data/repositories/music_repository_impl.dart';
import 'src/presentation/pages/home_screen.dart';
import 'src/presentation/widgets/permission_gate.dart';
import 'src/presentation/widgets/mini_player.dart';

/// Global flag to track if MetadataGod native library is available
bool isMetadataGodAvailable = false;

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
  try {
    await MetadataGod.initialize();
    isMetadataGodAvailable = true;
    debugPrint('[Main] MetadataGod initialized.');
  } catch (e) {
    isMetadataGodAvailable = false;
    debugPrint('[Main] MetadataGod failed to initialize: $e');
  }

  // Initialize and register services in order
  final settingsService = SettingsService();
  await settingsService.init();
  GetIt.I.registerSingleton<SettingsService>(settingsService);

  final localizationService = LocalizationService();
  GetIt.I.registerSingleton<LocalizationService>(localizationService);

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

  // Register MusicRepository
  GetIt.I.registerSingleton<MusicRepository>(MusicRepositoryImpl());

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

  runApp(
    ChangeNotifierProvider.value(
      value: localizationService,
      child: const OxidePlayerApp(),
    ),
  );
}

class OxidePlayerApp extends StatelessWidget {
  const OxidePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final musicFinder = GetIt.I<MusicFinder>();
    final localizationService = Provider.of<LocalizationService>(context);

    return MaterialApp(
      title: 'Oxide Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: localizationService.currentLocale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('uk', ''),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
            ],
          ),
        ),
      ),
    );
  }
}
