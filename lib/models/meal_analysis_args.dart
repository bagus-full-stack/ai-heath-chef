import '../models/ingredient.dart';

/// Ce que l'écran d'analyse doit examiner : une photo à envoyer à l'IA
/// (repas ou produit emballé), un code-barres déjà scanné à chercher
/// directement dans la base Open Food Facts, ou une liste d'ingrédients
/// déjà connue (recherche manuelle par nom, ou saisie à la main) à charger
/// telle quelle, sans appel IA.
class MealAnalysisArgs {
  final String? imagePath;
  final String? barcode;
  final bool isProduct;
  final List<Ingredient>? manualIngredients;

  const MealAnalysisArgs({
    this.imagePath,
    this.barcode,
    this.isProduct = false,
    this.manualIngredients,
  });
}
