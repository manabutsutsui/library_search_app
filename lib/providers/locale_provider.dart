import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefsKey = 'selected_locale';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ja')) {
    _loadLocale();
  }

  final supportedLocales = const [
    Locale('ja'), 
    Locale('en'), 
    Locale('zh'), 
    Locale('ko'), 
    Locale('fr'), 
  ];

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_prefsKey) ?? 'ja';
    final countryCode = prefs.getString('${_prefsKey}_country');
    state = Locale(languageCode, countryCode);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
    if (locale.countryCode != null) {
      await prefs.setString('${_prefsKey}_country', locale.countryCode!);
    }
    state = locale;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
