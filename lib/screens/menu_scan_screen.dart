import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_extensions.dart';
import '../local_db/local_db_provider.dart';
import '../models/ingredient.dart';
import '../providers/dashboard_provider.dart';
import '../providers/meal_provider.dart';
import '../widgets/animated_async_value.dart';
import '../widgets/cloud_ai_consent_gate.dart';

const _primaryColor = Color(0xFF6B66FF);

/// Résultat du scan d'une carte de restaurant : un plat détecté = un
/// [Ingredient] indépendant (voir analyze-menu/index.ts) — contrairement à
/// meal_analysis_screen.dart, on n'affiche pas de total combiné (les plats
/// d'un menu ne sont pas mangés ensemble), chaque carte peut être ajoutée au
/// journal séparément.
class MenuScanScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const MenuScanScreen({super.key, required this.imagePath});

  @override
  ConsumerState<MenuScanScreen> createState() => _MenuScanScreenState();
}

class _MenuScanScreenState extends ConsumerState<MenuScanScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _startAnalysis() {
    ref
        .read(mealProvider.notifier)
        .analyzeImage(widget.imagePath, isMenu: true);
  }

  Future<void> _addToJournal(Ingredient dish) async {
    try {
      await ref
          .read(mealRepositoryProvider)
          .saveMeal(
            [dish],
            dish.name,
            lang: Localizations.localeOf(context).languageCode,
          );
      ref.invalidate(todayMealsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.menuScanAddedMessage(dish.name)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dishesAsync = ref.watch(mealProvider);

    return CloudAiConsentGate(
      onGranted: _startAnalysis,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            context.l10n.menuScanTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              dishesAsync.animatedWhen(
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: _primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.menuScanLoadingMessage,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                data: (dishes) {
                  if (dishes.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        context.l10n.menuScanEmptyMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final dish in dishes) ...[
                        _DishCard(
                          dish: dish,
                          onDismiss: () => ref
                              .read(mealProvider.notifier)
                              .removeIngredient(dish.id),
                          onAdd: () => _addToJournal(dish),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  final Ingredient dish;
  final VoidCallback onDismiss;
  final VoidCallback onAdd;
  const _DishCard({
    required this.dish,
    required this.onDismiss,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(dish.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dish.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  context.l10n.mealAnalysisKcalValue(
                    dish.currentKcal.toString(),
                  ),
                  style: const TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.mealAnalysisWeightValue(dish.weight.toString()),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MacroChip(
                  label: context.l10n.mealAnalysisBadgeProt,
                  value: dish.currentProt,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: context.l10n.mealAnalysisBadgeGluc,
                  value: dish.currentGluc,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: context.l10n.mealAnalysisBadgeLip,
                  value: dish.currentLip,
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: onAdd,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: const BorderSide(color: _primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(context.l10n.menuScanAddButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  const _MacroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label ${context.l10n.mealAnalysisGramsValue(value.toStringAsFixed(1))}',
      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
    );
  }
}
