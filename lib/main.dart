import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/core/services/app_initializer.dart';
import 'src/core/services/localization_service.dart';
import 'src/core/services/settings_service.dart';
import 'src/core/services/recommendation_service.dart';
import 'src/core/services/audio_handler.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/utils/localization.dart';
import 'src/data/datasources/app_database.dart';

import 'src/presentation/blocs/player/player_bloc.dart';
import 'src/presentation/blocs/queue/queue_bloc.dart';
import 'src/presentation/blocs/home/home_bloc.dart';
import 'src/presentation/blocs/library/library_bloc.dart';

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

  // Initialize all services
  await AppInitializer.init();

  runApp(
    ChangeNotifierProvider.value(
      value: GetIt.I<LocalizationService>(),
      child: const OxidePlayerApp(),
    ),
  );
}

class OxidePlayerApp extends StatelessWidget {
  const OxidePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);

    // Initializing Blocs here to be available globally
    return MultiBlocProvider(
      providers: [
        BlocProvider<PlayerBloc>(
          create: (context) => PlayerBloc(
            audioHandler: GetIt.I<MyAudioHandler>(),
          ),
        ),
        BlocProvider<QueueBloc>(
          create: (context) => QueueBloc(
            audioHandler: GetIt.I<MyAudioHandler>(),
          ),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(
            recommendationService: GetIt.I<RecommendationService>(),
            db: GetIt.I<AppDatabase>(),
          )..add(HomeLoadFeed()),
        ),
        BlocProvider<LibraryBloc>(
          create: (context) => LibraryBloc(
            db: GetIt.I<AppDatabase>(),
            settings: GetIt.I<SettingsService>(),
          ),
        ),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
