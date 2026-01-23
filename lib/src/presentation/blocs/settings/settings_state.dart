import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final Locale locale;
  final ThemeMode themeMode;
  final bool showMiniPlayer;

  // We can add more settings here (e.g. minTrackDuration, excludedFolders)
  // But likely they are better managed by specific blocs or just read from Service when needed.
  // Critical UI-affecting settings go here.

  const SettingsState({
    required this.locale,
    this.themeMode = ThemeMode.dark, // Default to dark as per AppTheme
    this.showMiniPlayer = true,
    this.maxLogSize = 10485760, // 10 MB default
  });

  final int maxLogSize;

  SettingsState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool? showMiniPlayer,
    int? maxLogSize,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      showMiniPlayer: showMiniPlayer ?? this.showMiniPlayer,
      maxLogSize: maxLogSize ?? this.maxLogSize,
    );
  }

  @override
  List<Object?> get props => [locale, themeMode, showMiniPlayer, maxLogSize];
}
