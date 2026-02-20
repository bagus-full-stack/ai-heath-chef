import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import '../models/ingredient.dart';

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