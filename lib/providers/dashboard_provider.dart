import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../local_db/local_db_provider.dart';
import '../models/meal.dart';

// On rend le service accessible
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Ce provider va chercher les repas d'aujourd'hui, depuis la base locale
// (disponible même hors ligne — voir lib/local_db/meal_repository.dart).
// FutureProvider est parfait car il gère tout seul les états "chargement" et "erreur".
final todayMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final mealRepository = ref.watch(mealRepositoryProvider);
  return await mealRepository.getTodayMeals();
});

/// Repas des 7 derniers jours, pour l'écran "Analyses avancées" (PRO) —
/// tendances nutritionnelles et macros détaillées.
final nutritionTrendsProvider = FutureProvider<List<Meal>>((ref) async {
  final mealRepository = ref.watch(mealRepositoryProvider);
  return await mealRepository.getMealsSince(7);
});