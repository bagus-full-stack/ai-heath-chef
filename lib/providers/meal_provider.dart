import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import '../services/product_lookup_service.dart';
import '../models/ingredient.dart';
import 'local_ai_provider.dart';
import 'locale_provider.dart';

// --- LES SERVICES ---
final aiServiceProvider = Provider<AIService>((ref) => AIService());
final productLookupServiceProvider = Provider<ProductLookupService>((ref) => ProductLookupService());

// --- LE PROVIDER PRINCIPAL ---
// On utilise AsyncNotifier (sans AutoDispose) pour simplifier et éviter les erreurs de typage
class MealNotifier extends AsyncNotifier<List<Ingredient>> {
  @override
  FutureOr<List<Ingredient>> build() {
    // Par défaut, la liste est vide quand on arrive sur la page
    return [];
  }

  // Lancer l'analyse IA d'une photo (repas, ou produit emballé si isProduct)
  Future<void> analyzeImage(String imagePath, {bool isProduct = false}) async {
    // 1. On passe en état de chargement
    state = const AsyncValue.loading();

    // 2. On essaie de récupérer les données : IA locale d'abord si activée
    // et téléchargée (pas de connexion requise, n'utilise pas le quota
    // cloud partagé), sinon/en cas d'échec repli sur le cloud comme avant.
    final lang = ref.read(localeProvider).value?.languageCode ?? 'fr';
    state = await AsyncValue.guard(() async {
      final localSettings = ref.read(localAiSettingsProvider).value;
      if (localSettings?.isReadyToUse == true) {
        try {
          final local = ref.read(localAiServiceProvider);
          return isProduct
              ? await local.analyzeProductImage(imagePath, lang: lang)
              : await local.analyzeMealImage(imagePath, lang: lang);
        } catch (_) {
          // IA locale indisponible/échec : on retombe sur le cloud ci-dessous.
        }
      }

      final aiService = ref.read(aiServiceProvider);
      return isProduct
          ? await aiService.analyzeProductImage(imagePath, lang: lang)
          : await aiService.analyzeMealImage(imagePath, lang: lang);
    });
  }

  // Chercher un produit à partir d'un code-barres scanné (Open Food Facts)
  Future<void> loadFromBarcode(String barcode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final productService = ref.read(productLookupServiceProvider);
      final ingredient = await productService.lookupBarcode(barcode);
      return [ingredient];
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

  // Retirer un ingrédient de la liste
  void removeIngredient(String id) {
    if (state.value == null) return;
    state = AsyncValue.data(
      state.value!.where((i) => i.id != id).toList(),
    );
  }

  // Ajouter un ingrédient saisi manuellement
  void addIngredient(Ingredient ingredient) {
    final current = state.value ?? const <Ingredient>[];
    state = AsyncValue.data([...current, ingredient]);
  }
}

// On utilise AsyncNotifierProvider au lieu de AsyncNotifierProvider.autoDispose
final mealProvider = AsyncNotifierProvider<MealNotifier, List<Ingredient>>(() {
  return MealNotifier();
});
