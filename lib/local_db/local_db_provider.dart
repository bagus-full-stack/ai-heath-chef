import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import 'hydration_repository.dart';
import 'meal_repository.dart';
import 'weight_repository.dart';

/// Instance unique de la base locale (SQLite/Drift) pour toute l'app.
/// Surchargée dans `main.dart` pour partager la même connexion que le
/// listener de synchronisation réseau.
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(appDatabaseProvider));
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return WeightRepository(ref.watch(appDatabaseProvider));
});

final hydrationRepositoryProvider = Provider<HydrationRepository>((ref) {
  return HydrationRepository(ref.watch(appDatabaseProvider));
});
