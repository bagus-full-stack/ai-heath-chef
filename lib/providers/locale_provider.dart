import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocalePrefsKey = 'app_locale';
const supportedLocaleCodes = ['fr', 'en'];

/// Langue de l'app (FR/EN), persistée localement. Par défaut : langue
/// système si supportée, sinon français (langue d'origine de l'app, pour
/// ne pas surprendre les utilisateurs existants).
final localeProvider = AsyncNotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocalePrefsKey);
    if (saved != null && supportedLocaleCodes.contains(saved)) {
      return Locale(saved);
    }

    final systemCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(supportedLocaleCodes.contains(systemCode) ? systemCode : 'fr');
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocalePrefsKey, locale.languageCode);
    state = AsyncData(locale);
  }
}
