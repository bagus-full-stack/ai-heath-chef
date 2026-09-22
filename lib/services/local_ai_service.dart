import 'dart:convert';
import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/local_ai_config.dart';
import '../models/ingredient.dart';

/// Service IA 100% local (Gemma3n via flutter_gemma), indépendant de
/// [AIService] (cloud) — un simple "sibling", jamais une sous-classe.
/// [AIService] n'est pas modifié : le choix local-vs-cloud se fait dans les
/// providers (meal_provider, chat_provider), pas ici.
///
/// API flutter_gemma vérifiée directement dans le code source du package
/// installé (v1.8.2, voir le cache pub) plutôt que devinée depuis la doc en
/// ligne. Point resté incertain : aucun paramètre "system instruction" dédié
/// n'existe sur `createChat`/`Message` — on injecte donc l'instruction système
/// comme premier message côté "model" (isUser: false), une approche standard
/// pour ce type d'API mais non explicitement documentée comme telle.
class LocalAiService {
  static const _promptMeal = '''
Tu es un nutritionniste expert et un chef cuisinier.
Ton but est d'analyser la nourriture présente sur cette photo.
Identifie les ingrédients principaux, estime une portion réaliste en grammes (weight), et fournis les macronutriments (kcal, protéines, glucides, lipides, fibres, sucres, acides gras saturés) POUR 100 GRAMMES de cet ingrédient.
Tu DOIS répondre UNIQUEMENT au format JSON strict, sans aucun autre texte autour ni balises markdown.
Le JSON doit avoir cette structure exacte :
{
  "ingredients": [
    {
      "id": "1",
      "name": "Nom de l'ingrédient",
      "weight": 150,
      "kcalPer100g": 120,
      "protPer100g": 10.5,
      "glucPer100g": 2.0,
      "lipPer100g": 5.0,
      "fiberPer100g": 1.2,
      "sugarPer100g": 1.5,
      "satFatPer100g": 2.0
    }
  ]
}''';

  static const _promptProduct = '''
Tu es un nutritionniste expert. Cette photo montre un produit alimentaire emballé — le plus souvent son étiquette nutritionnelle (tableau des valeurs nutritionnelles au dos du produit), parfois juste la face avant de l'emballage.
Lis attentivement le tableau nutritionnel s'il est visible (valeurs "pour 100g" ou "pour 100ml"). S'il n'y a pas de tableau visible, estime au mieux à partir du nom/type de produit visible sur l'emballage.
Retourne UN SEUL ingrédient représentant ce produit dans son ensemble : son nom (marque + nom du produit si visible), sa portion habituelle en grammes (weight — utilise la portion indiquée sur l'étiquette si présente, sinon 100), et ses macronutriments (kcal, protéines, glucides, lipides, fibres, sucres, acides gras saturés) POUR 100 GRAMMES.
Tu DOIS répondre UNIQUEMENT au format JSON strict, sans aucun autre texte autour ni balises markdown.
Le JSON doit avoir cette structure exacte :
{
  "ingredients": [
    {
      "id": "1",
      "name": "Nom du produit",
      "weight": 100,
      "kcalPer100g": 250,
      "protPer100g": 8.0,
      "glucPer100g": 30.0,
      "lipPer100g": 10.0,
      "fiberPer100g": 2.5,
      "sugarPer100g": 12.0,
      "satFatPer100g": 3.0
    }
  ]
}''';

  static const Map<String, String> _toneInstructions = {
    'motivant':
        "Tu es empathique et motivant : tu encourages l'utilisateur et le pousses gentiment à avancer.",
    'bienveillant':
        "Tu es calme, doux et bienveillant : tu rassures l'utilisateur, sans jamais le juger sur ses écarts.",
    'direct':
        "Tu es direct et concis : tu vas droit au but avec des conseils actionnables, sans détour ni fioriture.",
    'humoristique':
        "Tu es léger et plein d'humour, tout en restant utile et sérieux sur le fond nutritionnel.",
  };

  static const Map<String, String> _dietLabels = {
    'vegetarian': 'végétarien (sans viande ni poisson)',
    'vegan': 'végétalien (sans aucun produit d\'origine animale)',
    'pescetarian': 'pescétarien (sans viande, poisson autorisé)',
    'halal': 'halal',
    'kosher': 'kasher',
  };

  /// Vérifie si le modèle est déjà téléchargé sur l'appareil.
  Future<bool> isModelReady() {
    return FlutterGemma.isModelInstalled(LocalAiConfig.modelFileName);
  }

  /// Extrait le texte d'une [ModelResponse] : notre usage (chat simple, sans
  /// appel de fonction ni mode "thinking") produit toujours un [TextResponse].
  String _extractText(ModelResponse response) {
    if (response is TextResponse) return response.token;
    throw Exception('Réponse IA locale inattendue : $response');
  }

  /// Télécharge le modèle Gemma3n depuis Hugging Face, en récupérant
  /// d'abord le token via l'Edge Function `huggingface-token` (jamais
  /// embarqué dans l'app). [onProgress] reçoit une valeur 0.0-1.0.
  Future<void> downloadModel({required void Function(double progress) onProgress}) async {
    final tokenResponse = await Supabase.instance.client.functions.invoke('huggingface-token');
    final token = tokenResponse.data?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception("Impossible de récupérer le token Hugging Face.");
    }

    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
    ).fromNetwork(
      LocalAiConfig.downloadUrl,
      token: token,
      // Service au premier plan : le modèle (~3 Go) dépasserait largement
      // la limite Android de 9 minutes en arrière-plan sans ce mode (voir
      // AndroidManifest.xml pour la permission/service associés).
      foreground: true,
    ).withProgress((progress) {
      onProgress(progress / 100);
    }).install();
  }

  /// Supprime le modèle téléchargé pour libérer de l'espace.
  Future<void> deleteModel() async {
    await FlutterGemma.uninstallModel(LocalAiConfig.modelFileName);
    await FlutterGemma.clearActiveInferenceIdentity();
  }

  Future<List<Ingredient>> analyzeMealImage(String imagePath) {
    return _analyzeImage(imagePath, _promptMeal);
  }

  Future<List<Ingredient>> analyzeProductImage(String imagePath) {
    return _analyzeImage(imagePath, _promptProduct);
  }

  Future<List<Ingredient>> _analyzeImage(String imagePath, String prompt) async {
    final imageBytes = await File(imagePath).readAsBytes();

    final model = await FlutterGemma.getActiveModel(
      maxTokens: 2048,
      preferredBackend: PreferredBackend.gpu,
      supportImage: true,
    );
    final chat = await model.createChat(supportImage: true);
    await chat.addQueryChunk(Message.withImages(
      text: prompt,
      imageBytes: [imageBytes],
      isUser: true,
    ));
    final response = _extractText(await chat.generateChatResponse());

    final jsonString = response.replaceAll(RegExp(r'```json', caseSensitive: false), '').replaceAll('```', '').trim();
    final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
    final List<dynamic> data = parsed['ingredients'] as List<dynamic>;

    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return Ingredient(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: map['name'] as String,
        weight: (map['weight'] as num).toInt(),
        kcalPer100g: (map['kcalPer100g'] as num).toDouble(),
        protPer100g: (map['protPer100g'] as num).toDouble(),
        glucPer100g: (map['glucPer100g'] as num).toDouble(),
        lipPer100g: (map['lipPer100g'] as num).toDouble(),
        fiberPer100g: (map['fiberPer100g'] as num?)?.toDouble() ?? 0,
        sugarPer100g: (map['sugarPer100g'] as num?)?.toDouble() ?? 0,
        satFatPer100g: (map['satFatPer100g'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  Future<String> chatWithCoach(
    String message,
    List<Map<String, dynamic>> history, {
    String coachTone = 'motivant',
    String dietType = 'none',
    List<String> allergies = const [],
  }) async {
    final toneInstruction = _toneInstructions[coachTone] ?? _toneInstructions['motivant']!;
    final dietLabel = _dietLabels[dietType];

    var dietaryNote = '';
    if (dietLabel != null) {
      dietaryNote += " L'utilisateur suit un régime $dietLabel : ne recommande jamais un aliment qui l'enfreint.";
    }
    if (allergies.isNotEmpty) {
      dietaryNote += " L'utilisateur est allergique/intolérant à : ${allergies.join(', ')}. Ne recommande jamais ces aliments.";
    }

    final systemInstruction =
        "Tu es AI Health Chef, un coach en nutrition expert. $toneInstruction Tu réponds de manière concise (maximum 3 phrases) et claire. Tu tutoies l'utilisateur.$dietaryNote Tu ne dois jamais utiliser de balises Markdown complexes, reste en texte simple.";

    final model = await FlutterGemma.getActiveModel(maxTokens: 2048);
    final chat = await model.createChat();

    // Pas de paramètre "system instruction" confirmé dans la doc à ce
    // stade : on l'injecte comme premier message côté modèle, pour établir
    // la persona avant le reste de l'historique.
    await chat.addQueryChunk(Message.text(text: systemInstruction, isUser: false));

    for (final entry in history) {
      final role = entry['role'] as String?;
      final parts = entry['parts'] as List<dynamic>?;
      final text = parts != null && parts.isNotEmpty ? (parts.first as Map)['text'] as String? : null;
      if (text != null && text.isNotEmpty) {
        await chat.addQueryChunk(Message.text(text: text, isUser: role == 'user'));
      }
    }

    await chat.addQueryChunk(Message.text(text: message, isUser: true));
    return _extractText(await chat.generateChatResponse());
  }
}
