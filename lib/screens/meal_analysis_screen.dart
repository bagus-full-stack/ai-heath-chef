import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/meal_provider.dart';

class MealAnalysisScreen extends ConsumerWidget { // <-- Changement ici
  final String? imagePath;

  const MealAnalysisScreen({super.key, this.imagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // <-- Ajout de WidgetRef
    const primaryColor = Color(0xFF6B66FF);

    // Écoute des ingrédients
    final ingredients = ref.watch(mealProvider);

    // Calculs totaux
    final totalKcal = ingredients.fold<int>(0, (sum, item) => sum + item.currentKcal);
    final totalProt = ingredients.fold<double>(0, (sum, item) => sum + item.currentProt);
    final totalGluc = ingredients.fold<double>(0, (sum, item) => sum + item.currentGluc);
    final totalLip = ingredients.fold<double>(0, (sum, item) => sum + item.currentLip);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(/* ... garde ton AppBar précédent ... */),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... (Garde la zone de l'image identique) ...

            // En-tête
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ingrédients', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Modifiez les quantités si nécessaire', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$totalKcal', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
                      const Text('TOTAL KCAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ],
                  )
                ],
              ),
            ),

            // Liste Dynamique des ingrédients
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  ...ingredients.map((item) => _buildIngredientCard(item, ref, primaryColor)), // <-- Génération dynamique
                  const SizedBox(height: 16),
                  // ... (Garde ton bouton Ajouter un ingrédient)
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Résumé Nutritionnel mis à jour
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RÉSUMÉ NUTRITIONNEL', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryMacro('Protéines', '${totalProt.toStringAsFixed(1)}g', primaryColor),
                        _buildSummaryMacro('Glucides', '${totalGluc.toStringAsFixed(1)}g', Colors.orange),
                        _buildSummaryMacro('Lipides', '${totalLip.toStringAsFixed(1)}g', Colors.pink),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientCard(Ingredient item, WidgetRef ref, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... Image placeholder ...
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${item.currentKcal} kcal', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildMacroBadge('PROT', '${item.currentProt.toStringAsFixed(1)}g', primaryColor),
                        const SizedBox(width: 8),
                        _buildMacroBadge('GLUC', '${item.currentGluc.toStringAsFixed(1)}g', Colors.orange),
                        const SizedBox(width: 8),
                        _buildMacroBadge('LIP', '${item.currentLip.toStringAsFixed(1)}g', Colors.pink),
                      ],
                    ),
                    // Boutons dynamiques
                    Container(
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: () => ref.read(mealProvider.notifier).decrement(item.id), // <-- ACTION
                          ),
                          Text('${item.weight} G', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () => ref.read(mealProvider.notifier).increment(item.id), // <-- ACTION
                          ),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String label, String value, Color color) { /* Identique à avant */ return Container(); }
  Widget _buildSummaryMacro(String title, String value, Color color) { /* Identique à avant */ return Container(); }
}