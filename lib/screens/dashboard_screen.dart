import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../providers/dashboard_provider.dart';
import '../providers/profile_provider.dart';
import '../models/meal.dart'; // 🚀 On importe notre nouveau modèle !
import '../utils/nutrition_targets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // Fonction pour ouvrir l'écran de capture caméra
  void _openCameraCapture(BuildContext context) {
    context.push('/camera_capture');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFF6B66FF);

    // Objectifs personnalisés, calculés à partir du profil (sexe/âge/poids/
    // objectif). Repli sur des valeurs par défaut tant que le profil n'est
    // pas chargé ou incomplet — voir lib/utils/nutrition_targets.dart.
    final profileAsync = ref.watch(profileProvider);
    final targets = profileAsync.maybeWhen(
      data: computeNutritionTargets,
      orElse: () => NutritionTargets.fallback,
    );
    final targetKcal = targets.kcal;
    final targetProt = targets.protein;
    final targetGluc = targets.carbs;
    final targetLip = targets.fat;

    // On écoute notre base de données (qui renvoie maintenant une List<Meal>)
    final mealsAsyncValue = ref.watch(todayMealsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.bolt, color: Colors.white),
          ),
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Color(0xFFEEEEEE),
              child: Icon(Icons.person, color: Colors.grey),
            ),
          )
        ],
      ),

      body: mealsAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
          error: (err, stack) => Center(child: Text('Erreur: $err')),
          data: (List<Meal> meals) { // 🚀 On spécifie bien List<Meal> ici

            // --- CALCUL DES TOTAUX ---
            int totalKcal = 0;
            double totalProt = 0;
            double totalGluc = 0;
            double totalLip = 0;

            // C'est tellement plus propre avec des objets !
            for (var meal in meals) {
              totalKcal += meal.totalKcal;
              totalProt += meal.totalProt;
              totalGluc += meal.totalGluc;
              totalLip += meal.totalLip;
            }

            // --- CALCUL DES RESTANTS ET POURCENTAGES ---
            int remainingKcal = targetKcal - totalKcal;
            if (remainingKcal < 0) remainingKcal = 0;

            double percentKcal = totalKcal / targetKcal;
            if (percentKcal > 1.0) percentKcal = 1.0;

            double percentProt = totalProt / targetProt;
            if (percentProt > 1.0) percentProt = 1.0;

            double percentGluc = totalGluc / targetGluc;
            if (percentGluc > 1.0) percentGluc = 1.0;

            double percentLip = totalLip / targetLip;
            if (percentLip > 1.0) percentLip = 1.0;

            return RefreshIndicator(
              onRefresh: () async => ref.refresh(todayMealsProvider),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Aujourd\'hui', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text('${DateTime.now().day} / ${DateTime.now().month}', style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Jauge Circulaire
                    Center(
                      child: CircularPercentIndicator(
                        radius: 130.0,
                        lineWidth: 20.0,
                        animation: true,
                        percent: percentKcal,
                        arcType: ArcType.HALF,
                        arcBackgroundColor: Colors.grey.shade200,
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: primaryColor,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$remainingKcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 40)),
                            const Text('KCAL RESTANT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department, size: 16, color: primaryColor),
                                Text(' Objectif: $targetKcal', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cartes de Macronutriments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMacroCard('PROTÉINES', '${totalProt.toInt()}g', '/${targetProt.toInt()}g', percentProt, Colors.blue),
                        _buildMacroCard('GLUCIDES', '${totalGluc.toInt()}g', '/${targetGluc.toInt()}g', percentGluc, Colors.orange),
                        _buildMacroCard('LIPIDES', '${totalLip.toInt()}g', '/${targetLip.toInt()}g', percentLip, Colors.pink),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Section Journal des repas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.restaurant, color: primaryColor),
                            const SizedBox(width: 8),
                            const Text('Journal des repas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Liste dynamique des repas sauvegardés
                    if (meals.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text("Aucun repas enregistré aujourd'hui. Scannez votre première assiette !", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                        ),
                      )
                    else
                      ...meals.map((meal) {
                        // 🚀 L'objet meal gère déjà la date proprement
                        final timeString = '${meal.createdAt.hour.toString().padLeft(2, '0')}:${meal.createdAt.minute.toString().padLeft(2, '0')}';

                        return _buildMealCard(
                          meal.name,
                          timeString,
                          '${meal.totalKcal} kcal',
                        );
                      }),

                    const SizedBox(height: 100), // Espace pour le bouton flottant
                  ],
                ),
              ),
            );
          }
      ),

      // Bouton Flottant
      floatingActionButton: mealsAsyncValue.isLoading ? null : FloatingActionButton(
        onPressed: () => _openCameraCapture(context),
        backgroundColor: Colors.pink.shade400,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
      ),
    );
  }

  // --- WIDGETS REUTILISABLES ---
  Widget _buildMacroCard(String title, String current, String total, double percent, Color color) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 2)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 6, backgroundColor: color),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(current, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(total, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 4.0,
            percent: percent,
            backgroundColor: color.withValues(alpha: 0.2),
            progressColor: color,
            barRadius: const Radius.circular(2),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(String name, String time, String calories) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, spreadRadius: 1)], border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.fastfood, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF6B66FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(calories, style: const TextStyle(color: Color(0xFF6B66FF), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}