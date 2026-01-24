import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final Locale locale;
  final ThemeMode themeMode;
  final bool showMiniPlayer;

  // We can add more settings here (e.g. minTrackDuration, excludedFolders)
  // But likely they are better managed by specific blocs or just read from Service when needed.
  // Critical UI-affecting settings go here.

  final int? accentColor;
  final double fontScale;
  final int crossfadeDuration;
  final bool wifiOnly;
  final int maxLogSize;
  final bool amoledMode;

  const SettingsState({
    required this.locale,
    this.themeMode = ThemeMode.system, // Changed to system default
    this.showMiniPlayer = true,
    this.maxLogSize = 10485760,
    this.amoledMode = false,
    this.accentColor,
    this.fontScale = 1.0,
    this.crossfadeDuration = 0,
    this.wifiOnly = false,
  });

  SettingsState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool? showMiniPlayer,
    int? maxLogSize,
    bool? amoledMode,
    int? accentColor,
    double? fontScale,
    int? crossfadeDuration,
    bool? wifiOnly,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      showMiniPlayer: showMiniPlayer ?? this.showMiniPlayer,
      maxLogSize: maxLogSize ?? this.maxLogSize,
      amoledMode: amoledMode ?? this.amoledMode,
      accentColor: accentColor ?? this.accentColor,
      fontScale: fontScale ?? this.fontScale,
      crossfadeDuration: crossfadeDuration ?? this.crossfadeDuration,
      wifiOnly: wifiOnly ?? this.wifiOnly,
    );
  }

  @override
  List<Object?> get props => [
        locale,
        themeMode,
        showMiniPlayer,
        maxLogSize,
        amoledMode,
        accentColor,
        fontScale,
        crossfadeDuration,
        wifiOnly,
      ];
}
