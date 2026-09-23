import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../l10n/app_localizations.dart';
import '../models/ingredient.dart';

/// Recherche les informations nutritionnelles d'un produit à partir de son
/// code-barres, via la base de données publique et gratuite Open Food Facts
/// (https://world.openfoodfacts.org). Aucune clé API requise.
class ProductLookupService {
  Future<Ingredient> lookupBarcode(String barcode, {String lang = 'fr'}) async {
    final l10n = lookupAppLocalizations(Locale(lang));
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
      '?fields=product_name,brands,serving_quantity,nutriments',
    );

    late final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception(l10n.svcErrorProductLookupNetwork(e.toString()));
    }

    if (response.statusCode != 200) {
      throw Exception(l10n.svcErrorProductLookupHttp('${response.statusCode}'));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['status'] != 1 || json['product'] == null) {
      throw Exception(l10n.svcErrorProductNotFound);
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
      fiberPer100g: _readNutrient(nutriments, 'fiber_100g'),
      sugarPer100g: _readNutrient(nutriments, 'sugars_100g'),
      satFatPer100g: _readNutrient(nutriments, 'saturated-fat_100g'),
    );
  }

  /// Recherche des produits par nom (saisie manuelle sans photo ni
  /// code-barres, ex. "yaourt nature" ou "poulet rôti"). Ignore les fiches
  /// sans nom ou sans calories renseignées, trop peu fiables pour être
  /// proposées telles quelles.
  Future<List<Ingredient>> searchByName(String query, {String lang = 'fr'}) async {
    final l10n = lookupAppLocalizations(Locale(lang));
    final uri = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl').replace(
      queryParameters: {
        'search_terms': query,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '20',
        'fields': 'code,product_name,brands,serving_quantity,nutriments',
      },
    );

    late final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception(l10n.svcErrorProductLookupNetwork(e.toString()));
    }

    if (response.statusCode != 200) {
      throw Exception(l10n.svcErrorProductLookupHttp('${response.statusCode}'));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final products = (json['products'] as List?) ?? const [];

    return products
        .cast<Map<String, dynamic>>()
        .map((product) {
          final name = (product['product_name'] as String?)?.trim();
          final kcal = _readNutrient(
            (product['nutriments'] as Map<String, dynamic>?) ?? const {},
            'energy-kcal_100g',
          );
          if (name == null || name.isEmpty || kcal <= 0) return null;

          final brand = (product['brands'] as String?)?.trim();
          final nutriments = (product['nutriments'] as Map<String, dynamic>?) ?? const {};
          final servingQuantity = (product['serving_quantity'] as num?)?.toInt();
          final code = (product['code'] as String?)?.trim();

          return Ingredient(
            id: (code != null && code.isNotEmpty) ? code : name,
            name: (brand?.isNotEmpty == true) ? '$name ($brand)' : name,
            weight: (servingQuantity != null && servingQuantity > 0) ? servingQuantity : 100,
            kcalPer100g: kcal,
            protPer100g: _readNutrient(nutriments, 'proteins_100g'),
            glucPer100g: _readNutrient(nutriments, 'carbohydrates_100g'),
            lipPer100g: _readNutrient(nutriments, 'fat_100g'),
            fiberPer100g: _readNutrient(nutriments, 'fiber_100g'),
            sugarPer100g: _readNutrient(nutriments, 'sugars_100g'),
            satFatPer100g: _readNutrient(nutriments, 'saturated-fat_100g'),
          );
        })
        .whereType<Ingredient>()
        .toList();
  }

  double _readNutrient(Map<String, dynamic> nutriments, String key) {
    final value = nutriments[key];
    return value is num ? value.toDouble() : 0;
  }
}
