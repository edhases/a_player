import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  final Map<String, String> _localizedStrings;

  AppLocalizations(this.locale, this._localizedStrings);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String translate(String key, {Map<String, dynamic>? args}) {
    var res = _localizedStrings[key] ?? key;
    if (args != null) {
      args.forEach((k, v) {
        res = res.replaceAll('{$k}', v.toString());
      });
    }
    return res;
  }

  // Original Keys
  String get home => translate('home');
  String get library => translate('library');
  String get settings => translate('settings');
  String get youtube => translate('youtube');
  String get search => translate('search');
  String get playlists => translate('playlists');
  String get tracks => translate('tracks');
  String get albums => translate('albums');
  String get folders => translate('folders');
  String get artists => translate('artists');
  String get login => translate('login');
  String get logout => translate('logout');
  String get darkMode => translate('dark_mode');
  String get language => translate('language');
  String get equalizer => translate('equalizer');
  String get sleepTimer => translate('sleep_timer');
  String get quickPicks => translate('quick_picks');
  String get quickAccess => translate('quick_access');
  String get listenAgain => translate('listen_again');
  String get community => translate('community');
  String get localAlbums => translate('local_albums');
  String get likedSongs => translate('liked_songs');
  String get history => translate('history');
  String get signInMessage => translate('sign_in_message');
  String get playback => translate('playback');
  String get about => translate('about');
  String get scanLibrary => translate('scan_library');
  String get scanDesc => translate('scan_desc');
  String get scanning => translate('scanning');
  String get scanComplete => translate('scan_complete');
  String get clearLibrary => translate('clear_library');
  String get clearDesc => translate('clear_desc');
  String get clearTitle => translate('clear_title');
  String get clearConfirm => translate('clear_confirm');
  String get cancel => translate('cancel');
  String get clear => translate('clear');
  String get cleared => translate('cleared');
  String get signedIn => translate('signed_in');
  String get notSignedIn => translate('not_signed_in');
  String get reauth => translate('reauth');
  String get reauthDesc => translate('reauth_desc');
  String get cookiesUpdated => translate('cookies_updated');
  // New keys getters
  String get single => translate('single');
  String get songType => translate('song_type');
  String get playlistType => translate('playlist_type');
  String get albumType => translate('album_type');
  String get epType => translate('ep_type');
  String get unknownArtist => translate('unknown_artist');
  String get recommendedForYou => translate('recommended_for_you');
  String get trendingNow => translate('trending_now');
  String get madeForYou => translate('made_for_you');

  String get shareTrack => translate('share_track');
  String get stopTimer => translate('stop_timer');
  String get setSleepTimer => translate('set_sleep_timer');
  String get minutesSuffix => translate('minutes_suffix');
  String get noHistory => translate('no_history');
  String get addToQueue => translate('add_to_queue');
  String get playNow => translate('play_now');
  String get queueAdded => translate('queue_added');
  String get yourLibrary => translate('your_library');
  String get lastPlayedTitle => translate('last_played_title');

  // New Config/Settings keys
  String get filters => translate('filters');
  String get skipShortTracks => translate('skip_short_tracks');
  String get skipLongTracks => translate('skip_long_tracks');
  String get noLimit => translate('no_limit');
  String get off => translate('off');
  String get excludedFolders => translate('excluded_folders');
  String get matchMetadata => translate('match_metadata');
  String get matchMetadataDesc => translate('match_metadata_desc');
  String get serviceNotAvailable => translate('service_not_available');
  String get scanningLibraryTitle => translate('scanning_library_title');
  String get cache => translate('cache');
  String get maxCacheSize => translate('max_cache_size');
  String get viewCachedTracks => translate('view_cached_tracks');
  String get showDownloadedSongs => translate('show_downloaded_songs');
  String get clearCache => translate('clear_cache');
  String get clearCacheDesc => translate('clear_cache_desc');
  String get clearCacheConfirm => translate('clear_cache_confirm');
  String get cacheCleared => translate('cache_cleared');
  String get cacheServiceUnavailable => translate('cache_service_unavailable');
  String get adjustEqualizer => translate('adjust_equalizer');
  String get personalizedRecommendations =>
      translate('personalized_recommendations');
  String get matched => translate('matched');
  String get wrongMatch => translate('wrong_match');
  String get ok => translate('ok');
  String get noMatchFound => translate('no_match_found');
  String get manualSearchConfirm => translate('manual_search_confirm');
  String get manualSearch => translate('manual_search');
  String get metadataUpdated => translate('metadata_updated');
  String get playNext => translate('play_next');
  String get playAll => translate('play_all');
  String get shuffle => translate('shuffle');
  String get excludeHide => translate('exclude_hide');
  String get restore => translate('restore');
  String get deleteFile => translate('delete_file');
  String get trackHidden => translate('track_hidden');
  String get trackRestored => translate('track_restored');
  String get deleteFileTitle => translate('delete_file_title');
  String get deleteFileConfirm => translate('delete_file_confirm');
  String get delete => translate('delete');
  String get fileDeleted => translate('file_deleted');
  String get noTracksFound => translate('no_tracks_found');
  String get willPlayNext => translate('will_play_next');
  String get close => translate('close');
  String get noExcludedFolders => translate('no_excluded_folders');
  String get unknownAlbum => translate('unknown_album');
  String get tracksCount => translate('tracks_count');
  String get error => translate('error');
  String get loginTooltip => translate('login_tooltip');
  String get scanQuerying => translate('scan_querying');
  String get scanFound => translate('scan_found');
  String get scanProcessing => translate('scan_processing');
  String get scanSaving => translate('scan_saving');
  String get currentQueue => translate('current_queue');
  String get download => translate('download');
  String get startingDownload => translate('starting_download');
  String get cannotDownload => translate('cannot_download');
  String get addToFavorites => translate('add_to_favorites');
  String get removeFromFavorites => translate('remove_from_favorites');
  String get addedToFavorites => translate('added_to_favorites');
  String get removedFromFavorites => translate('removed_from_favorites');
  String get trackDetails => translate('track_details');
  String get path => translate('path');
  String get includeInLibrary => translate('include_in_library');
  String get excludeFromLibrary => translate('exclude_from_library');
  String get noFolders => translate('no_folders');
  String get noAlbums => translate('no_albums');
  String get noArtists => translate('no_artists');
  String get scanStarting => translate('scan_starting');
  String get signInYoutube => translate('sign_in_youtube');
  String get retry => translate('retry');
  String get scanMusic => translate('scan_music');
  String get cachedTracksTitle => translate('cached_tracks_title');
  String get equalizerActivate => translate('equalizer_activate');
  String get preset => translate('preset');
  String get permissionNeeded => translate('permission_needed');
  String get permissionDesc => translate('permission_desc');
  String get grantPermissions => translate('grant_permissions');
  String get openSettings => translate('open_settings');
  String get signInTitle => translate('sign_in_title');
  String get signInSubtitle => translate('sign_in_subtitle');
  String get signInBtn => translate('sign_in_btn');
  String get signingIn => translate('signing_in');
  String get whatWeNeed => translate('what_we_need');
  String get needAccess => translate('need_access');
  String get needPlaylists => translate('need_playlists');
  String get needCookies => translate('need_cookies');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'uk', 'de', 'pl', 'es', 'ja'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Map locale to file
    String fileName = 'lang_en-us';
    if (locale.languageCode == 'uk') {
      fileName = 'lang_uk-ua';
    } else if (locale.languageCode == 'de') {
      fileName = 'lang_de-de';
    } else if (locale.languageCode == 'pl') {
      fileName = 'lang_pl-pl';
    } else if (locale.languageCode == 'es') {
      fileName = 'lang_es-es';
    } else if (locale.languageCode == 'ja') {
      fileName = 'lang_ja-jp';
    }

    // Load JSON from assets
    final jsonString =
        await rootBundle.loadString('assets/lang/$fileName.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    final localizedStrings =
        jsonMap.map((key, value) => MapEntry(key, value.toString()));

    return AppLocalizations(locale, localizedStrings);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
