import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';

// --- LE MODÈLE ---
class Ingredient {
  final String id;
  final String name;
  final int weight;
  final double kcalPer100g;
  final double protPer100g;
  final double glucPer100g;
  final double lipPer100g;

  Ingredient({
    required this.id,
    required this.name,
    required this.weight,
    required this.kcalPer100g,
    required this.protPer100g,
    required this.glucPer100g,
    required this.lipPer100g,
  });

  Ingredient copyWith({int? weight}) {
    return Ingredient(
      id: id,
      name: name,
      weight: weight ?? this.weight,
      kcalPer100g: kcalPer100g,
      protPer100g: protPer100g,
      glucPer100g: glucPer100g,
      lipPer100g: lipPer100g,
    );
  }

  int get currentKcal => (kcalPer100g * weight / 100).round();
  double get currentProt => (protPer100g * weight / 100);
  double get currentGluc => (glucPer100g * weight / 100);
  double get currentLip => (lipPer100g * weight / 100);
}

// --- LE SERVICE IA ---
final aiServiceProvider = Provider<AIService>((ref) => AIService());

// --- LE PROVIDER PRINCIPAL ---
// On utilise AsyncNotifier (sans AutoDispose) pour simplifier et éviter les erreurs de typage
class MealNotifier extends AsyncNotifier<List<Ingredient>> {
  @override
  FutureOr<List<Ingredient>> build() {
    // Par défaut, la liste est vide quand on arrive sur la page
    return [];
  }

  // Lancer l'analyse IA
  Future<void> analyzeImage(String imagePath) async {
    // 1. On passe en état de chargement
    state = const AsyncValue.loading();

    // 2. On essaie de récupérer les données
    state = await AsyncValue.guard(() async {
      final aiService = ref.read(aiServiceProvider);
      return await aiService.analyzeMealImage(imagePath);
    });
  }

  // Augmenter de 10g
  void increment(String id) {
    if (state.value == null) return;
    state = AsyncValue.data(
      state.value!.map((i) => i.id == id ? i.copyWith(weight: i.weight + 10) : i).toList(),
    );
  }

  // Diminuer de 10g
  void decrement(String id) {
    if (state.value == null) return;
    state = AsyncValue.data(
      state.value!.map((i) => i.id == id ? i.copyWith(weight: (i.weight - 10).clamp(0, 9999)) : i).toList(),
    );
  }
}

// On utilise AsyncNotifierProvider au lieu de AsyncNotifierProvider.autoDispose
final mealProvider = AsyncNotifierProvider<MealNotifier, List<Ingredient>>(() {
  return MealNotifier();
});