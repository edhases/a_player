import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:get_it/get_it.dart';

import '../../../core/services/settings_service.dart';
import '../../../core/services/log_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsService _settingsService;

  SettingsBloc(this._settingsService)
      : super(const SettingsState(locale: Locale('en', ''))) {
    on<LoadSettings>(_onLoadSettings);
    on<ChangeLocale>(_onChangeLocale);
    on<ChangeThemeMode>(_onChangeThemeMode);
    on<ToggleMiniPlayer>(_onToggleMiniPlayer);
    on<ChangeMaxLogSize>(_onChangeMaxLogSize);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    // Load Locale
    final langCode = _settingsService.loadString('language_code');
    final scriptCode = _settingsService.loadString('script_code');

    Locale locale;
    if (langCode != null) {
      if (scriptCode != null) {
        locale =
            Locale.fromSubtags(languageCode: langCode, scriptCode: scriptCode);
      } else {
        locale = Locale(langCode);
      }
    } else {
      locale = const Locale('en', ''); // Default
    }

    // Load Theme (Future proofing, for now defaults to dark)
    // final themeIndex = _settingsService.loadInt('theme_mode') ?? ThemeMode.dark.index;

    // Load Log Size
    final maxLogSize = _settingsService.loadMaxLogSize();

    emit(state.copyWith(locale: locale, maxLogSize: maxLogSize));
  }

  Future<void> _onChangeLocale(
    ChangeLocale event,
    Emitter<SettingsState> emit,
  ) async {
    // Save to settings
    await _settingsService.saveString(
        'language_code', event.locale.languageCode);
    if (event.locale.scriptCode != null) {
      await _settingsService.saveString(
          'script_code', event.locale.scriptCode!);
    }

    emit(state.copyWith(locale: event.locale));
  }

  void _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(themeMode: event.themeMode));
    // Persist if needed
  }

  void _onToggleMiniPlayer(
    ToggleMiniPlayer event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(showMiniPlayer: event.show));
  }

  Future<void> _onChangeMaxLogSize(
    ChangeMaxLogSize event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsService.saveMaxLogSize(event.size);
    if (GetIt.I.isRegistered<LogService>()) {
      GetIt.I<LogService>().setMaxFileSize(event.size);
    }
    emit(state.copyWith(maxLogSize: event.size));
  }
}
