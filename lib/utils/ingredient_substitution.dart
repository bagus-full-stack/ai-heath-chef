/// Table de substitution par catégorie d'ingrédient (mots-clés FR) —
/// couvre les allergènes courants (voir _kCommonAllergies dans
/// dietary_preferences_screen.dart) et les manques de stock classiques.
///
/// ponytail: table statique de mots-clés, pas de NLP — l'IA de génération de
/// repas connaît déjà les allergies déclarées (voir
/// AIService.getMealSuggestions) et est censée les éviter ; ceci est un
/// filet de sécurité (repas mis en cache avant un changement d'allergie,
/// ligne d'ingrédient ambiguë...) plus un dépannage manuel "je n'ai pas ça
/// dans mon placard", pas la défense principale contre les allergies.
const Map<String, ({List<String> keywords, String substitute})> _kSubstitutions = {
  'lait': (keywords: ['lait', 'crème', 'creme'], substitute: "lait d'avoine ou d'amande"),
  'beurre': (keywords: ['beurre'], substitute: "huile d'olive"),
  'fromage': (keywords: ['fromage', 'mozzarella', 'parmesan', 'emmental'], substitute: 'levure maltée ou fromage végétal'),
  'gluten': (keywords: ['farine de blé', 'farine', 'pâtes', 'pain', 'semoule'], substitute: 'farine ou pâtes sans gluten'),
  'oeuf': (keywords: ['œuf', 'oeuf', 'œufs', 'oeufs'], substitute: 'compote de pommes ou graines de lin trempées'),
  'arachide': (keywords: ['arachide', 'cacahuète', 'cacahuete'], substitute: 'graines de tournesol'),
  'fruits a coque': (keywords: ['amande', 'noix', 'noisette', 'pistache', 'cajou'], substitute: 'graines de courge'),
  'crustace': (keywords: ['crevette', 'crabe', 'homard', 'crustacé', 'crustace'], substitute: 'tofu ferme ou poulet'),
  'poisson': (keywords: ['poisson', 'saumon', 'thon', 'cabillaud'], substitute: 'tofu fumé ou poulet'),
  'soja': (keywords: ['soja', 'tofu', 'edamame'], substitute: 'pois chiches ou lentilles'),
  'viande': (keywords: ['poulet', 'bœuf', 'boeuf', 'porc', 'dinde'], substitute: 'tofu, tempeh ou légumineuses'),
};

/// Fait correspondre un libellé d'allergie courant (voir
/// dietary_preferences_screen.dart) à une catégorie de [_kSubstitutions].
const Map<String, String> _kAllergyToCategory = {
  'gluten': 'gluten',
  'lactose': 'lait',
  'fruits à coque': 'fruits a coque',
  'arachides': 'arachide',
  'œufs': 'oeuf',
  'fruits de mer': 'crustace',
  'crustacés': 'crustace',
  'soja': 'soja',
};

/// Retourne un substitut suggéré pour [ingredientLine] si un mot-clé connu y
/// est détecté (dépannage "je n'ai pas ça dans mon placard"), sinon `null`.
String? suggestSubstitute(String ingredientLine) {
  final lower = ingredientLine.toLowerCase();
  for (final entry in _kSubstitutions.values) {
    if (entry.keywords.any(lower.contains)) return entry.substitute;
  }
  return null;
}

/// Vrai si [ingredientLine] contient un mot-clé associé à une des
/// [allergies] déclarées par l'utilisateur.
bool ingredientMatchesAllergy(String ingredientLine, List<String> allergies) {
  final lower = ingredientLine.toLowerCase();
  for (final allergy in allergies) {
    final category = _kAllergyToCategory[allergy.toLowerCase()];
    final keywords = category != null ? _kSubstitutions[category]?.keywords : null;
    if (keywords != null && keywords.any(lower.contains)) return true;
    // Repli pour une allergie personnalisée (non répertoriée ci-dessus) :
    // son libellé apparaît tel quel dans la ligne d'ingrédient.
    if (lower.contains(allergy.toLowerCase())) return true;
  }
  return false;
}
