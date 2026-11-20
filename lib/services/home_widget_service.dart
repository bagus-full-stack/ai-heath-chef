import 'dart:io';

import 'package:home_widget/home_widget.dart';

/// Widget écran d'accueil Android (macros du jour + streak) — voir
/// android/app/src/main/kotlin/com/aihealthchef/app/HealthChefWidgetProvider.kt
/// pour le rendu natif et [homeWidgetReconcilerProvider] (dashboard_provider.dart)
/// pour le déclenchement à chaque ouverture du dashboard.
///
/// ponytail: pas de version iOS — nécessiterait une extension WidgetKit
/// distincte (projet Xcode), hors périmètre buildable sans Mac.
class HomeWidgetService {
  static const _androidProviderName = 'HealthChefWidgetProvider';

  /// Best-effort : ignore silencieusement tout échec (pas de widget épinglé,
  /// plateforme non supportée...), ce n'est jamais une fonctionnalité
  /// bloquante pour le reste du dashboard.
  static Future<void> update({
    required int kcal,
    required int targetKcal,
    required int streak,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await HomeWidget.saveWidgetData<int>('kcal', kcal);
      await HomeWidget.saveWidgetData<int>('targetKcal', targetKcal);
      await HomeWidget.saveWidgetData<int>('streak', streak);
      await HomeWidget.updateWidget(androidName: _androidProviderName);
    } catch (_) {
      // best-effort, voir commentaire de classe
    }
  }
}
