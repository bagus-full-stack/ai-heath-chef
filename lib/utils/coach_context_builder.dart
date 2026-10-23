import '../config/coach_prompt.dart';
import '../models/meal.dart';
import '../models/user_profile.dart';
import '../utils/nutrition_targets.dart';

/// Nombre maximum de repas inclus dans le bloc — borne la taille même pour
/// une journée avec un nombre de repas inhabituel (voir
/// docs/AUDIT_CHATBOT.md étape 6, "size overflow").
const int kMaxMealsInContext = 8;

/// Longueur maximale d'un nom de repas inclus dans le bloc, après
/// neutralisation des délimiteurs.
const int kMaxMealNameLength = 40;

/// Données déjà résolues (DB locale, profil, préférences) nécessaires pour
/// construire le bloc de contexte du jour — aucun accès DB ici, uniquement
/// de la mise en forme, pour rester testable sans DB/réseau.
class DailyContextInput {
  final UserProfile? profile;
  final List<Meal> todayMeals;
  final int hydrationMl;
  final bool isFasting;
  final int fastingElapsedHours;
  final int fastingGoalHours;
  final String lang;

  const DailyContextInput({
    this.profile,
    this.todayMeals = const [],
    this.hydrationMl = 0,
    this.isFasting = false,
    this.fastingElapsedHours = 0,
    this.fastingGoalHours = 16,
    this.lang = 'fr',
  });
}

/// Construit le bloc de contexte du jour (profil, cibles, consommé/restant,
/// repas, hydratation, poids, jeûne) à injecter dans le prompt système à
/// chaque tour — voir docs/AUDIT_CHATBOT.md étape 6.
///
/// Minimisation des données : ni email, ni identifiant, ni photo — seulement
/// ce qui sert la conversation (voir [UserProfile], on ne lit jamais
/// `userId`/`email`/`fullName` ici).
///
/// Sécurité : le nom d'un repas est une donnée libre saisie par
/// l'utilisateur (comme les allergies, étape 4) — neutralisé via
/// [CoachPrompt.neutralizeDelimiters] avant interpolation, sinon ce bloc
/// redeviendrait un vecteur d'injection dès qu'un nom de repas y est inclus
/// (voir eval_cases.json, cas "injection_meal_name", désormais applicable).
///
/// [compact] produit une variante plus courte pour le modèle local
/// (contrainte de contexte plus serrée qu'un modèle cloud).
String buildDailyContextBlock(DailyContextInput input, {bool compact = false}) {
  final isEn = input.lang == 'en';
  final targets = computeNutritionTargets(input.profile);

  final meals = input.todayMeals.take(kMaxMealsInContext).toList();
  final consumedKcal = meals.fold<int>(0, (sum, m) => sum + m.totalKcal);
  final consumedProt = meals.fold<double>(0, (sum, m) => sum + m.totalProt);
  final consumedGluc = meals.fold<double>(0, (sum, m) => sum + m.totalGluc);
  final consumedLip = meals.fold<double>(0, (sum, m) => sum + m.totalLip);
  final remainingKcal = (targets.kcal - consumedKcal).clamp(0, targets.kcal);

  final mealsText = meals.isEmpty
      ? (isEn ? 'none yet' : 'aucun')
      : meals.map((m) => '${_safeMealName(m.name)} (${m.totalKcal} kcal)').join(', ');

  final profile = input.profile;
  final goalText = profile?.goal ?? 'maintain';
  final dietText = profile?.dietType ?? 'none';
  final cuisineText = profile?.cuisinePreference ?? 'none';
  final allergyList = profile?.allergies ?? const <String>[];
  final allergiesText =
      allergyList.map(CoachPrompt.neutralizeDelimiters).join(', ');
  final weightText = profile != null && profile.currentWeight > 0
      ? '${profile.currentWeight}'
      : null;
  final fastingText =
      input.isFasting ? '${input.fastingElapsedHours}h/${input.fastingGoalHours}h' : null;

  if (compact) {
    final buffer = StringBuffer()
      ..write('obj=$goalText regime=$dietText cuisine=$cuisineText ')
      ..write('allergies=[$allergiesText] ')
      ..write('cibles=${targets.kcal}kcal/${targets.protein.round()}p/${targets.carbs.round()}g/${targets.fat.round()}l ')
      ..write('conso=${consumedKcal}kcal(${consumedProt.round()}p/${consumedGluc.round()}g/${consumedLip.round()}l) restant=${remainingKcal}kcal ')
      ..write('repas=[$mealsText] eau=${input.hydrationMl}ml');
    if (weightText != null) buffer.write(' poids=${weightText}kg');
    if (fastingText != null) buffer.write(' jeune=$fastingText');
    return buffer.toString();
  }

  if (isEn) {
    final buffer = StringBuffer()
      ..write('Goal: $goalText. Diet: $dietText. Cuisine preference: $cuisineText. ')
      ..write('Allergies: ${allergiesText.isEmpty ? 'none' : allergiesText}. ')
      ..write(
          "Today's targets: ${targets.kcal} kcal, ${targets.protein.round()}g protein, ${targets.carbs.round()}g carbs, ${targets.fat.round()}g fat. ")
      ..write(
          'Consumed so far: $consumedKcal kcal (${consumedProt.round()}g protein, ${consumedGluc.round()}g carbs, ${consumedLip.round()}g fat). Remaining: $remainingKcal kcal. ')
      ..write("Today's meals: $mealsText. ")
      ..write('Hydration: ${input.hydrationMl} ml.');
    if (weightText != null) buffer.write(' Recent weight: $weightText kg.');
    if (fastingText != null) buffer.write(' Ongoing fast: $fastingText.');
    return buffer.toString();
  }

  final buffer = StringBuffer()
    ..write('Objectif : $goalText. Régime : $dietText. Cuisine préférée : $cuisineText. ')
    ..write('Allergies : ${allergiesText.isEmpty ? 'aucune' : allergiesText}. ')
    ..write(
        "Cibles du jour : ${targets.kcal} kcal, ${targets.protein.round()}g de protéines, ${targets.carbs.round()}g de glucides, ${targets.fat.round()}g de lipides. ")
    ..write(
        "Consommé jusqu'ici : $consumedKcal kcal (${consumedProt.round()}g prot, ${consumedGluc.round()}g gluc, ${consumedLip.round()}g lip). Restant : $remainingKcal kcal. ")
    ..write('Repas du jour : $mealsText. ')
    ..write('Hydratation : ${input.hydrationMl} ml.');
  if (weightText != null) buffer.write(' Poids récent : $weightText kg.');
  if (fastingText != null) buffer.write(' Jeûne en cours : $fastingText.');
  return buffer.toString();
}

String _safeMealName(String name) {
  final cleaned = CoachPrompt.neutralizeDelimiters(name).trim();
  return cleaned.length > kMaxMealNameLength
      ? '${cleaned.substring(0, kMaxMealNameLength)}…'
      : cleaned;
}
