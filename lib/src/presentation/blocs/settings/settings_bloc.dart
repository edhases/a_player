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
    on<ChangeAmoledMode>(_onChangeAmoledMode);
    on<ChangeAccentColor>(_onChangeAccentColor);
    on<ChangeFontScale>(_onChangeFontScale);
    on<ChangeCrossfadeDuration>(_onChangeCrossfadeDuration);
    on<ChangeWifiOnly>(_onChangeWifiOnly);
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

    // Load Appearance
    final themeIndex = _settingsService.loadThemeMode();
    final themeMode = ThemeMode.values[themeIndex];
    final amoledMode = _settingsService.loadAmoledMode();
    final accentColor = _settingsService.loadAccentColor();
    final fontScale = _settingsService.loadFontSizeScale();

    // Load Playback & Network
    final crossfade = _settingsService.loadCrossfadeDuration();
    final wifiOnly = _settingsService.loadWifiOnly();

    // Load Log Size
    final maxLogSize = _settingsService.loadMaxLogSize();

    emit(state.copyWith(
      locale: locale,
      themeMode: themeMode,
      amoledMode: amoledMode,
      accentColor: accentColor,
      fontScale: fontScale,
      maxLogSize: maxLogSize,
      crossfadeDuration: crossfade,
      wifiOnly: wifiOnly,
    ));
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

  Future<void> _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsService.saveThemeMode(event.themeMode.index);
    emit(state.copyWith(themeMode: event.themeMode));
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

  Future<void> _onChangeAmoledMode(
      ChangeAmoledMode event, Emitter<SettingsState> emit) async {
    await _settingsService.saveAmoledMode(event.enabled);
    emit(state.copyWith(amoledMode: event.enabled));
  }

  Future<void> _onChangeAccentColor(
      ChangeAccentColor event, Emitter<SettingsState> emit) async {
    if (event.color != null) {
      await _settingsService.saveAccentColor(event.color!);
    } else {
      // Logic for removing/nullifying could be handled by passing a specific value or separate method,
      // but SharedPreferences doesn't support 'remove' easily via simple setInt.
      // We'll treat 0 or specific negative as null/dynamic if needed, or update Service to support remove.
      // For now, let's assume we always save a value if picked.
    }
    emit(state.copyWith(accentColor: event.color));
  }

  Future<void> _onChangeFontScale(
      ChangeFontScale event, Emitter<SettingsState> emit) async {
    await _settingsService.saveFontSizeScale(event.scale);
    emit(state.copyWith(fontScale: event.scale));
  }

  Future<void> _onChangeCrossfadeDuration(
      ChangeCrossfadeDuration event, Emitter<SettingsState> emit) async {
    await _settingsService.saveCrossfadeDuration(event.seconds);
    emit(state.copyWith(crossfadeDuration: event.seconds));
    // TODO: Notify AudioHandler
  }

  Future<void> _onChangeWifiOnly(
      ChangeWifiOnly event, Emitter<SettingsState> emit) async {
    await _settingsService.saveWifiOnly(event.enabled);
    emit(state.copyWith(wifiOnly: event.enabled));
  }
}
