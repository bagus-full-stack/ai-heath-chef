import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/meal_provider.dart';

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

  Future<List<Map<String, dynamic>>> getTodayMeals() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // On calcule le début et la fin de la journée d'aujourd'hui
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      // On interroge la table 'meals' dans Supabase
      final response = await _supabase
          .from('meals')
          .select()
          .eq('user_id', user.id) // Uniquement MES repas
          .gte('created_at', startOfDay) // Depuis ce matin 00:00
          .lte('created_at', endOfDay)   // Jusqu'à ce soir 23:59
          .order('created_at', ascending: false); // Du plus récent au plus ancien

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des repas : ${e.toString()}');
    }
  }
}