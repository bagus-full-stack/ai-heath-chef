import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ingredient.dart';

class AIService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fonction principale qui prend le chemin de l'image et retourne une liste d'ingrédients
  Future<List<Ingredient>> analyzeMealImage(String imagePath) async {
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
      // On appelle la fonction 'analyze-meal' déployée sur ton projet Supabase
      final response = await _supabase.functions.invoke(
        'analyze-meal',
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
      throw Exception("Erreur lors de l'analyse IA : ${e.toString()}");
    }
  }

  Future<String> chatWithCoach(String message, List<Map<String, dynamic>> history) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'coach_chat',
        body: {
          'message': message,
          'history': history,
        },
      );

      return response.data['reply'] as String;
    } catch (e) {
      throw Exception("Erreur de connexion avec le Coach IA : $e");
    }
  }
}