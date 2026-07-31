import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'locale';

/// Langue d'affichage de l'app, persistée localement et synchronisée avec
/// `Utilisateur.langue` côté serveur (voir `settings_screen.dart` et `splash_screen.dart`).
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      state = Locale(saved);
    }
  }

  /// `languageCode` : 'FR' ou 'EN' (insensible à la casse, comme renvoyé par l'API).
  Future<void> setLanguageCode(String languageCode) async {
    state = Locale(languageCode.toLowerCase());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, languageCode.toLowerCase());
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
