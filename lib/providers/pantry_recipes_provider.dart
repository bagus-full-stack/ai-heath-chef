import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal_suggestion.dart';
import 'locale_provider.dart';
import 'meal_provider.dart';
import 'profile_provider.dart';
import '../utils/nutrition_targets.dart';

/// Recettes générées à partir d'un inventaire détecté (photo de
/// frigo/placard, voir pantry_scan_screen.dart). Contrairement à
/// [mealSuggestionsProvider], pas de cache DB : l'inventaire varie à chaque
/// photo, donc chaque génération est un appel IA explicite via [generate].
final pantryRecipesProvider =
    AsyncNotifierProvider<PantryRecipesNotifier, List<MealSuggestion>>(
  PantryRecipesNotifier.new,
);

class PantryRecipesNotifier extends AsyncNotifier<List<MealSuggestion>> {
  List<String> _lastIngredients = const [];

  @override
  Future<List<MealSuggestion>> build() async => [];

  Future<void> generate(List<String> ingredientNames) async {
    _lastIngredients = ingredientNames;
    final profile = await ref.read(profileProvider.future);
    final aiService = ref.read(aiServiceProvider);
    final lang = ref.read(localeProvider).value?.languageCode ?? 'fr';
    final targets = computeNutritionTargets(profile);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final suggestions = await aiService.getMealSuggestions(
        goal: profile?.goal ?? 'maintain',
        targetKcal: targets.kcal,
        targetProt: targets.protein,
        targetGluc: targets.carbs,
        targetLip: targets.fat,
        dietType: profile?.dietType ?? 'none',
        allergies: profile?.allergies ?? const [],
        count: 3,
        availableIngredients: ingredientNames,
        lang: lang,
      );
      return aiService.getMealImages(suggestions);
    });
  }

  Future<void> regenerate() => generate(_lastIngredients);
}
