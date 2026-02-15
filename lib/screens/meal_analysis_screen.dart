import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/meal_provider.dart';
import '../services/database_service.dart';

class MealAnalysisScreen extends ConsumerStatefulWidget {
  final String? imagePath;

  const MealAnalysisScreen({super.key, this.imagePath});

  @override
  ConsumerState<MealAnalysisScreen> createState() => _MealAnalysisScreenState();
}

class _MealAnalysisScreenState extends ConsumerState<MealAnalysisScreen> {

  @override
  void initState() {
    super.initState();
    // On lance l'analyse IA juste après la construction initiale de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.imagePath != null) {
        ref.read(mealProvider.notifier).analyzeImage(widget.imagePath!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);

    // On écoute l'état de notre Provider (loading, data, ou error)
    final mealState = ref.watch(mealProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('ANALYSE DU REPAS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.info_outline, color: primaryColor), onPressed: () {})
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Zone de l'image (Toujours visible)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade200),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.imagePath != null)
                    Image.file(File(widget.imagePath!), fit: BoxFit.cover)
                  else
                    const Icon(Icons.fastfood, size: 80, color: Colors.grey),

                  Positioned(
                    bottom: 16, left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
                      child: const Text('Identifié par l\'IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  )
                ],
              ),
            ),

            // 2. Gestion de l'affichage selon l'état de l'IA
            mealState.when(
              // ÉTAT 1 : CHARGEMENT
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(vertical: 60.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 20),
                    Text('L\'IA analyse votre assiette...', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('Cela prend généralement quelques secondes.', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  ],
                ),
              ),

              // ÉTAT 2 : ERREUR
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                    const SizedBox(height: 16),
                    const Text('Oups !', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(error.toString(), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (widget.imagePath != null) ref.read(mealProvider.notifier).analyzeImage(widget.imagePath!);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),

              // ÉTAT 3 : SUCCÈS (On affiche les données !)
              data: (ingredients) {
                if (ingredients.isEmpty) return const SizedBox.shrink(); // Sécurité

                // Calculs totaux
                final totalKcal = ingredients.fold<int>(0, (sum, item) => sum + item.currentKcal);
                final totalProt = ingredients.fold<double>(0, (sum, item) => sum + item.currentProt);
                final totalGluc = ingredients.fold<double>(0, (sum, item) => sum + item.currentGluc);
                final totalLip = ingredients.fold<double>(0, (sum, item) => sum + item.currentLip);

                return Column(
                  children: [
                    // En-tête Ingrédients & Total
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
                          ...ingredients.map((item) => _buildIngredientCard(item, ref, primaryColor)),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {}, // Logique pour ajouter manuellement
                            icon: const Icon(Icons.add, color: Colors.black54),
                            label: const Text('Ajouter un ingrédient', style: TextStyle(color: Colors.black87, fontSize: 16)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade300, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Résumé Nutritionnel
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
                    // BOUTON DE SAUVEGARDE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // On affiche un indicateur de chargement natif
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(child: CircularProgressIndicator()),
                            );

                            // Appel au service de base de données
                            await DatabaseService().saveMeal(ingredients, 'Repas IA'); // Tu pourras rendre le nom dynamique plus tard

                            // On ferme le dialogue de chargement
                            if (context.mounted) Navigator.pop(context);

                            // On retourne au Dashboard !
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Repas sauvegardé avec succès !'), backgroundColor: Colors.green));
                              context.go('/dashboard');
                            }
                          } catch (e) {
                            if (context.mounted) Navigator.pop(context); // Fermer le loader
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Valider et sauvegarder', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS REUTILISABLES ---

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
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
            child: const Icon(Icons.restaurant, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.delete_outline, color: Colors.black54, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('${item.currentKcal} kcal', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                    Container(
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: () => ref.read(mealProvider.notifier).decrement(item.id),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                          Text('${item.weight} G', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () => ref.read(mealProvider.notifier).increment(item.id),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
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

  Widget _buildMacroBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSummaryMacro(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 8),
        Container(
          height: 4, width: 80,
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(width: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          ),
        )
      ],
    );
  }
}