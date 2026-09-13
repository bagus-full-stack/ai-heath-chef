/// Ce que l'écran d'analyse doit examiner : une photo à envoyer à l'IA
/// (repas ou produit emballé), ou un code-barres déjà scanné à chercher
/// directement dans la base Open Food Facts.
class MealAnalysisArgs {
  final String? imagePath;
  final String? barcode;
  final bool isProduct;

  const MealAnalysisArgs({
    this.imagePath,
    this.barcode,
    this.isProduct = false,
  });
}
