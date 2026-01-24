import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/services/recommendation_service.dart';
import 'core/services/audio_handler.dart';
import 'core/services/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/localization.dart';
import 'data/datasources/app_database.dart';

import 'presentation/blocs/player/player_bloc.dart';
import 'presentation/blocs/queue/queue_bloc.dart';
import 'presentation/blocs/home/home_bloc.dart';
import 'presentation/blocs/library/library_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/settings/settings_event.dart';
import 'presentation/blocs/settings/settings_state.dart';
import 'presentation/blocs/lyrics/lyrics_bloc.dart';
import 'core/services/lyrics_service.dart';

import 'presentation/pages/home_screen.dart';
import 'presentation/widgets/permission_gate.dart';
import 'presentation/widgets/mini_player.dart';

class OxidePlayerApp extends StatelessWidget {
  const OxidePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initializing Blocs here to be available globally
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc(
            GetIt.I<SettingsService>(),
          )..add(LoadSettings()),
        ),
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
        BlocProvider<LyricsBloc>(
          create: (context) => LyricsBloc(
            GetIt.I<LyricsService>(),
            GetIt.I<MyAudioHandler>(),
          ),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            title: 'Oxide Player',
            debugShowCheckedModeBanner: false,
            // Use state from SettingsBloc
            theme: AppTheme.create(
              isDark: false,
              amoled: settingsState.amoledMode,
              accentColor: settingsState.accentColor,
            ),
            darkTheme: AppTheme.create(
              isDark: true,
              amoled: settingsState.amoledMode,
              accentColor: settingsState.accentColor,
            ),
            themeMode: settingsState.themeMode,
            locale: settingsState.locale,
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
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settingsState.fontScale),
                ),
                child: child!,
              );
            },
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
        },
      ),
    );
  }
}
