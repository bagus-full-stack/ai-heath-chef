import 'package:flutter/material.dart';

import '../l10n/l10n_extensions.dart';
import '../models/meal_suggestion.dart';
import '../utils/image_data_uri.dart';
import '../utils/ingredient_substitution.dart';

const Color _kPrimaryColor = Color(0xFF6B66FF);

const Map<String, IconData> _kTimeSlotIcons = {
  'Petit-déjeuner': Icons.free_breakfast_rounded,
  'Déjeuner': Icons.lunch_dining_rounded,
  'Dîner': Icons.dinner_dining_rounded,
  'Collation': Icons.apple_rounded,
};

/// Carte présentant une idée de repas générée par l'IA, illustrée par une
/// image générée (Pollinations.ai, encodée en data URI) quand elle a pu être
/// générée. Ce n'est jamais une vraie photo du plat — juste une illustration
/// IA — donc en cas d'échec de génération (réseau, quota...) on retombe sur
/// une icône représentative du moment de la journée plutôt que de bloquer
/// l'affichage de la suggestion.
class MealSuggestionCard extends StatelessWidget {
  final MealSuggestion suggestion;
  final VoidCallback onAdd;
  final VoidCallback onAddToShoppingList;
  /// Allergies déclarées par l'utilisateur (voir user_profile.dart) — pour
  /// signaler un ingrédient à risque dans la feuille recette et proposer un
  /// substitut (voir lib/utils/ingredient_substitution.dart).
  final List<String> allergies;

  const MealSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onAdd,
    required this.onAddToShoppingList,
    this.allergies = const [],
  });

  @override
  Widget build(BuildContext context) {
    final icon =
        _kTimeSlotIcons[suggestion.timeSlot] ?? Icons.restaurant_rounded;
    final imageBytes = decodeImageDataUri(suggestion.imageUrl);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: suggestion.ingredients.isEmpty && suggestion.steps.isEmpty
                ? null
                : () => _showRecipeSheet(context),
            child: Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _kPrimaryColor.withValues(alpha: 0.08),
                  ),
                  child: imageBytes != null
                      ? Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(icon, size: 48, color: _kPrimaryColor),
                          ),
                        )
                      : Center(
                          child: Icon(icon, size: 48, color: _kPrimaryColor),
                        ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      suggestion.timeSlot,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (suggestion.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    suggestion.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_outlined,
                      size: 16,
                      color: _kPrimaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.mealSuggestionCardKcalLabel(
                        suggestion.kcal.toString(),
                      ),
                      style: const TextStyle(
                        color: _kPrimaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MacroMini(
                      label: context.l10n.mealSuggestionCardProtLabel,
                      value: context.l10n.mealSuggestionCardGramsValue(
                        suggestion.prot.toStringAsFixed(0),
                      ),
                    ),
                    _MacroMini(
                      label: context.l10n.mealSuggestionCardGlucLabel,
                      value: context.l10n.mealSuggestionCardGramsValue(
                        suggestion.gluc.toStringAsFixed(0),
                      ),
                    ),
                    _MacroMini(
                      label: context.l10n.mealSuggestionCardLipLabel,
                      value: context.l10n.mealSuggestionCardGramsValue(
                        suggestion.lip.toStringAsFixed(0),
                      ),
                    ),
                    GestureDetector(
                      onTap: onAddToShoppingList,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _kPrimaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: _kPrimaryColor,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: _kPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRecipeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecipeSheet(suggestion: suggestion, allergies: allergies),
    );
  }
}

/// Feuille modale listant les ingrédients et les étapes de préparation d'une
/// suggestion — générés par l'IA en même temps que le reste de la suggestion
/// (voir supabase/functions/meal-suggestions).
class _RecipeSheet extends StatelessWidget {
  final MealSuggestion suggestion;
  final List<String> allergies;

  const _RecipeSheet({required this.suggestion, this.allergies = const []});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                suggestion.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (suggestion.ingredients.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  context.l10n.mealSuggestionRecipeIngredientsTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                for (final ingredient in suggestion.ingredients)
                  _IngredientRow(text: ingredient, allergies: allergies),
              ],
              if (suggestion.steps.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  context.l10n.mealSuggestionRecipeStepsTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < suggestion.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: _kPrimaryColor.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _kPrimaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            suggestion.steps[i],
                            style: const TextStyle(fontSize: 13.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Décode une data URI base64 (`data:image/...;base64,...`) en octets bruts.
/// Retourne `null` si `dataUri` est nul/vide ou mal formé, plutôt que de
/// lever une exception — la carte retombe alors sur l'icône par défaut.
/// Ligne d'ingrédient dans la feuille recette, signalant un allergène
/// déclaré (icône orange + substitut suggéré) ou proposant un substitut sur
/// demande via une icône d'échange (dépannage "je n'ai pas ça dans mon
/// placard") — voir lib/utils/ingredient_substitution.dart.
class _IngredientRow extends StatelessWidget {
  final String text;
  final List<String> allergies;

  const _IngredientRow({required this.text, required this.allergies});

  @override
  Widget build(BuildContext context) {
    final hasAllergyMatch = ingredientMatchesAllergy(text, allergies);
    final substitute = suggestSubstitute(text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Icon(
                  hasAllergyMatch ? Icons.warning_amber_rounded : Icons.circle,
                  size: hasAllergyMatch ? 15 : 5,
                  color: hasAllergyMatch ? Colors.deepOrange : _kPrimaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                ),
              ),
              if (!hasAllergyMatch && substitute != null)
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.mealSuggestionRecipeSubstituteMessage(substitute)),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.swap_horiz_rounded, size: 18, color: Colors.grey),
                  ),
                ),
            ],
          ),
          if (hasAllergyMatch && substitute != null)
            Padding(
              padding: const EdgeInsets.only(left: 25, top: 2),
              child: Text(
                context.l10n.mealSuggestionRecipeAllergyWarning(substitute),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MacroMini extends StatelessWidget {
  final String label;
  final String value;

  const _MacroMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
