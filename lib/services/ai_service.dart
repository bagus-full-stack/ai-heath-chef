import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/ingredient.dart';
import '../models/meal_suggestion.dart';

class AIService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fonction principale qui prend le chemin de l'image et retourne une liste d'ingrédients
  Future<List<Ingredient>> analyzeMealImage(String imagePath, {String lang = 'fr'}) {
    return _analyzeImage(
      imagePath,
      'analyze-meal',
      (l10n, error) => l10n.svcErrorAnalyzeMeal(error),
      lang,
    );
  }

  /// Analyse la photo d'un produit emballé (étiquette nutritionnelle) et
  /// retourne un ingrédient représentant le produit entier.
  Future<List<Ingredient>> analyzeProductImage(String imagePath, {String lang = 'fr'}) {
    return _analyzeImage(
      imagePath,
      'analyze-product',
      (l10n, error) => l10n.svcErrorAnalyzeProduct(error),
      lang,
    );
  }

  /// Analyse la photo d'une carte de restaurant et retourne un "ingrédient"
  /// par plat identifié (portion estimée + macros pour cette portion) —
  /// même contrat JSON que [analyzeMealImage], voir analyze-menu/index.ts.
  Future<List<Ingredient>> analyzeMenuImage(String imagePath, {String lang = 'fr'}) {
    return _analyzeImage(
      imagePath,
      'analyze-menu',
      (l10n, error) => l10n.svcErrorAnalyzeMenu(error),
      lang,
    );
  }

  /// Analyse la photo d'un frigo/placard et retourne un "ingrédient" par
  /// aliment identifié (inventaire, pas un repas à consommer) — même contrat
  /// JSON que [analyzeMealImage], voir analyze-pantry/index.ts. Seul `name`
  /// est réellement utilisé côté client (voir pantry_scan_screen.dart).
  Future<List<Ingredient>> analyzePantryImage(String imagePath, {String lang = 'fr'}) {
    return _analyzeImage(
      imagePath,
      'analyze-pantry',
      (l10n, error) => l10n.svcErrorAnalyzePantry(error),
      lang,
    );
  }

  Future<List<Ingredient>> _analyzeImage(
    String imagePath,
    String functionName,
    String Function(AppLocalizations l10n, String error) buildErrorMessage,
    String lang,
  ) async {
    final l10n = lookupAppLocalizations(Locale(lang));
    try {
      // 1. COMPRESSION DE L'IMAGE
      // On réduit la taille (max 800x800) et la qualité (70%) pour un envoi ultra-rapide.
      // `compressWithFile` n'est pas supporté sur Flutter Web (dart:io uniquement) :
      // on lit d'abord les octets via XFile (gère aussi bien un chemin natif qu'une
      // URL blob: web), puis on compresse via `compressWithList`, supporté partout.
      final rawBytes = await XFile(imagePath).readAsBytes();
      final compressedBytes = await FlutterImageCompress.compressWithList(
        rawBytes,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
      );

      // 2. ENCODAGE EN BASE64
      // L'API attend du texte, on transforme donc notre image en longue chaîne de caractères
      final String base64Image = base64Encode(compressedBytes);

      // 3. APPEL À SUPABASE EDGE FUNCTIONS
      final response = await _supabase.functions.invoke(
        functionName,
        body: {'image': base64Image, 'lang': lang},
      );

      // 4. PARSING DU RÉSULTAT JSON
      // On transforme le JSON renvoyé par l'IA en nos objets Dart 'Ingredient'
      final List<dynamic> data = response.data['ingredients'];

      return data.map((item) => Ingredient(
        id: item['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(), // ID unique
        name: item['name'],
        weight: (item['weight'] as num).toInt(),
        kcalPer100g: (item['kcalPer100g'] as num).toDouble(),
        protPer100g: (item['protPer100g'] as num).toDouble(),
        glucPer100g: (item['glucPer100g'] as num).toDouble(),
        lipPer100g: (item['lipPer100g'] as num).toDouble(),
        fiberPer100g: (item['fiberPer100g'] as num?)?.toDouble() ?? 0,
        sugarPer100g: (item['sugarPer100g'] as num?)?.toDouble() ?? 0,
        satFatPer100g: (item['satFatPer100g'] as num?)?.toDouble() ?? 0,
      )).toList();

    } catch (e) {
      throw Exception(buildErrorMessage(l10n, _describeError(e)));
    }
  }

  /// `suggestedDish` est le nom du plat recommandé par le coach dans sa
  /// réponse, extrait côté edge function (balise `[DISH: ...]`), ou `null`
  /// si aucun plat précis n'a été recommandé. Utilisé par chat_provider.dart
  /// pour illustrer la réponse via [getDishImage].
  Future<({String reply, String? suggestedDish})> chatWithCoach(
    String message,
    List<Map<String, dynamic>> history, {
    String coachTone = 'motivant',
    String dietType = 'none',
    List<String> allergies = const [],
    String lang = 'fr',
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'coach-chat',
        body: {
          'message': message,
          'history': history,
          'coachTone': coachTone,
          'dietType': dietType,
          'allergies': allergies,
          'lang': lang,
        },
      );

      return (
        reply: response.data['reply'] as String,
        suggestedDish: response.data['suggestedDish'] as String?,
      );
    } catch (e) {
      throw Exception(lookupAppLocalizations(Locale(lang)).svcErrorCoachChat(_describeError(e)));
    }
  }

  /// Génère une illustration IA pour un plat unique recommandé par le coach
  /// (voir chat_provider.dart), en réutilisant l'edge function `meal-images`.
  /// Comme [getMealImages], c'est un bonus visuel : repli sur `null` en cas
  /// d'échec plutôt que de faire échouer la réponse du coach.
  Future<String?> getDishImage(String dishName) async {
    try {
      final response = await _supabase.functions.invoke(
        'meal-images',
        body: {
          'meals': [
            {'title': dishName},
          ],
        },
      );
      final List<dynamic> images = response.data['images'];
      return images.isNotEmpty ? images.first as String? : null;
    } catch (_) {
      return null;
    }
  }

  /// Génère des idées de repas personnalisées via l'IA, en fonction de
  /// l'objectif de l'utilisateur, de ses cibles nutritionnelles du jour et
  /// de son régime/allergies déclarés.
  Future<List<MealSuggestion>> getMealSuggestions({
    required String goal,
    required int targetKcal,
    required double targetProt,
    required double targetGluc,
    required double targetLip,
    String dietType = 'none',
    List<String> allergies = const [],
    String cuisinePreference = 'none',
    int count = 6,
    // Plan hebdomadaire (voir weekly_meal_plan_provider.dart) : quand fourni,
    // `days`/`mealsPerDay` remplacent `count` et chaque suggestion revient
    // avec son champ `day` (1..days) rempli.
    int? days,
    int? mealsPerDay,
    // Recette à partir d'une photo de frigo/placard (voir
    // pantry_recipes_provider.dart) : ingrédients déjà disponibles à
    // prioriser dans les recettes générées.
    List<String>? availableIngredients,
    String lang = 'fr',
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'meal-suggestions',
        body: {
          'goal': goal,
          'targetKcal': targetKcal,
          'targetProt': targetProt,
          'targetGluc': targetGluc,
          'targetLip': targetLip,
          'dietType': dietType,
          'allergies': allergies,
          'cuisinePreference': cuisinePreference,
          'count': count,
          'days': ?days,
          'mealsPerDay': ?mealsPerDay,
          if (availableIngredients != null && availableIngredients.isNotEmpty)
            'availableIngredients': availableIngredients,
          'lang': lang,
        },
      );

      final List<dynamic> data = response.data['suggestions'];
      return data
          .map((item) => MealSuggestion.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(lookupAppLocalizations(Locale(lang)).svcErrorMealSuggestions(_describeError(e)));
    }
  }

  /// Génère une illustration IA (Pollinations.ai) pour chaque suggestion et
  /// retourne les suggestions enrichies de leur `imageUrl` (data URI). Une
  /// suggestion dont l'image échoue à se générer garde `imageUrl == null`
  /// (la carte retombe alors sur l'icône par défaut) plutôt que de faire
  /// échouer tout l'appel.
  Future<List<MealSuggestion>> getMealImages(List<MealSuggestion> suggestions) async {
    if (suggestions.isEmpty) return suggestions;

    try {
      final response = await _supabase.functions.invoke(
        'meal-images',
        body: {
          'meals': suggestions
              .map((s) => {'title': s.title, 'description': s.description})
              .toList(),
        },
      );

      final List<dynamic> images = response.data['images'];
      return [
        for (var i = 0; i < suggestions.length; i++)
          suggestions[i].withImageUrl(i < images.length ? images[i] as String? : null),
      ];
    } catch (e) {
      // La génération d'images est un bonus visuel, pas une fonctionnalité
      // critique : en cas d'échec, on garde les suggestions telles quelles.
      return suggestions;
    }
  }

  /// Extrait un message d'erreur lisible d'une [FunctionException] (le champ
  /// `error` renvoyé par nos Edge Functions, ex. quota dépassé), au lieu de
  /// laisser fuiter la représentation brute de l'exception à l'utilisateur.
  String _describeError(Object error) {
    if (error is FunctionException) {
      final details = error.details;
      if (details is Map && details['error'] is String) {
        return details['error'] as String;
      }
      return error.reasonPhrase ?? error.toString();
    }
    return error.toString();
  }
}