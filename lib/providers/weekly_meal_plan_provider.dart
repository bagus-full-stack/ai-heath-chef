import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal_suggestion.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../utils/nutrition_targets.dart';
import '../utils/week_start.dart';
import 'dashboard_provider.dart';
import 'locale_provider.dart';
import 'profile_provider.dart';

const _mealsPerDay = 3;

/// Plan de repas pour les 7 prochains jours, généré par l'IA à partir du
/// profil/objectifs nutritionnels, mis en cache en base (une entrée par
/// semaine, clé = lundi de la semaine) — même pattern que
/// [mealSuggestionsProvider] (voir meal_suggestions_provider.dart), en plus
/// gros (7 jours au lieu d'un seul).
final weeklyMealPlanProvider =
    AsyncNotifierProvider<WeeklyMealPlanNotifier, List<MealSuggestion>>(
  WeeklyMealPlanNotifier.new,
);

class WeeklyMealPlanNotifier extends AsyncNotifier<List<MealSuggestion>> {
  @override
  Future<List<MealSuggestion>> build() async {
    final profile = await ref.watch(profileProvider.future);
    final dbService = ref.watch(databaseServiceProvider);
    return _loadOrGenerate(profile, dbService, forceRefresh: false);
  }

  /// Force une nouvelle génération IA (ignore le cache de la semaine) et la
  /// sauvegarde, à la place du plan actuel.
  Future<void> regenerate() async {
    final profile = await ref.read(profileProvider.future);
    final dbService = ref.read(databaseServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadOrGenerate(profile, dbService, forceRefresh: true),
    );
  }

  Future<List<MealSuggestion>> _loadOrGenerate(
    UserProfile? profile,
    DatabaseService dbService, {
    required bool forceRefresh,
  }) async {
    final weekKey = weekStartKey(DateTime.now());
    final dietType = profile?.dietType ?? 'none';
    final allergies = profile?.allergies ?? const [];
    final cuisinePreference = profile?.cuisinePreference ?? 'none';
    final signature = _preferencesSignature(dietType, allergies, cuisinePreference);

    if (!forceRefresh) {
      final cached = await dbService.getCachedWeeklyMealPlan(weekKey, signature);
      if (cached != null) {
        return cached;
      }
    }

    final targets = computeNutritionTargets(profile);
    final aiService = AIService();
    final lang = ref.read(localeProvider).value?.languageCode ?? 'fr';
    // ponytail: pas d'illustrations IA pour ~21 repas (coût/latence) — les
    // cartes retombent sur l'icône du moment de la journée, comme quand une
    // image échoue déjà pour les suggestions du jour.
    final plan = await aiService.getMealSuggestions(
      goal: profile?.goal ?? 'maintain',
      targetKcal: targets.kcal,
      targetProt: targets.protein,
      targetGluc: targets.carbs,
      targetLip: targets.fat,
      dietType: dietType,
      allergies: allergies,
      cuisinePreference: cuisinePreference,
      days: 7,
      mealsPerDay: _mealsPerDay,
      lang: lang,
    );

    await dbService.saveWeeklyMealPlan(weekKey, plan, signature);
    return plan;
  }

  String _preferencesSignature(String dietType, List<String> allergies, String cuisinePreference) {
    final sortedAllergies = [...allergies]..sort();
    return '$dietType|${sortedAllergies.join(',')}|$cuisinePreference';
  }
}
