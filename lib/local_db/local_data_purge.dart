import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/home_widget_service.dart';
import '../services/notification_service.dart';
import 'app_database.dart';

/// Supprime toutes les lignes locales (repas, pesées, hydratation). Isolée
/// de [purgeLocalUserData] pour rester testable sans plugins (voir
/// test/local_db/local_data_purge_test.dart).
Future<void> wipeLocalDatabase(AppDatabase db) async {
  await db.transaction(() async {
    await db.delete(db.localMeals).go();
    await db.delete(db.weightEntries).go();
    await db.delete(db.hydrationEntries).go();
  });
}

/// Purge complète des données locales d'un compte, appelée après succès de
/// la suppression côté serveur (voir delete_account_screen.dart) : base
/// drift, photos locales, préférences, rappels programmés et widget Android.
///
/// Best-effort par étape : une erreur sur l'une d'elles ne doit pas empêcher
/// la déconnexion/redirection qui suit (le compte est déjà supprimé côté
/// serveur à ce stade, il n'y a plus de retour en arrière possible).
Future<void> purgeLocalUserData(AppDatabase db) async {
  try {
    await wipeLocalDatabase(db);
  } catch (_) {}

  try {
    final docsDir = await getApplicationDocumentsDirectory();
    for (final subDir in ['meal_photos', 'weight_photos']) {
      final dir = Directory('${docsDir.path}/$subDir');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  } catch (_) {}

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  } catch (_) {}

  try {
    await NotificationService.instance.cancelAll();
  } catch (_) {}

  try {
    await HomeWidgetService.update(kcal: 0, targetKcal: 0, streak: 0);
  } catch (_) {}
}
