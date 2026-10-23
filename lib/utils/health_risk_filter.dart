/// Filet de sécurité déterministe, appliqué AVANT tout appel à un modèle
/// (local ou cloud) : voir chat_provider.dart et
/// supabase/functions/coach-chat/index.ts (filtre équivalent côté serveur).
/// Un petit modèle on-device ne peut pas être la seule défense contre un
/// message évoquant un risque vital ou un trouble du comportement
/// alimentaire — voir docs/AUDIT_CHATBOT.md, étape 1.
///
/// Détection par sous-chaînes sur texte normalisé, pas de NLP : rapide,
/// testable, mais contournable par une formulation suffisamment différente
/// (limite documentée, pas un dispositif de modération complet).
library;

enum HealthRiskCategory { selfHarm, eatingDisorder, dangerousGoal }

HealthRiskCategory? detectHealthRisk(String message) {
  final normalized = _normalize(message);
  if (_containsAny(normalized, _selfHarmPhrases)) {
    return HealthRiskCategory.selfHarm;
  }
  if (_containsAny(normalized, _eatingDisorderPhrases)) {
    return HealthRiskCategory.eatingDisorder;
  }
  if (_containsAny(normalized, _dangerousGoalPhrases) ||
      _hasDangerousWeightLossRate(normalized)) {
    return HealthRiskCategory.dangerousGoal;
  }
  return null;
}

/// Minuscules, accents français retirés, tout caractère non alphanumérique
/// remplacé par une espace (donc une apostrophe sépare plutôt que de fusionner
/// les mots, ex. "j'ai" -> "j ai") : les listes de phrases ci-dessous sont
/// écrites dans cette même forme normalisée.
String _normalize(String input) {
  var s = input.toLowerCase();
  const accents = {
    'à': 'a', 'â': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i',
    'ô': 'o', 'ö': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c',
    'œ': 'oe',
  };
  accents.forEach((accented, plain) => s = s.replaceAll(accented, plain));
  s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

bool _containsAny(String normalized, List<String> phrases) =>
    phrases.any(normalized.contains);

const _selfHarmPhrases = <String>[
  'je veux me suicider',
  'j ai envie de me suicider',
  'je veux mourir',
  'j ai envie de mourir',
  'je veux en finir',
  'j ai envie d en finir',
  'je veux me tuer',
  'je pense au suicide',
  'idees suicidaires',
  'je veux me faire du mal',
  'je me scarifie',
  'je m automutile',
  'je veux disparaitre a jamais',
  'i want to kill myself',
  'i want to die',
  'i want to end it all',
  'i m suicidal',
  'i am suicidal',
  'suicidal thoughts',
  'i want to hurt myself',
  'i self harm',
  'i m cutting myself',
  'i don t want to live anymore',
  'ending my life',
];

const _eatingDisorderPhrases = <String>[
  'je me fais vomir',
  'je me fais vomir apres manger',
  'je vomis apres chaque repas',
  'je ne mange plus rien depuis des jours',
  'je ne mange presque plus rien',
  'je culpabilise a chaque fois que je mange',
  'obsession du poids',
  'je prends des laxatifs pour maigrir',
  'je saute tous mes repas pour maigrir',
  'je me prive de manger',
  'i make myself throw up',
  'i purge after eating',
  'i throw up after every meal',
  'i haven t eaten in days',
  'i feel guilty every time i eat',
  'i take laxatives to lose weight',
  'i starve myself',
  'i m obsessed with my weight',
];

const _dangerousGoalPhrases = <String>[
  'jeune prolonge',
  'jeune extreme',
  'jeune de 7 jours',
  'jeune de plusieurs jours',
  'regime a 500 kcal',
  'regime a 400 kcal',
  'je ne mange que 300 kcal par jour',
  'maigrir tres vite',
  'extended fast',
  'prolonged fast',
  'water fast for 7 days',
  '500 calorie diet',
  'eating only 300 calories a day',
  'lose weight super fast',
];

final _frWeightLossRate =
    RegExp(r'perdre\s+(\d{1,3})\s*kg\s+en\s+(\d{1,2})\s*(jour|jours|semaine|semaines)');
final _enWeightLossRate =
    RegExp(r'lose\s+(\d{1,3})\s*kg\s+in\s+(\d{1,2})\s*(day|days|week|weeks)');

/// Plus de 1,5 kg/semaine est considéré comme un rythme de perte de poids
/// dangereux par la plupart des recommandations médicales généralistes
/// (ex. NHS : 0,5 à 1 kg/semaine) ; seuil volontairement simple plutôt
/// qu'une table de recommandations par profil, hors périmètre d'un filtre
/// de sécurité.
const _maxSafeKgPerWeek = 1.5;

bool _hasDangerousWeightLossRate(String normalized) {
  final prepped = normalized
      .replaceAll('en une semaine', 'en 1 semaine')
      .replaceAll('en un jour', 'en 1 jour')
      .replaceAll('in a week', 'in 1 week')
      .replaceAll('in a day', 'in 1 day');

  final match = _frWeightLossRate.firstMatch(prepped) ?? _enWeightLossRate.firstMatch(prepped);
  if (match == null) return false;

  final kg = int.parse(match.group(1)!);
  final amount = int.parse(match.group(2)!);
  final unit = match.group(3)!;
  final weeks = unit.startsWith('semaine') || unit.startsWith('week') ? amount : amount / 7;
  if (weeks <= 0) return false;

  return kg / weeks > _maxSafeKgPerWeek;
}
