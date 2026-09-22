import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import 'meal_repository.dart';

/// Instance unique de la base locale (SQLite/Drift) pour toute l'app.
/// Surchargée dans `main.dart` pour partager la même connexion que le
/// listener de synchronisation réseau.
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(appDatabaseProvider));
});
