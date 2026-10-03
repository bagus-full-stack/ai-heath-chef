import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_extensions.dart';
import '../providers/pantry_recipes_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/animated_async_value.dart';
import '../widgets/cloud_ai_consent_gate.dart';
import '../widgets/meal_suggestion_card.dart';
import 'coach_screen.dart' show openCoachChatSheet, kCoachPrimaryColor;

/// Recettes générées à partir de l'inventaire détecté sur une photo de
/// frigo/placard (voir pantry_scan_screen.dart) — même carte/actions que
/// meal_suggestions_screen.dart (ajuster via le coach, ajouter à la liste de
/// courses), la génération étant ici déclenchée explicitement à l'ouverture
/// plutôt que mise en cache par jour.
class PantryRecipesScreen extends ConsumerStatefulWidget {
  final List<String> ingredientNames;
  const PantryRecipesScreen({super.key, required this.ingredientNames});

  @override
  ConsumerState<PantryRecipesScreen> createState() =>
      _PantryRecipesScreenState();
}

class _PantryRecipesScreenState extends ConsumerState<PantryRecipesScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _startAnalysis() {
    ref.read(pantryRecipesProvider.notifier).generate(widget.ingredientNames);
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(pantryRecipesProvider);
    final allergies = ref.watch(profileProvider).value?.allergies ?? const [];

    return CloudAiConsentGate(
      onGranted: _startAnalysis,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.black,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            context.l10n.pantryRecipesTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: kCoachPrimaryColor,
              ),
              onPressed: () =>
                  ref.read(pantryRecipesProvider.notifier).regenerate(),
            ),
          ],
        ),
        body: SafeArea(
          child: recipesAsync.animatedWhen(
            loading: () => const Center(
              child: CircularProgressIndicator(color: kCoachPrimaryColor),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.pantryRecipesLoadError,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(pantryRecipesProvider.notifier).regenerate(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCoachPrimaryColor,
                      ),
                      child: Text(
                        context.l10n.pantryRecipesRetryButton,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            data: (recipes) {
              if (recipes.isEmpty) {
                return Center(
                  child: Text(
                    context.l10n.pantryRecipesEmptyMessage,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: recipes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return MealSuggestionCard(
                    suggestion: recipe,
                    allergies: allergies,
                    onAdd: () => openCoachChatSheet(
                      context,
                      presetMessage: context.l10n
                          .mealSuggestionsAdjustPresetMessage(recipe.title),
                    ),
                    onAddToShoppingList: () {
                      ref.read(shoppingListProvider.notifier).addItems([
                        recipe.title,
                      ]);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n
                                .mealSuggestionsAddedToShoppingListMessage(
                                  recipe.title,
                                ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
