import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const localePrefKey = 'app_locale';
  static const selectedPrefKey = 'language_selected';

  Locale _locale = const Locale('en');
  bool _selected = false;
  bool _ready = false;

  Locale get locale => _locale;
  bool get isSelected => _selected;
  bool get ready => _ready;
  bool get isHindi => _locale.languageCode == 'hi';

  String get displayName => isHindi ? 'हिन्दी' : 'English';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _selected = prefs.getBool(selectedPrefKey) ?? false;
    final code = prefs.getString(localePrefKey);
    if (code == 'hi' || code == 'en') {
      _locale = Locale(code!);
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale, {bool markSelected = true}) async {
    _locale = locale;
    if (markSelected) _selected = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(localePrefKey, locale.languageCode);
    if (markSelected) {
      await prefs.setBool(selectedPrefKey, true);
    }
    notifyListeners();
  }
}
