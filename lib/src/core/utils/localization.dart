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
      'playback': 'Playback',
      'about': 'About',
      'scan_library': 'Scan Music Library',
      'scan_desc': 'Scan device for all music files',
      'scanning': 'Scanning...',
      'scan_complete': 'Library scan complete!',
      'clear_library': 'Clear Library',
      'clear_desc': 'Remove all tracks from the database',
      'clear_title': 'Clear Library?',
      'clear_confirm':
          'This will remove all tracks from the library. You will need to scan your music folders again.',
      'cancel': 'Cancel',
      'clear': 'Clear',
      'cleared': 'Library cleared!',
      'signed_in': 'Signed in to YouTube Music',
      'not_signed_in': 'Not signed in',
      'reauth': 'Re-authenticate',
      'reauth_desc': 'Update cookies for YouTube Music',
      'cookies_updated': 'Cookies updated successfully!',
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
      'playback': 'Відтворення',
      'about': 'Про додаток',
      'scan_library': 'Сканувати бібліотеку',
      'scan_desc': 'Знайти всі музичні файли на пристрої',
      'scanning': 'Сканування...',
      'scan_complete': 'Сканування завершено!',
      'clear_library': 'Очистити бібліотеку',
      'clear_desc': 'Видалити всі треки з бази даних',
      'clear_title': 'Очистити бібліотеку?',
      'clear_confirm':
          'Це видалить всі треки. Вам доведеться сканувати папки знову.',
      'cancel': 'Скасувати',
      'clear': 'Очистити',
      'cleared': 'Бібліотеку очищено!',
      'signed_in': 'Ви увійшли в YouTube Music',
      'not_signed_in': 'Ви не увійшли',
      'reauth': 'Переавторизуватися',
      'reauth_desc': 'Оновити cookies для YouTube Music',
      'cookies_updated': 'Cookies оновлено успішно!',
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
  String get playback => _localizedValues[locale.languageCode]!['playback']!;
  String get about => _localizedValues[locale.languageCode]!['about']!;
  String get scanLibrary =>
      _localizedValues[locale.languageCode]!['scan_library']!;
  String get scanDesc => _localizedValues[locale.languageCode]!['scan_desc']!;
  String get scanning => _localizedValues[locale.languageCode]!['scanning']!;
  String get scanComplete =>
      _localizedValues[locale.languageCode]!['scan_complete']!;
  String get clearLibrary =>
      _localizedValues[locale.languageCode]!['clear_library']!;
  String get clearDesc => _localizedValues[locale.languageCode]!['clear_desc']!;
  String get clearTitle =>
      _localizedValues[locale.languageCode]!['clear_title']!;
  String get clearConfirm =>
      _localizedValues[locale.languageCode]!['clear_confirm']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get clear => _localizedValues[locale.languageCode]!['clear']!;
  String get cleared => _localizedValues[locale.languageCode]!['cleared']!;
  String get signedIn => _localizedValues[locale.languageCode]!['signed_in']!;
  String get notSignedIn =>
      _localizedValues[locale.languageCode]!['not_signed_in']!;
  String get reauth => _localizedValues[locale.languageCode]!['reauth']!;
  String get reauthDesc =>
      _localizedValues[locale.languageCode]!['reauth_desc']!;
  String get cookiesUpdated =>
      _localizedValues[locale.languageCode]!['cookies_updated']!;

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
