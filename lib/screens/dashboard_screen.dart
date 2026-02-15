import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/dashboard_provider.dart';
import 'package:image_picker/image_picker.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFF6B66FF);

    // Objectifs fixes (à rendre dynamiques avec le profil utilisateur plus tard)
    const int targetKcal = 2200;
    const double targetProt = 160.0;
    const double targetGluc = 250.0;
    const double targetLip = 75.0;

    // On écoute notre base de données via Riverpod
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/100')),
          )
        ],
      ),

      // La magie Riverpod : loading, error, et data
      body: mealsAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
          error: (err, stack) => Center(child: Text('Erreur: $err')),
          data: (meals) {

            // --- CALCUL DES TOTAUX ---
            int totalKcal = 0;
            double totalProt = 0;
            double totalGluc = 0;
            double totalLip = 0;

            for (var meal in meals) {
              totalKcal += (meal['total_kcal'] as num).toInt();
              totalProt += (meal['total_prot'] as num).toDouble();
              totalGluc += (meal['total_gluc'] as num).toDouble();
              totalLip += (meal['total_lip'] as num).toDouble();
            }

            // --- CALCUL DES REQUANTS ET POURCENTAGES ---
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
              onRefresh: () async => ref.refresh(todayMealsProvider), // Tirer vers le bas pour rafraîchir
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                physics: const AlwaysScrollableScrollPhysics(), // Nécessaire pour le pull-to-refresh
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
                          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          // Affichage de la date du jour
                          child: Text('${DateTime.now().day} / ${DateTime.now().month}', style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Jauge Circulaire Principale
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
                              children: const [
                                Icon(Icons.local_fire_department, size: 16, color: primaryColor),
                                Text(' Objectif: 2200', style: TextStyle(color: Colors.black54, fontSize: 12)),
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

                    // Journal des repas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.restaurant, color: primaryColor),
                            SizedBox(width: 8),
                            Text('Journal des repas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        // On formate l'heure (ex: 14:05)
                        final date = DateTime.parse(meal['created_at']).toLocal();
                        final timeString = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                        return _buildMealCard(
                          meal['name'] ?? 'Repas',
                          timeString,
                          '${meal['total_kcal']} kcal',
                        );
                      }).toList(),

                    const SizedBox(height: 100), // Espace pour le bouton flottant
                  ],
                ),
              ),
            );
          }
      ),

      // Bouton Flottant (Caméra)
      floatingActionButton: mealsAsyncValue.isLoading ? null : FloatingActionButton(
        onPressed: () {
          // Ce code ouvre l'appareil photo, comme on l'avait configuré !
          _pickImageAndNavigate(context);
        },
        backgroundColor: Colors.pink.shade400,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
      ),
    );
  }

  // Fonction pour appeler ImagePicker (placée ici pour garder le code propre)
  Future<void> _pickImageAndNavigate(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    // On ouvre l'appareil photo
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    // Si on a pris une photo, on va vers l'écran d'analyse
    if (image != null && context.mounted) {
      context.push('/meal_analysis', extra: image.path);
    }
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
            percent: percent, // Pourcentage dynamique !
            backgroundColor: color.withOpacity(0.2),
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
            decoration: BoxDecoration(color: const Color(0xFF6B66FF).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(calories, style: const TextStyle(color: Color(0xFF6B66FF), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}