import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _consentKey = 'cloud_ai_consent_given';
const _declinedKey = 'cloud_ai_consent_declined';

/// Consentement explicite avant le premier envoi de photo/texte à l'IA
/// cloud (Google Gemini, Cloudflare Workers AI / Pollinations.ai) — Purement local (SharedPreferences),
/// révocable depuis Profil > Sécurité, même pattern que fasting_provider.dart.
/// N'affecte pas l'IA locale (flutter_gemma), qui n'envoie rien au cloud.
final cloudAiConsentProvider =
    AsyncNotifierProvider<CloudAiConsentNotifier, bool>(
      CloudAiConsentNotifier.new,
    );

class CloudAiConsentNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
    state = const AsyncData(true);
  }

  Future<void> revoke() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, false);
    state = const AsyncData(false);
  }
}

/// Vrai si l'utilisateur a explicitement refusé le consentement cloud (bouton
/// "Pas maintenant" d'un dialogue de consentement, pas une simple fermeture).
/// Distinct de `false` dans [cloudAiConsentProvider], qui ne permet pas de
/// différencier "jamais demandé" de "refusé explicitement" — utilisé par le
/// chat coach pour afficher une carte explicative plutôt que de redemander à
/// chaque envoi (voir coach_screen.dart).
final cloudAiConsentDeclinedProvider =
    AsyncNotifierProvider<CloudAiConsentDeclinedNotifier, bool>(
      CloudAiConsentDeclinedNotifier.new,
    );

class CloudAiConsentDeclinedNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_declinedKey) ?? false;
  }

  Future<void> markDeclined() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_declinedKey, true);
    state = const AsyncData(true);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_declinedKey, false);
    state = const AsyncData(false);
  }
}
