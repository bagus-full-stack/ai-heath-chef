import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/meal.dart';

// On rend le service accessible
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Ce provider va chercher les repas d'aujourd'hui.
// FutureProvider est parfait car il gère tout seul les états "chargement" et "erreur".
final todayMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getTodayMeals();
});