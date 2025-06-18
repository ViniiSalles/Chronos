import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _timezoneKey = 'selected_timezone';
  
  Locale _currentLocale = const Locale('pt', 'BR');
  String _currentTimezone = 'GMT-2';
  
  LanguageProvider() {
    _loadSavedSettings();
  }

  Locale get currentLocale => _currentLocale;
  String get currentTimezone => _currentTimezone;
  String get currentLanguage {
    switch (_currentLocale.languageCode) {
      case 'pt':
        return 'Português';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return 'Português';
    }
  }


  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);
    final savedTimezone = prefs.getString(_timezoneKey);

    if (savedLanguage != null) {
      final parts = savedLanguage.split('_');
      _currentLocale = Locale(parts[0], parts[1]);
    }

    if (savedTimezone != null) {
      _currentTimezone = savedTimezone;
    }

    notifyListeners();
  }

  Future<void> changeLanguage(String language) async {
    Locale newLocale;
    switch (language) {
      case 'Português':
        newLocale = const Locale('pt', 'BR');
        break;
      case 'English':
        newLocale = const Locale('en', 'US');
        break;
      case 'Español':
        newLocale = const Locale('es', 'ES');
        break;
      default:
        newLocale = const Locale('pt', 'BR');
    }

    _currentLocale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, '${newLocale.languageCode}_${newLocale.countryCode}');
    notifyListeners();
  }

  Future<void> changeTimezone(String timezone) async {
    _currentTimezone = timezone;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timezoneKey, timezone);
    notifyListeners();
  }
} 