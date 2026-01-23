import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class ChangeLocale extends SettingsEvent {
  final Locale locale;

  const ChangeLocale(this.locale);

  @override
  List<Object?> get props => [locale];
}

class ChangeThemeMode extends SettingsEvent {
  final ThemeMode themeMode;

  const ChangeThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class ToggleMiniPlayer extends SettingsEvent {
  final bool show;

  const ToggleMiniPlayer(this.show);

  @override
  List<Object?> get props => [show];
}

class ChangeMaxLogSize extends SettingsEvent {
  final int size; // bytes

  const ChangeMaxLogSize(this.size);

  @override
  List<Object?> get props => [size];
}
