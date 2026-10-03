import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_extensions.dart';
import '../models/ingredient.dart';
import '../providers/meal_provider.dart';
import '../widgets/animated_async_value.dart';
import '../widgets/cloud_ai_consent_gate.dart';

const _primaryColor = Color(0xFF6B66FF);

/// Inventaire détecté sur une photo de frigo/placard (voir
/// analyze-pantry/index.ts) : un [Ingredient] par aliment identifié, dont
/// seul `name` importe ici (poids/macros ne servent qu'au contrat JSON
/// partagé, voir ai_service.dart). L'utilisateur peut corriger la liste
/// (retirer un aliment mal identifié, en ajouter un manuellement) avant de
/// lancer la génération de recettes.
class PantryScanScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const PantryScanScreen({super.key, required this.imagePath});

  @override
  ConsumerState<PantryScanScreen> createState() => _PantryScanScreenState();
}

class _PantryScanScreenState extends ConsumerState<PantryScanScreen> {
  final _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _startAnalysis() {
    ref
        .read(mealProvider.notifier)
        .analyzeImage(widget.imagePath, isPantry: true);
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _addManualItem() {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    ref
        .read(mealProvider.notifier)
        .addIngredient(
          Ingredient(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: name,
            weight: 0,
            kcalPer100g: 0,
            protPer100g: 0,
            glucPer100g: 0,
            lipPer100g: 0,
          ),
        );
    _addController.clear();
  }

  void _generateRecipes(List<Ingredient> items) {
    context.push('/pantry_recipes', extra: items.map((i) => i.name).toList());
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(mealProvider);

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
            context.l10n.pantryScanTitle,
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
              itemsAsync.animatedWhen(
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: _primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.pantryScanLoadingMessage,
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
                data: (items) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            context.l10n.pantryScanEmptyMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final item in items)
                              Chip(
                                label: Text(item.name),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => ref
                                    .read(mealProvider.notifier)
                                    .removeIngredient(item.id),
                                backgroundColor: _primaryColor.withValues(
                                  alpha: 0.08,
                                ),
                                labelStyle: const TextStyle(
                                  color: _primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _addController,
                              decoration: InputDecoration(
                                hintText: context.l10n.pantryScanAddHint,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onSubmitted: (_) => _addManualItem(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _addManualItem,
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: items.isEmpty
                              ? null
                              : () => _generateRecipes(items),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(context.l10n.pantryScanGenerateButton),
                        ),
                      ),
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
