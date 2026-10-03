import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _consentKey = 'cloud_ai_consent_given';

/// Consentement explicite avant le premier envoi de photo/texte à l'IA
/// cloud (Google Gemini, Cloudflare Workers AI / Pollinations.ai) — voir
/// docs/PRIVACY_POLICY_DRAFT.md. Purement local (SharedPreferences),
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
