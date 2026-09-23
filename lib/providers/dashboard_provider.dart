import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../local_db/app_database.dart' show HydrationEntry, WeightEntry;
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

/// Repas des 30 derniers jours, pour la courbe de tendance calories longue
/// durée de l'écran "Analyses avancées" (PRO).
final nutritionTrends30Provider = FutureProvider<List<Meal>>((ref) async {
  final mealRepository = ref.watch(mealRepositoryProvider);
  return await mealRepository.getMealsSince(30);
});

/// Pesées des 90 derniers jours, pour la courbe de progression de l'écran
/// "Suivi du poids".
final weightEntriesProvider = FutureProvider<List<WeightEntry>>((ref) async {
  final weightRepository = ref.watch(weightRepositoryProvider);
  return await weightRepository.getEntriesSince(90);
});

/// Prises d'eau du jour, pour la carte "Hydratation" du dashboard.
final hydrationTodayProvider = FutureProvider<List<HydrationEntry>>((ref) async {
  final hydrationRepository = ref.watch(hydrationRepositoryProvider);
  return await hydrationRepository.getTodayEntries();
});