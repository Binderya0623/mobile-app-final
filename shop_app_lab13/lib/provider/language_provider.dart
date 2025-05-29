import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../orchuulga/en.dart';
import '../orchuulga/mn.dart';

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'language_code';
  late SharedPreferences _prefs;
  Map<String, String> _currentLanguage = en;
  String _currentLanguageCode = 'en';
  LanguageProvider() {
    _loadLanguagePreference();
  }
  String get currentLanguageCode => _currentLanguageCode;
  Future<void> _loadLanguagePreference() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLanguage = _prefs.getString(_languageKey);
    if (savedLanguage != null) {
      await setLanguage(savedLanguage);
    }
  }
  Future<void> setLanguage(String languageCode) async {
    _currentLanguageCode = languageCode;
    _currentLanguage = languageCode == 'mn' ? mn : en;
    await _prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }
  String translate(String key) {
    return _currentLanguage[key] ?? key;
  }
} 