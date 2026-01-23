import 'package:audio_service/audio_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'audio_handler.dart';
import 'audio_source_factory.dart';
import 'cache_service.dart';
import 'download_service.dart';
import 'favorites_service.dart';
import 'google_auth_service.dart';
import 'innertube_service.dart';

import 'log_service.dart';
import 'metadata_matching_service.dart';
import 'music_finder.dart';
import 'recommendation_service.dart';
import 'settings_service.dart';
import 'sleep_timer_service.dart';
import 'smart_play_service.dart';
import 'telegram_service.dart';
import 'youtube_helper.dart';

import '../../data/datasources/app_database.dart';
import '../../data/repositories/music_repository_impl.dart';
import '../../domain/repositories/music_repository.dart';

/// Handles initialization and dependency injection of all app services.
class AppInitializer {
  static Future<void> init() async {
    // 1. Initialize LogService first (for early logging)
    final logService = LogService();
    await logService.init();
    GetIt.I.registerSingleton<LogService>(logService);
    logService.info('[AppInitializer] Starting initialization...');

    // 2. Initialize core services
    await _initCoreServices();

    // 3. Initialize Data Layer (Database)
    final db = AppDatabase();
    GetIt.I.registerSingleton<AppDatabase>(db);

    // 4. Initialize Domain/Feature Services
    await _initFeatureServices(db);

    // 5. Initialize Audio Handler
    await _initAudioHandler(db);

    logService.info('[AppInitializer] Initialization complete.');
  }

  static Future<void> _initCoreServices() async {
    // TelegramService
    final telegramService = TelegramService();
    await telegramService.init();
    GetIt.I.registerSingleton<TelegramService>(telegramService);

    // SettingsService
    final settingsService = SettingsService();
    await settingsService.init();
    GetIt.I.registerSingleton<SettingsService>(settingsService);

    // GoogleAuthService
    debugPrint('[AppInitializer] GoogleAuthService initializing...');
    final googleAuthService = GoogleAuthService();
    GetIt.I.registerSingleton<GoogleAuthService>(googleAuthService);
  }

  static Future<void> _initFeatureServices(AppDatabase db) async {
    // MusicFinder
    final musicFinder = MusicFinder(db);
    GetIt.I.registerSingleton<MusicFinder>(musicFinder);

    // InnerTubeService
    GetIt.I.registerSingleton<InnerTubeService>(
        InnerTubeService(settingsService: GetIt.I<SettingsService>()));

    // MusicRepository
    GetIt.I.registerSingleton<MusicRepository>(MusicRepositoryImpl());

    // YouTubeHelper
    debugPrint('[AppInitializer] YouTubeHelper initializing...');
    final youtubeHelper = YouTubeHelper(db);
    GetIt.I.registerSingleton<YouTubeHelper>(youtubeHelper);

    // DownloadService
    GetIt.I.registerSingleton<DownloadService>(
        DownloadService(ytHelper: youtubeHelper));

    // RecommendationService
    debugPrint('[AppInitializer] RecommendationService initializing...');
    final ytInstance = YoutubeExplode();
    final recommendationService = RecommendationService(
      ytInstance,
      GetIt.I<InnerTubeService>(),
      db,
      settingsService: GetIt.I<SettingsService>(),
    );
    await recommendationService.init();
    GetIt.I.registerSingleton<RecommendationService>(recommendationService);

    // MetadataMatchingService
    final metadataMatchingService = MetadataMatchingService(
      db,
      GetIt.I<InnerTubeService>(),
    );
    GetIt.I.registerSingleton<MetadataMatchingService>(metadataMatchingService);

    // FavoritesService
    final favoritesService = FavoritesService(recommendationService);
    await favoritesService.init();
    GetIt.I.registerSingleton<FavoritesService>(favoritesService);

    // CacheService
    final cacheService = CacheService();
    await cacheService.init();
    GetIt.I.registerSingleton<CacheService>(cacheService);

    // AudioSourceFactory
    GetIt.I.registerSingleton<AudioSourceFactory>(
      AudioSourceFactory(youtubeHelper, cacheService),
    );
  }

  static Future<void> _initAudioHandler(AppDatabase db) async {
    debugPrint('[AppInitializer] AudioService initializing...');
    final handler = await AudioService.init(
      builder: () => MyAudioHandler(
        db: db,
        settingsService: GetIt.I<SettingsService>(),
        audioSourceFactory: GetIt.I<AudioSourceFactory>(),
        recommendationService: GetIt.I<RecommendationService>(),
        innerTubeService: GetIt.I<InnerTubeService>(),
        metadataMatchingService: GetIt.I.isRegistered<MetadataMatchingService>()
            ? GetIt.I<MetadataMatchingService>()
            : null,
        logService:
            GetIt.I.isRegistered<LogService>() ? GetIt.I<LogService>() : null,
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.oxide_player.channel.audio',
        androidNotificationChannelName: 'Audio Playback',
        androidNotificationOngoing: true,
      ),
    );
    GetIt.I.registerSingleton<MyAudioHandler>(handler);

    // SleepTimerService (depends on handler)
    GetIt.I.registerSingleton<SleepTimerService>(SleepTimerService(handler));

    // SmartPlayService (depends on handler!)
    GetIt.I.registerSingleton<SmartPlayService>(SmartPlayService());

    debugPrint('[AppInitializer] AudioService initialized.');
  }
}
