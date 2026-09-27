import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meal_suggestion.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupère les idées de repas déjà générées aujourd'hui pour cet
  /// utilisateur, si elles existent (cache quotidien) ET si elles ont été
  /// générées avec les mêmes préférences alimentaires qu'actuellement.
  /// Retourne `null` s'il n'y a rien en base pour ce jour, ou si les
  /// préférences ont changé depuis (il faudra alors rappeler l'IA) — sinon
  /// un changement de régime/allergies en cours de journée continuerait à
  /// servir des suggestions qui ne le respectent plus.
  Future<List<MealSuggestion>?> getCachedMealSuggestions(
    String dayKey,
    String preferencesSignature,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('meal_suggestions')
        .select('suggestions, preferences_signature')
        .eq('user_id', user.id)
        .eq('day', dayKey)
        .maybeSingle();

    if (response == null) return null;
    if ((response['preferences_signature'] as String?) != preferencesSignature) {
      return null;
    }

    final suggestions = response['suggestions'] as List<dynamic>;
    if (suggestions.isEmpty) return null;

    return suggestions
        .map((item) => MealSuggestion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Sauvegarde (ou remplace) les idées de repas générées pour aujourd'hui,
  /// avec la signature des préférences utilisées pour les générer.
  Future<void> saveMealSuggestions(
    String dayKey,
    List<MealSuggestion> suggestions,
    String preferencesSignature,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final suggestionsJson = suggestions.map(_suggestionToJson).toList();

    await _supabase.from('meal_suggestions').upsert({
      'user_id': user.id,
      'day': dayKey,
      'suggestions': suggestionsJson,
      'preferences_signature': preferencesSignature,
    }, onConflict: 'user_id,day');
  }

  Map<String, dynamic> _suggestionToJson(MealSuggestion s) => {
    'timeSlot': s.timeSlot,
    'title': s.title,
    'kcal': s.kcal,
    'prot': s.prot,
    'gluc': s.gluc,
    'lip': s.lip,
    'description': s.description,
    'imageUrl': s.imageUrl,
    'ingredients': s.ingredients,
    'steps': s.steps,
    'day': s.day,
  };

  /// Récupère le plan de repas déjà généré pour cette semaine (clé =
  /// lundi de la semaine), si les préférences alimentaires n'ont pas changé
  /// depuis — même logique que [getCachedMealSuggestions] (cache quotidien).
  Future<List<MealSuggestion>?> getCachedWeeklyMealPlan(
    String weekStartKey,
    String preferencesSignature,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('weekly_meal_plans')
        .select('suggestions, preferences_signature')
        .eq('user_id', user.id)
        .eq('week_start', weekStartKey)
        .maybeSingle();

    if (response == null) return null;
    if ((response['preferences_signature'] as String?) != preferencesSignature) {
      return null;
    }

    final suggestions = response['suggestions'] as List<dynamic>;
    if (suggestions.isEmpty) return null;

    return suggestions
        .map((item) => MealSuggestion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Sauvegarde (ou remplace) le plan de repas généré pour cette semaine.
  Future<void> saveWeeklyMealPlan(
    String weekStartKey,
    List<MealSuggestion> suggestions,
    String preferencesSignature,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('weekly_meal_plans').upsert({
      'user_id': user.id,
      'week_start': weekStartKey,
      'suggestions': suggestions.map(_suggestionToJson).toList(),
      'preferences_signature': preferencesSignature,
    }, onConflict: 'user_id,week_start');
  }
}
