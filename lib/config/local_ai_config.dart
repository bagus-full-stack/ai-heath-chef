/// Paramètres du modèle IA local (Gemma3n, via flutter_gemma). Centralisés
/// ici pour pouvoir changer de variante (taille/qualité) en un seul endroit
/// plutôt que de chercher les références dans tout le code.
class LocalAiConfig {
  LocalAiConfig._();

  /// Dépôt Hugging Face officiel de Gemma3n E2B au format LiteRT-LM
  /// (multimodal : vision + audio), utilisé à la fois pour le scan
  /// (analyse photo) et le chat coach.
  static const String huggingFaceRepo = 'google/gemma-3n-E2B-it-litert-lm';

  /// Nom du fichier modèle dans ce dépôt, vérifié contre l'onglet "Files"
  /// du repo Hugging Face (3,66 Go au 2026-10-03).
  static const String modelFileName = 'gemma-3n-E2B-it-int4.litertlm';

  static String get downloadUrl =>
      'https://huggingface.co/$huggingFaceRepo/resolve/main/$modelFileName';

  /// Taille annoncée, affichée à l'utilisateur avant le téléchargement.
  static const int approxSizeBytes = 3_660 * 1024 * 1024; // ~3,66 Go

  static const String approxSizeLabel = '~3,66 Go';
}
