import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  // Par défaut, l'abonnement annuel est sélectionné (index 1)
  int selectedPlanIndex = 1;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('AI-HEALTH-CHEF PRO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          children: [
            // Logo central
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.bolt, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 20),
            const Text('Passez au niveau supérieur', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
            const SizedBox(height: 12),
            Text('Libérez tout le potentiel de votre nutrition\navec l\'intelligence artificielle de pointe.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
            const SizedBox(height: 30),

            // Liste des fonctionnalités
            _buildFeatureRow(Icons.camera_alt_outlined, 'Reconnaissance Photo Illimitée', 'Analysez chaque repas en une seconde grâce à notre IA visionnaire sans aucune restriction.', primaryColor),
            _buildFeatureRow(Icons.restaurant_menu, 'Coach de Repas Personnel', 'Recevez des suggestions de recettes adaptées à vos macros restantes en temps réel.', primaryColor),
            _buildFeatureRow(Icons.insights, 'Analyses Avancées', 'Graphiques détaillés sur vos micronutriments et tendances de santé sur le long terme.', primaryColor),
            _buildFeatureRow(Icons.shield_outlined, 'Zéro Publicité', 'Une expérience fluide et propre pour rester concentré sur vos objectifs santé.', primaryColor),

            const SizedBox(height: 30),
            const Align(alignment: Alignment.centerLeft, child: Text('CHOISISSEZ VOTRE FORFAIT', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0))),
            const SizedBox(height: 16),

            // Option Mensuelle
            _buildPlanCard(
              index: 0,
              title: 'Mensuel',
              price: '9,99 €',
              subtitle: '/mois',
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 12),

            // Option Annuelle (Conseillée)
            _buildPlanCard(
              index: 1,
              title: 'Annuel',
              price: '4,99 €',
              subtitle: '/mois',
              badge: 'Conseillé',
              primaryColor: primaryColor,
            ),

            const SizedBox(height: 16),
            Text('Facturé annuellement (59,88 €). Annulable à tout moment dans les paramètres de votre compte.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            const SizedBox(height: 24),

            // Bouton Principal
            ElevatedButton(
              onPressed: () {}, // Logique de paiement Stripe/RevenueCat plus tard
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Commencer l\'essai gratuit', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),

            // Liens footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('CONDITIONS', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                Text('CONFIDENTIALITÉ', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                Text('RESTAURER', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget pour une ligne de fonctionnalité
  Widget _buildFeatureRow(IconData icon, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget cliquable pour choisir un abonnement
  Widget _buildPlanCard({required int index, required String title, required String price, required String subtitle, String? badge, required Color primaryColor}) {
    final isSelected = selectedPlanIndex == index;

    return GestureDetector(
      onTap: () => setState(() => selectedPlanIndex = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
              border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: isSelected ? primaryColor : Colors.black54, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(price, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(' $subtitle', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    )
                  ],
                ),
                // Radio button custom
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300, width: 2),
                    color: isSelected ? primaryColor : Colors.transparent,
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                )
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -10,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(10)),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            )
        ],
      ),
    );
  }
}