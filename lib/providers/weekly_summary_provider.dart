import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../local_db/local_db_provider.dart';
import '../services/notification_service.dart';
import 'locale_provider.dart';

const _kWeeklySummaryNotificationId = 1005;
const _kLastShownPrefsKey = 'weekly_summary_last_shown';

/// Chiffres du résumé hebdomadaire, calculés une seule fois et réutilisés par
/// [weeklySummaryReconcilerProvider] (notification) et par l'export partageable
/// de nutrition_trends_screen.dart.
class WeeklySummaryData {
  final int avgKcal;
  final double? weightDeltaKg;
  const WeeklySummaryData({required this.avgKcal, this.weightDeltaKg});
}

/// `null` si aucun repas loggé sur les 7 derniers jours (pas de résumé
/// pertinent à afficher).
final weeklySummaryDataProvider = FutureProvider<WeeklySummaryData?>((ref) async {
  final mealRepository = ref.watch(mealRepositoryProvider);
  final meals = await mealRepository.getMealsSince(7);
  if (meals.isEmpty) return null;
  final avgKcal = (meals.fold<int>(0, (sum, m) => sum + m.totalKcal) / 7).round();

  final weightRepository = ref.watch(weightRepositoryProvider);
  final weights = await weightRepository.getEntriesSince(7);
  double? weightDeltaKg;
  if (weights.length >= 2) {
    weightDeltaKg = weights.last.weightKg - weights.first.weightKg;
  }

  return WeeklySummaryData(avgKcal: avgKcal, weightDeltaKg: weightDeltaKg);
});

/// Résumé hebdomadaire ("cette semaine : -0.3kg, 1850kcal/j en moyenne")
/// envoyé en notification au plus une fois tous les 7 jours, à l'ouverture de
/// l'app. Pas de notion de semaine calendaire : juste "au moins 7 jours
/// depuis le dernier envoi", recalculé à chaque ouverture de l'app puisqu'aucun
/// code ne tourne pendant qu'elle est fermée.
final weeklySummaryReconcilerProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final lastShownMillis = prefs.getInt(_kLastShownPrefsKey);
  final now = DateTime.now();
  if (lastShownMillis != null &&
      now.difference(DateTime.fromMillisecondsSinceEpoch(lastShownMillis)) <
          const Duration(days: 7)) {
    return;
  }

  final data = await ref.watch(weeklySummaryDataProvider.future);
  if (data == null) return;

  final locale = ref.read(localeProvider).value ?? const Locale('fr');
  final l10n = lookupAppLocalizations(locale);
  final body = weeklySummaryBodyText(l10n, data);

  try {
    await NotificationService.instance.showNotification(
      id: _kWeeklySummaryNotificationId,
      title: 'AI Health Chef',
      body: body,
    );
  } catch (_) {
    // Best-effort : permission pas encore accordée, ou plugin pas prêt.
  }

  await prefs.setInt(_kLastShownPrefsKey, now.millisecondsSinceEpoch);
});

/// Texte du résumé ("cette semaine : -0.3kg, 1850kcal/j en moyenne"),
/// commun à la notification et à la carte partageable.
String weeklySummaryBodyText(AppLocalizations l10n, WeeklySummaryData data) {
  return data.weightDeltaKg != null
      ? l10n.weeklySummaryBodyWithWeight(
          '${data.weightDeltaKg! >= 0 ? '+' : ''}${data.weightDeltaKg!.toStringAsFixed(1)}kg',
          data.avgKcal,
        )
      : l10n.weeklySummaryBodyNoWeight(data.avgKcal);
}
