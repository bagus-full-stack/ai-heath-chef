import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal_suggestion.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../utils/nutrition_targets.dart';
import 'dashboard_provider.dart';
import 'profile_provider.dart';

/// Idées de repas générées par l'IA à partir du profil et des objectifs
/// nutritionnels de l'utilisateur, mises en cache en base (une entrée par
/// jour) pour éviter un appel IA à chaque ouverture de l'écran. Un appel
/// explicite à [MealSuggestionsNotifier.regenerate] force une nouvelle
/// génération et remplace le cache du jour.
final mealSuggestionsProvider =
    AsyncNotifierProvider<MealSuggestionsNotifier, List<MealSuggestion>>(
  MealSuggestionsNotifier.new,
);

class MealSuggestionsNotifier extends AsyncNotifier<List<MealSuggestion>> {
  @override
  Future<List<MealSuggestion>> build() async {
    final profile = await ref.watch(profileProvider.future);
    final dbService = ref.watch(databaseServiceProvider);
    return _loadOrGenerate(profile, dbService, forceRefresh: false);
  }

  /// Force une nouvelle génération IA (ignore le cache du jour) et la
  /// sauvegarde, à la place des suggestions actuelles.
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
    final dayKey = _todayKey();
    final dietType = profile?.dietType ?? 'none';
    final allergies = profile?.allergies ?? const [];
    final signature = _preferencesSignature(dietType, allergies);

    if (!forceRefresh) {
      final cached = await dbService.getCachedMealSuggestions(dayKey, signature);
      if (cached != null) {
        return cached;
      }
    }

    final targets = computeNutritionTargets(profile);
    final aiService = AIService();
    final suggestions = await aiService.getMealSuggestions(
      goal: profile?.goal ?? 'maintain',
      targetKcal: targets.kcal,
      targetProt: targets.protein,
      targetGluc: targets.carbs,
      targetLip: targets.fat,
      dietType: dietType,
      allergies: allergies,
      count: 6,
    );
    final illustratedSuggestions = await aiService.getMealImages(suggestions);

    await dbService.saveMealSuggestions(dayKey, illustratedSuggestions, signature);
    return illustratedSuggestions;
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  /// Identifie les préférences utilisées pour générer un lot de suggestions,
  /// afin de détecter un changement de régime/allergies en cours de journée
  /// (voir [DatabaseService.getCachedMealSuggestions]).
  String _preferencesSignature(String dietType, List<String> allergies) {
    final sortedAllergies = [...allergies]..sort();
    return '$dietType|${sortedAllergies.join(',')}';
  }
}
