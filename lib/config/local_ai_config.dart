/// Paramètres du modèle IA local (Gemma3n, via flutter_gemma). Centralisés
/// ici pour pouvoir changer de variante (taille/qualité) en un seul endroit
/// plutôt que de chercher les références dans tout le code.
///
/// TODO(implémentation) : le nom de fichier exact (`modelFileName`) doit être
/// vérifié contre le contenu actuel de [huggingFaceRepo] sur Hugging Face
/// (onglet "Files" du repo) avant la première exécution réelle — le nom
/// exact peut changer d'une publication à l'autre du modèle.
class LocalAiConfig {
  LocalAiConfig._();

  /// Dépôt Hugging Face officiel de Gemma3n E2B au format LiteRT-LM
  /// (multimodal : vision + audio), utilisé à la fois pour le scan
  /// (analyse photo) et le chat coach.
  static const String huggingFaceRepo = 'google/gemma-3n-E2B-it-litert-lm';

  /// Nom du fichier modèle dans ce dépôt. À confirmer/ajuster à
  /// l'implémentation (voir TODO ci-dessus).
  static const String modelFileName = 'gemma-3n-E2B-it-int4.litertlm';

  static String get downloadUrl =>
      'https://huggingface.co/$huggingFaceRepo/resolve/main/$modelFileName';

  /// Taille annoncée, affichée à l'utilisateur avant le téléchargement.
  static const int approxSizeBytes = 3_100 * 1024 * 1024; // ~3,1 Go

  static const String approxSizeLabel = '~3,1 Go';
}
