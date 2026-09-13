import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ingredient.dart';
import '../models/meal.dart';
import '../models/meal_suggestion.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sauvegarde le repas et ses macros dans Supabase
  Future<void> saveMeal(List<Ingredient> ingredients, String mealName) async {
    try {
      // 1. On vérifie qui est connecté
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Vous devez être connecté pour sauvegarder un repas.');

      // 2. On calcule les totaux finaux
      final totalKcal = ingredients.fold<int>(0, (sum, item) => sum + item.currentKcal);
      final totalProt = ingredients.fold<double>(0, (sum, item) => sum + item.currentProt);
      final totalGluc = ingredients.fold<double>(0, (sum, item) => sum + item.currentGluc);
      final totalLip = ingredients.fold<double>(0, (sum, item) => sum + item.currentLip);

      // 3. On formate les ingrédients en JSON pour la base de données
      final ingredientsJson = ingredients.map((i) => {
        'name': i.name,
        'weight': i.weight,
        'kcal': i.currentKcal,
        'prot': i.currentProt,
        'gluc': i.currentGluc,
        'lip': i.currentLip,
      }).toList();

      // 4. On envoie tout à Supabase
      await _supabase.from('meals').insert({
        'user_id': user.id,
        'name': mealName,
        'total_kcal': totalKcal,
        'total_prot': totalProt,
        'total_gluc': totalGluc,
        'total_lip': totalLip,
        'ingredients': ingredientsJson,
      });

    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde : ${e.toString()}');
    }
  }

  Future<List<Meal>> getTodayMeals() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // On calcule le début et la fin de la journée d'aujourd'hui en heure
      // locale, puis on convertit en UTC : 'created_at' est un timestamptz
      // stocké en UTC côté Supabase, donc on doit comparer des UTC entre eux.
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();

      // On interroge la table 'meals' dans Supabase
      final response = await _supabase
          .from('meals')
          .select('id, name, total_kcal, total_prot, total_gluc, total_lip, created_at')
          .eq('user_id', user.id) // Uniquement MES repas
          .gte('created_at', startOfDay) // Depuis ce matin 00:00
          .lte('created_at', endOfDay)   // Jusqu'à ce soir 23:59
          .order('created_at', ascending: false); // Du plus récent au plus ancien

      return (response as List<dynamic>).map((json) => Meal.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des repas : ${e.toString()}');
    }
  }

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
    if ((response['preferences_signature'] as String?) != preferencesSignature) return null;

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

    final suggestionsJson = suggestions.map((s) => {
      'timeSlot': s.timeSlot,
      'title': s.title,
      'kcal': s.kcal,
      'prot': s.prot,
      'gluc': s.gluc,
      'lip': s.lip,
      'description': s.description,
    }).toList();

    await _supabase.from('meal_suggestions').upsert(
      {
        'user_id': user.id,
        'day': dayKey,
        'suggestions': suggestionsJson,
        'preferences_signature': preferencesSignature,
      },
      onConflict: 'user_id,day',
    );
  }
}