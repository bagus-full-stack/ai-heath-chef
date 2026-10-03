import 'dart:math' as math;

import '../models/user_profile.dart';

/// Objectifs nutritionnels quotidiens estimés pour un profil.
class NutritionTargets {
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;

  /// true si [kcal] a été relevé jusqu'au plancher de sécurité
  /// ([kMinCaloriesFemale]/[kMinCaloriesMale]) car le calcul brut tombait
  /// dessous — permet à l'UI d'afficher une mention dédiée.
  final bool flooredByMinimum;

  const NutritionTargets({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.flooredByMinimum = false,
  });

  /// Utilisée tant que le profil n'est pas disponible (chargement, erreur,
  /// profil incomplet, ou entrées hors bornes physiologiques — voir
  /// [computeNutritionTargets]).
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

// --- Bornes physiologiques des entrées. La borne haute reste alignée sur
// lib/screens/onboarding_screen.dart / account_screen.dart (kMaximumAge).
// La borne basse reste volontairement à 10 (plus permissive que
// kMinimumAge = 16, voir lib/utils/age_policy.dart) pour continuer à
// calculer une cible pour les comptes < 16 ans créés avant l'introduction
// de cette limite, tant qu'ils n'ont pas été traités (voir README). ---
const int _kMinAge = 10;
const int _kMaxAge = 120;
const double _kMaxWeightKg = 400;
const double _kMinHeightCm = 100;
const double _kMaxHeightCm = 250;

/// Plancher calorique de sécurité : la cible ne descend jamais sous ce seuil,
/// quel que soit l'objectif choisi (valeurs usuelles en nutrition clinique
/// pour un adulte, en-dessous desquelles un suivi médical est recommandé).
const int kMinCaloriesFemale = 1200;

/// Utilisé pour les profils masculins, ainsi que "autre"/non renseigné (on
/// retient le plancher le plus prudent par défaut).
const int kMinCaloriesMale = 1500;

/// Le déficit calorique appliqué pour un objectif de perte de poids est
/// borné par les deux contraintes suivantes (la plus stricte s'applique) :
/// au plus 25 % du TDEE, et au plus 1000 kcal/jour.
const double kMaxDeficitRatio = 0.25;
const int kMaxDeficitKcal = 1000;

/// Sous cet âge, aucun déficit calorique chiffré n'est appliqué même si
/// l'objectif choisi est "perte de poids" : la cible retombe sur le
/// maintien (un mineur en croissance ne devrait pas recevoir d'objectif de
/// restriction calorique sans encadrement médical).
const int kMinAgeForWeightLossGoal = 18;

/// Plancher de protéines, utilisé si le pourcentage par défaut (30 % des
/// kcal) tomberait plus bas.
const double kMinProteinGPerKg = 0.8;

/// Plancher de lipides, en pourcentage des kcal cibles.
const double kMinFatRatioOfKcal = 0.20;

/// Estime les objectifs nutritionnels quotidiens à partir du profil, via la
/// formule de Mifflin-St Jeor pour le métabolisme de base.
///
/// Approximations assumées faute de données collectées à l'onboarding :
/// - Taille : utilise `profile.heightCm` si renseignée, sinon retombe sur une
///   moyenne par sexe (voir [_assumedHeightCmBySex]) pour les profils créés
///   avant l'ajout de ce champ.
/// - Niveau d'activité : "modérément actif" (facteur 1.375) par défaut.
/// Le résultat est donc indicatif, pas une valeur médicale précise.
///
/// Retourne [NutritionTargets.fallback] si le profil est absent/incomplet ou
/// si l'âge/le poids/la taille sortent des bornes physiologiques plausibles
/// (voir les constantes `_kMin*`/`_kMax*` ci-dessus) plutôt que de produire
/// un calcul absurde à partir de ces valeurs.
NutritionTargets computeNutritionTargets(UserProfile? profile) {
  if (profile == null) {
    return NutritionTargets.fallback;
  }

  final age = profile.age;
  final weight = profile.currentWeight;
  final heightInput = profile.heightCm;

  final hasValidAge = age >= _kMinAge && age <= _kMaxAge;
  final hasValidWeight = weight > 0 && weight <= _kMaxWeightKg;
  // heightInput == 0 signifie "non renseignée" (voir _assumedHeightCmBySex),
  // ce n'est pas une valeur hors bornes.
  final hasValidHeight = heightInput == 0 || (heightInput >= _kMinHeightCm && heightInput <= _kMaxHeightCm);

  if (!hasValidAge || !hasValidWeight || !hasValidHeight) {
    return NutritionTargets.fallback;
  }

  final heightCm = heightInput > 0
      ? heightInput
      : _assumedHeightCmBySex[profile.sex] ?? _assumedHeightCmBySex['other']!;
  final sexOffset = profile.sex == 'female' ? -161 : 5;

  final bmr = 10 * weight + 6.25 * heightCm - 5 * age + sexOffset;

  const activityFactor = 1.375;
  final tdee = bmr * activityFactor;

  // Mineur : pas de déficit chiffré pour un objectif de perte de poids (voir
  // kMinAgeForWeightLossGoal) — la prise de masse reste autorisée, un
  // surplus calorique n'est pas le même risque qu'une restriction.
  final isMinor = age < kMinAgeForWeightLossGoal;

  var rawTarget = tdee;
  switch (profile.goal) {
    case 'loseWeight':
      if (!isMinor) {
        final rawDeficit = tdee * 0.2;
        final deficitCap = math.min(tdee * kMaxDeficitRatio, kMaxDeficitKcal.toDouble());
        final deficit = math.min(rawDeficit, deficitCap);
        rawTarget = tdee - deficit;
      }
      break;
    case 'gainMuscle':
      rawTarget = tdee * 1.12;
      break;
    default:
      break;
  }

  final minCalories = profile.sex == 'female' ? kMinCaloriesFemale : kMinCaloriesMale;
  final flooredByMinimum = rawTarget < minCalories;
  final kcal = (flooredByMinimum ? minCalories.toDouble() : rawTarget).round();

  // Macros : 30 % protéines / 40 % glucides / 30 % lipides par défaut, avec
  // un plancher sur les protéines (g/kg) et les lipides (% des kcal) ; les
  // glucides absorbent le reste (jamais négatif).
  final proteinG = math.max(kcal * 0.30 / 4, kMinProteinGPerKg * weight);
  final fatG = math.max(kcal * 0.30 / 9, kMinFatRatioOfKcal * kcal / 9);
  final remainingKcalForCarbs = kcal - proteinG * 4 - fatG * 9;
  final carbsG = remainingKcalForCarbs > 0 ? remainingKcalForCarbs / 4 : 0.0;

  return NutritionTargets(
    kcal: kcal,
    protein: proteinG,
    carbs: carbsG,
    fat: fatG,
    flooredByMinimum: flooredByMinimum,
  );
}
