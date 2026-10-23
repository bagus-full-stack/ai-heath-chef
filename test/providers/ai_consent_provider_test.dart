import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_health_chef/providers/ai_consent_provider.dart';
import 'package:ai_health_chef/providers/local_ai_provider.dart';

// Vérifie les 5 cas de routage local/cloud décrits ci-dessous, via les primitives d'état qui pilotent le
// branchement (coach_screen.dart / chat_provider.dart) :
// - LocalAiSettings.isReadyToUse (IA locale prête ou non)
// - cloudAiConsentProvider (consentement cloud accordé ou non)
// - cloudAiConsentDeclinedProvider (refus explicite, distinct de "jamais demandé")
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('cas 1 — IA locale prête : aucun consentement requis', () {
    test('isReadyToUse est vrai seulement si activée ET téléchargée', () {
      const ready = LocalAiSettings(enabled: true, isDownloaded: true);
      const notEnabled = LocalAiSettings(enabled: false, isDownloaded: true);
      const notDownloaded = LocalAiSettings(enabled: true, isDownloaded: false);

      expect(ready.isReadyToUse, isTrue);
      expect(notEnabled.isReadyToUse, isFalse);
      expect(notDownloaded.isReadyToUse, isFalse);
    });
  });

  group('cas 2 — IA locale pas prête + consentement déjà donné', () {
    test('cloudAiConsentProvider démarre à false puis passe à true après accept()', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(cloudAiConsentProvider.future), isFalse);

      await container.read(cloudAiConsentProvider.notifier).accept();

      expect(container.read(cloudAiConsentProvider).value, isTrue);
    });
  });

  group('cas 3 — IA locale pas prête + consentement absent (jamais demandé)', () {
    test('consentement et refus sont tous les deux faux par défaut', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(cloudAiConsentProvider.future), isFalse);
      expect(await container.read(cloudAiConsentDeclinedProvider.future), isFalse);
    });
  });

  group('cas 4 — consentement refusé explicitement + IA locale pas prête', () {
    test('markDeclined() persiste le refus, sans affecter le consentement', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(cloudAiConsentDeclinedProvider.future);
      await container.read(cloudAiConsentProvider.future);

      await container.read(cloudAiConsentDeclinedProvider.notifier).markDeclined();

      expect(container.read(cloudAiConsentDeclinedProvider).value, isTrue);
      expect(container.read(cloudAiConsentProvider).value, isFalse);
    });

    test('accepter le cloud depuis la carte efface le refus (clear())', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(cloudAiConsentDeclinedProvider.future);
      await container.read(cloudAiConsentDeclinedProvider.notifier).markDeclined();

      await container.read(cloudAiConsentProvider.notifier).accept();
      await container.read(cloudAiConsentDeclinedProvider.notifier).clear();

      expect(container.read(cloudAiConsentProvider).value, isTrue);
      expect(container.read(cloudAiConsentDeclinedProvider).value, isFalse);
    });
  });

  group('cas 5 — repli IA locale vers le cloud uniquement si consentement existant', () {
    test('revoke() repasse le consentement à false (plus de repli cloud silencieux)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(cloudAiConsentProvider.future);
      await container.read(cloudAiConsentProvider.notifier).accept();

      await container.read(cloudAiConsentProvider.notifier).revoke();

      expect(container.read(cloudAiConsentProvider).value, isFalse);
    });
  });
}
