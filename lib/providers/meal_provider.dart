import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Modèle de données pour un ingrédient
class Ingredient {
  final String id;
  final String name;
  final int weight; // en grammes
  final double kcalPer100g;
  final double protPer100g;
  final double glucPer100g;
  final double lipPer100g;

  Ingredient({required this.id, required this.name, required this.weight, required this.kcalPer100g, required this.protPer100g, required this.glucPer100g, required this.lipPer100g});

  Ingredient copyWith({int? weight}) {
    return Ingredient(id: id, name: name, weight: weight ?? this.weight, kcalPer100g: kcalPer100g, protPer100g: protPer100g, glucPer100g: glucPer100g, lipPer100g: lipPer100g);
  }

  // Calculs dynamiques basés sur le poids actuel
  int get currentKcal => (kcalPer100g * weight / 100).round();
  double get currentProt => (protPer100g * weight / 100);
  double get currentGluc => (glucPer100g * weight / 100);
  double get currentLip => (lipPer100g * weight / 100);
}

// 2. Le Notifier qui gère la liste et les modifications
class MealNotifier extends Notifier<List<Ingredient>> {
  @override
  List<Ingredient> build() {
    // Données fictives simulant le retour de l'IA
    return [
      Ingredient(id: '1', name: 'Blanc de Poulet Grillé', weight: 150, kcalPer100g: 163, protPer100g: 31, glucPer100g: 0, lipPer100g: 4),
      Ingredient(id: '2', name: 'Riz Basmati Cuit', weight: 120, kcalPer100g: 130, protPer100g: 2.9, glucPer100g: 28.3, lipPer100g: 0.4),
      Ingredient(id: '3', name: 'Brocolis Vapeur', weight: 80, kcalPer100g: 35, protPer100g: 2.8, glucPer100g: 6.2, lipPer100g: 0.4),
    ];
  }

  // Augmenter de 10g
  void increment(String id) {
    state = state.map((i) => i.id == id ? i.copyWith(weight: i.weight + 10) : i).toList();
  }

  // Diminuer de 10g (minimum 0)
  void decrement(String id) {
    state = state.map((i) => i.id == id ? i.copyWith(weight: (i.weight - 10).clamp(0, 9999)) : i).toList();
  }
}

// 3. Le Provider à écouter dans l'UI
final mealProvider = NotifierProvider<MealNotifier, List<Ingredient>>(() => MealNotifier());