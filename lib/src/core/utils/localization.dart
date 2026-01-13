import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'home': 'Home',
      'library': 'Library',
      'settings': 'Settings',
      'youtube': 'YouTube',
      'search': 'Search',
      'playlists': 'Playlists',
      'tracks': 'Tracks',
      'albums': 'Albums',
      'folders': 'Folders',
      'artists': 'Artists',
      'login': 'Login',
      'logout': 'Logout',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'equalizer': 'Equalizer',
      'sleep_timer': 'Sleep Timer',
      'quick_picks': 'Quick Picks',
      'listen_again': 'Listen Again',
      'community': 'Community',
      'local_albums': 'Local Albums',
      'liked_songs': 'Liked Songs',
      'history': 'History',
      'sign_in_message':
          'Sign in to YouTube Music\nfor a personalized experience',
    },
    'uk': {
      'home': 'Головна',
      'library': 'Бібліотека',
      'settings': 'Налаштування',
      'youtube': 'YouTube',
      'search': 'Пошук',
      'playlists': 'Плейлисти',
      'tracks': 'Треки',
      'albums': 'Альбоми',
      'folders': 'Папки',
      'artists': 'Виконавці',
      'login': 'Увійти',
      'logout': 'Вийти',
      'dark_mode': 'Темна тема',
      'language': 'Мова',
      'equalizer': 'Еквалайзер',
      'sleep_timer': 'Таймер сну',
      'quick_picks': 'Швидкий вибір',
      'listen_again': 'Слухати знову',
      'community': 'Спільнота',
      'local_albums': 'Локальні альбоми',
      'liked_songs': 'Вподобані',
      'history': 'Історія',
      'sign_in_message':
          'Увійдіть в YouTube Music\nдля персоналізованого досвіду',
    },
  };

  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get library => _localizedValues[locale.languageCode]!['library']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get youtube => _localizedValues[locale.languageCode]!['youtube']!;
  String get search => _localizedValues[locale.languageCode]!['search']!;
  String get playlists => _localizedValues[locale.languageCode]!['playlists']!;
  String get tracks => _localizedValues[locale.languageCode]!['tracks']!;
  String get albums => _localizedValues[locale.languageCode]!['albums']!;
  String get folders => _localizedValues[locale.languageCode]!['folders']!;
  String get artists => _localizedValues[locale.languageCode]!['artists']!;
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get darkMode => _localizedValues[locale.languageCode]!['dark_mode']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get equalizer => _localizedValues[locale.languageCode]!['equalizer']!;
  String get sleepTimer =>
      _localizedValues[locale.languageCode]!['sleep_timer']!;
  String get quickPicks =>
      _localizedValues[locale.languageCode]!['quick_picks']!;
  String get listenAgain =>
      _localizedValues[locale.languageCode]!['listen_again']!;
  String get community => _localizedValues[locale.languageCode]!['community']!;
  String get localAlbums =>
      _localizedValues[locale.languageCode]!['local_albums']!;
  String get likedSongs =>
      _localizedValues[locale.languageCode]!['liked_songs']!;
  String get history => _localizedValues[locale.languageCode]!['history']!;
  String get signInMessage =>
      _localizedValues[locale.languageCode]!['sign_in_message']!;

  // Helper method for dynamic keys
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'uk'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
