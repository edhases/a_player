import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'language_code';
  Locale _currentLocale = const Locale('en');
  Map<String, String> _localizedStrings = {};

  Locale get currentLocale => _currentLocale;
  Map<String, String> get localizedStrings => _localizedStrings;

  LocalizationService() {
    _init();
  }

  Future<void> _init() async {
    await _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
    }
    await _loadStrings();
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    await _loadStrings();
    notifyListeners();
  }

  Future<void> _loadStrings() async {
    String fileName = 'lang_en-us';
    switch (_currentLocale.languageCode) {
      case 'uk':
        fileName = 'lang_uk-ua';
        break;
      case 'de':
        fileName = 'lang_de-de';
        break;
      case 'pl':
        fileName = 'lang_pl-pl';
        break;
      case 'es':
        fileName = 'lang_es-es';
        break;
      case 'ja':
        fileName = 'lang_ja-jp';
        break;
      default:
        fileName = 'lang_en-us';
    }

    try {
      final jsonString =
          await rootBundle.loadString('assets/lang/$fileName.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings =
          jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      debugPrint('Error loading localization: $e');
      _localizedStrings = {};
    }
  }
}
