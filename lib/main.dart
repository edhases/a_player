import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'src/core/services/audio_source_factory.dart';
import 'src/core/services/sleep_timer_service.dart';

import 'src/core/services/localization_service.dart';
import 'src/core/utils/localization.dart';
import 'src/core/theme/app_theme.dart';
import 'src/domain/repositories/music_repository.dart';
import 'src/data/repositories/music_repository_impl.dart';
import 'src/presentation/pages/home_screen.dart';
import 'src/presentation/widgets/permission_gate.dart';
import 'src/presentation/widgets/mini_player.dart';
import 'src/core/services/recommendation_service.dart';
import 'src/core/services/metadata_matching_service.dart';
import 'src/core/services/favorites_service.dart';
import 'src/core/services/cache_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

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

  GetIt.I.registerSingleton<InnerTubeService>(
      InnerTubeService(localizationService: localizationService));

  // Register MusicRepository
  GetIt.I.registerSingleton<MusicRepository>(MusicRepositoryImpl());

  // Register YouTubeHelper with database
  debugPrint('[Main] YouTubeHelper initializing...');
  final youtubeHelper = YouTubeHelper(db);
  GetIt.I.registerSingleton<YouTubeHelper>(youtubeHelper);
  debugPrint('[Main] YouTubeHelper initialized.');

  // Register RecommendationService
  debugPrint('[Main] RecommendationService initializing...');
  // We need a YoutubeExplode instance for the service
  // It's better to manage this instance properly (e.g. inside the service or a provider)
  // For now creating a new one as per requirement context
  final ytInstance = YoutubeExplode();
  final recommendationService = RecommendationService(
      ytInstance, GetIt.I<InnerTubeService>(),
      localizationService: localizationService);
  // Important: Initialize Isar
  await recommendationService.init();
  GetIt.I.registerSingleton<RecommendationService>(recommendationService);
  debugPrint('[Main] RecommendationService initialized.');

  // Register MetadataMatchingService
  // It depends on RecommendationService's Isar instance
  if (recommendationService.isar != null) {
    final innerTubeService = GetIt.I<InnerTubeService>();
    final metadataMatchingService = MetadataMatchingService(
        recommendationService.isar!, db, innerTubeService);
    GetIt.I.registerSingleton<MetadataMatchingService>(metadataMatchingService);
    debugPrint('[Main] MetadataMatchingService initialized.');

    // Register FavoritesService
    final favoritesService = FavoritesService(recommendationService);
    await favoritesService.init();
    GetIt.I.registerSingleton<FavoritesService>(favoritesService);
    debugPrint('[Main] FavoritesService initialized.');

    // Register CacheService
    final cacheService = CacheService(recommendationService);
    await cacheService.init();
    GetIt.I.registerSingleton<CacheService>(cacheService);
    debugPrint('[Main] CacheService initialized.');

    // Register AudioSourceFactory
    GetIt.I.registerSingleton<AudioSourceFactory>(
      AudioSourceFactory(youtubeHelper, GetIt.I<CacheService>()),
    );
  } else {
    debugPrint(
        '[Main] Error: Isar is null, cannot init MetadataMatchingService');
  }

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

  // Register SleepTimerService
  GetIt.I.registerSingleton<SleepTimerService>(SleepTimerService(handler));

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
    final localizationService = Provider.of<LocalizationService>(context);

    return MaterialApp(
      title: 'Oxide Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: localizationService.currentLocale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('uk', ''),
        Locale('de', ''),
        Locale('pl', ''),
        Locale('es', ''),
        Locale('ja', ''),
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
