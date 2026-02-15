import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text('Étape 1 sur 2', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 16),
            const Text('Apprenons à nous connaître', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1)),
            const SizedBox(height: 12),
            Text('Ces informations permettent à notre IA de calculer votre besoin calorique précis.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 30),

            // Choix du genre
            const Row(children: [Icon(Icons.people_outline, color: primaryColor), SizedBox(width: 8), Text('Vous êtes...', style: TextStyle(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSelectableCard('Homme', Icons.person_outline, true, primaryColor)),
                const SizedBox(width: 16),
                Expanded(child: _buildSelectableCard('Femme', Icons.person_outline, false, primaryColor)),
              ],
            ),
            const SizedBox(height: 24),

            // Âge et Poids
            Row(
              children: [
                Expanded(child: _buildInputField('Votre Âge', '25', 'ans')),
                const SizedBox(width: 16),
                Expanded(child: _buildInputField('Votre Poids', '70', 'kg')),
              ],
            ),
            const SizedBox(height: 24),

            // Objectifs
            const Row(children: [Icon(Icons.track_changes, color: primaryColor), SizedBox(width: 8), Text('Quel est votre objectif ?', style: TextStyle(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            _buildGoalCard('Perdre du poids', 'Réduire l\'apport calorique et brûler les graisses', Icons.trending_down, true, primaryColor),
            _buildGoalCard('Maintenir mon poids', 'Équilibrer les macros pour une santé optimale', Icons.adjust, false, primaryColor),
            _buildGoalCard('Prendre de la masse', 'Augmenter l\'apport pour le muscle', Icons.fitness_center, false, primaryColor),

            const SizedBox(height: 40),

            // Bouton
            ElevatedButton(
              onPressed: () => context.go('/dashboard'), // Vers le dashboard
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text('Calculer mon plan', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(width: 8), Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableCard(String title, IconData icon, bool isSelected, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.05) : Colors.white,
        border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? color : Colors.grey, size: 30),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String placeholder, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const Icon(Icons.calendar_today, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(label, style: const TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: placeholder,
            suffixText: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(String title, String subtitle, IconData icon, bool isSelected, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.white,
        border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2 : 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isSelected ? color : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: isSelected ? Colors.white : Colors.grey)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))])),
          if (isSelected) Icon(Icons.check_circle, color: color)
        ],
      ),
    );
  }
}