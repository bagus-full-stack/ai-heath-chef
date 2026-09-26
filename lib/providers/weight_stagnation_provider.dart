import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../local_db/local_db_provider.dart';
import 'chat_provider.dart';
import 'locale_provider.dart';

const _kLookbackDays = 14;
// ponytail: naive max-min variation over the window, not a real trend/slope —
// upgrade to linear regression if this proves too sensitive to a single
// outlier weigh-in.
const _kStagnationThresholdKg = 0.3;
const _kLastAlertedPrefsKey = 'weight_stagnation_last_alerted';

/// Si le poids n'a quasi pas varié sur les [_kLookbackDays] derniers jours,
/// pousse un message dans le chat du coach existant (plutôt qu'une
/// notification séparée) — au plus une fois toutes les [_kLookbackDays]
/// jours. Réutilise l'historique déjà chargé pour le résumé hebdomadaire.
final weightStagnationReconcilerProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final lastAlertedMillis = prefs.getInt(_kLastAlertedPrefsKey);
  final now = DateTime.now();
  if (lastAlertedMillis != null &&
      now.difference(DateTime.fromMillisecondsSinceEpoch(lastAlertedMillis)) <
          const Duration(days: _kLookbackDays)) {
    return;
  }

  final weightRepository = ref.watch(weightRepositoryProvider);
  final entries = await weightRepository.getEntriesSince(_kLookbackDays);
  if (entries.length < 2) return;

  // Pas encore assez d'historique pour juger d'une stagnation sur la
  // fenêtre entière.
  if (now.difference(entries.first.recordedAt) < const Duration(days: _kLookbackDays - 2)) {
    return;
  }

  final weights = entries.map((e) => e.weightKg);
  final variation = weights.reduce((a, b) => a > b ? a : b) - weights.reduce((a, b) => a < b ? a : b);
  if (variation > _kStagnationThresholdKg) return;

  final locale = ref.read(localeProvider).value ?? const Locale('fr');
  final l10n = lookupAppLocalizations(locale);
  await ref.read(chatProvider.notifier).pushCoachMessage(l10n.weightStagnationCoachMessage);

  await prefs.setInt(_kLastAlertedPrefsKey, now.millisecondsSinceEpoch);
});
