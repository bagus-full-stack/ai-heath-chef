import '../models/user_profile.dart';

/// Objectifs nutritionnels quotidiens estimés pour un profil.
class NutritionTargets {
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionTargets({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Utilisée tant que le profil n'est pas disponible (chargement, erreur,
  /// ou profil incomplet).
  static const NutritionTargets fallback = NutritionTargets(
    kcal: 2200,
    protein: 160,
    carbs: 250,
    fat: 75,
  );
}

const Map<String, double> _assumedHeightCmBySex = {
  'male': 175,
  'female': 162,
  'other': 168,
};

/// Estime les objectifs nutritionnels quotidiens à partir du profil, via la
/// formule de Mifflin-St Jeor pour le métabolisme de base.
///
/// Approximations assumées faute de données collectées à l'onboarding :
/// - Taille : moyenne par sexe (voir [_assumedHeightCmBySex]) — pas de champ
///   taille dans le modèle actuel.
/// - Niveau d'activité : "modérément actif" (facteur 1.375) par défaut.
/// Le résultat est donc indicatif, pas une valeur médicale précise.
NutritionTargets computeNutritionTargets(UserProfile? profile) {
  if (profile == null || profile.age <= 0 || profile.currentWeight <= 0) {
    return NutritionTargets.fallback;
  }

  final heightCm = _assumedHeightCmBySex[profile.sex] ?? _assumedHeightCmBySex['other']!;
  final sexOffset = profile.sex == 'female' ? -161 : 5;

  final bmr = 10 * profile.currentWeight + 6.25 * heightCm - 5 * profile.age + sexOffset;

  const activityFactor = 1.375;
  var tdee = bmr * activityFactor;

  switch (profile.goal) {
    case 'loseWeight':
      tdee *= 0.8;
      break;
    case 'gainMuscle':
      tdee *= 1.12;
      break;
    default:
      break;
  }

  return NutritionTargets(
    kcal: tdee.round(),
    protein: (tdee * 0.30) / 4,
    carbs: (tdee * 0.40) / 4,
    fat: (tdee * 0.30) / 9,
  );
}
