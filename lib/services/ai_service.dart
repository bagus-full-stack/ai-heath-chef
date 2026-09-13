import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ingredient.dart';
import '../models/meal_suggestion.dart';

class AIService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fonction principale qui prend le chemin de l'image et retourne une liste d'ingrédients
  Future<List<Ingredient>> analyzeMealImage(String imagePath) {
    return _analyzeImage(imagePath, 'analyze-meal', "Erreur lors de l'analyse IA");
  }

  /// Analyse la photo d'un produit emballé (étiquette nutritionnelle) et
  /// retourne un ingrédient représentant le produit entier.
  Future<List<Ingredient>> analyzeProductImage(String imagePath) {
    return _analyzeImage(imagePath, 'analyze-product', "Erreur lors de l'analyse du produit");
  }

  Future<List<Ingredient>> _analyzeImage(
    String imagePath,
    String functionName,
    String errorPrefix,
  ) async {
    try {
      // 1. COMPRESSION DE L'IMAGE
      // On réduit la taille (max 800x800) et la qualité (70%) pour un envoi ultra-rapide
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imagePath,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
      );

      if (compressedBytes == null) {
        throw Exception("Impossible de compresser l'image.");
      }

      // 2. ENCODAGE EN BASE64
      // L'API attend du texte, on transforme donc notre image en longue chaîne de caractères
      final String base64Image = base64Encode(compressedBytes);

      // 3. APPEL À SUPABASE EDGE FUNCTIONS
      final response = await _supabase.functions.invoke(
        functionName,
        body: {'image': base64Image},
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
      )).toList();

    } catch (e) {
      throw Exception("$errorPrefix : ${_describeError(e)}");
    }
  }

  Future<String> chatWithCoach(
    String message,
    List<Map<String, dynamic>> history, {
    String coachTone = 'motivant',
    String dietType = 'none',
    List<String> allergies = const [],
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
        },
      );

      return response.data['reply'] as String;
    } catch (e) {
      throw Exception("Erreur de connexion avec le Coach IA : ${_describeError(e)}");
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
    int count = 6,
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
          'count': count,
        },
      );

      final List<dynamic> data = response.data['suggestions'];
      return data
          .map((item) => MealSuggestion.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("Erreur lors de la génération des idées de repas : ${_describeError(e)}");
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