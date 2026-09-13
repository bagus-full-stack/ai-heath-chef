import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ingredient.dart';

/// Recherche les informations nutritionnelles d'un produit à partir de son
/// code-barres, via la base de données publique et gratuite Open Food Facts
/// (https://world.openfoodfacts.org). Aucune clé API requise.
class ProductLookupService {
  Future<Ingredient> lookupBarcode(String barcode) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
      '?fields=product_name,brands,serving_quantity,nutriments',
    );

    late final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception('Impossible de contacter la base de données produits : ${e.toString()}');
    }

    if (response.statusCode != 200) {
      throw Exception('Erreur réseau lors de la recherche du produit (${response.statusCode}).');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['status'] != 1 || json['product'] == null) {
      throw Exception(
        'Produit introuvable pour ce code-barres. Essaie une photo du produit, ou ajoute-le manuellement.',
      );
    }

    final product = json['product'] as Map<String, dynamic>;
    final nutriments = (product['nutriments'] as Map<String, dynamic>?) ?? const {};

    final name = (product['product_name'] as String?)?.trim();
    final brand = (product['brands'] as String?)?.trim();
    final label = (name == null || name.isEmpty)
        ? (brand?.isNotEmpty == true ? brand! : 'Produit scanné')
        : (brand?.isNotEmpty == true ? '$name ($brand)' : name);

    final servingQuantity = (product['serving_quantity'] as num?)?.toInt();

    return Ingredient(
      id: barcode,
      name: label,
      weight: (servingQuantity != null && servingQuantity > 0) ? servingQuantity : 100,
      kcalPer100g: _readNutrient(nutriments, 'energy-kcal_100g'),
      protPer100g: _readNutrient(nutriments, 'proteins_100g'),
      glucPer100g: _readNutrient(nutriments, 'carbohydrates_100g'),
      lipPer100g: _readNutrient(nutriments, 'fat_100g'),
    );
  }

  double _readNutrient(Map<String, dynamic> nutriments, String key) {
    final value = nutriments[key];
    return value is num ? value.toDouble() : 0;
  }
}
