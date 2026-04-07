import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_power_client/core/i18n.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  static const String _localeKey = 'locale';

  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey) ?? 'en';
    state = Locale(localeCode);
    LocaleService.setLocale(localeCode);
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
    state = Locale(languageCode);
    LocaleService.setLocale(languageCode);
  }

  String get currentLanguageCode => state.languageCode;

  bool get isEnglish => state.languageCode == 'en';
  bool get isChinese => state.languageCode == 'zh';

  Future<void> toggleLocale() async {
    if (isEnglish) {
      await setLocale('zh');
    } else {
      await setLocale('en');
    }
  }
}
