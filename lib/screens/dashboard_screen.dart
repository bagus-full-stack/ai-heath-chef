import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);

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
            child: CircleAvatar(
              backgroundImage: NetworkImage('https://i.pravatar.cc/100'), // Avatar mock
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('24 OCTOBRE', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
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
                percent: 0.6, // 60% restants
                arcType: ArcType.HALF,
                arcBackgroundColor: Colors.grey.shade200,
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: primaryColor,
                center: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('960', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40)),
                    Text('KCAL RESTANT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                _buildMacroCard('PROTÉINES', '85g', '/160g', Colors.blue),
                _buildMacroCard('GLUCIDES', '112g', '/250g', Colors.orange),
                _buildMacroCard('LIPIDES', '42g', '/75g', Colors.pink),
              ],
            ),
            const SizedBox(height: 30),

            // Journal des repas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.restaurant, color: primaryColor),
                    SizedBox(width: 8),
                    Text('Journal des repas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('Voir tout', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),

            // Liste des repas (Mocks)
            _buildMealCard('Bowl de Saumon', '08:30', '450 kcal'),
            _buildMealCard('Salade César', '12:45', '320 kcal'),

            const SizedBox(height: 100), // Espace pour le bouton flottant
          ],
        ),
      ),

      // Bouton Flottant (Caméra)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 1. On initialise le sélecteur d'image
          final ImagePicker picker = ImagePicker();

          // 2. On ouvre la caméra
          final XFile? image = await picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 80, // Petite compression native pour commencer
          );

          // 3. Si l'utilisateur a pris une photo, on navigue vers l'écran d'analyse
          if (image != null && context.mounted) {
            context.push('/meal_analysis', extra: image.path);
          }
        },
        backgroundColor: Colors.pink.shade400,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
      ),

      // Barre de navigation inférieure (Mock visuel)
      // bottomNavigationBar: BottomNavigationBar(
      //   selectedItemColor: primaryColor,
      //   unselectedItemColor: Colors.grey,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize), label: 'Accueil'),
      //     BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Coach'),
      //     BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
      //   ],
      // ),
    );
  }

  // --- WIDGETS REUTILISABLES POUR CET ÉCRAN ---

  Widget _buildMacroCard(String title, String current, String total, Color color) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 2)],
      ),
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
            percent: 0.5, // Mock progress
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
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, spreadRadius: 1)],
          border: Border.all(color: Colors.grey.shade100)
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.fastfood, color: Colors.grey), // Placeholder pour l'image
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
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}