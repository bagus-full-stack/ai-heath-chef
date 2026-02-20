import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  // 0 = Mensuel, 1 = Annuel
  int _selectedPlan = 1;
  bool _isLoading = false;

  void _processPayment() async {
    setState(() => _isLoading = true);

    // TODO: Intégrer RevenueCat (purchases_flutter) ou Stripe ici plus tard !
    // Pour l'instant, on simule un délai de paiement
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bienvenue dans AI Health Chef PRO ! ✨'), backgroundColor: Colors.green),
      );
      context.pop(); // On ferme le paywall et on retourne à l'application
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Couleur sombre Premium
      body: SafeArea(
        child: Column(
          children: [
            // --- EN-TÊTE AVEC BOUTON FERMER ---
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // --- LOGO ET TITRE ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, color: Colors.amber, size: 48),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Passez à la vitesse\nsupérieure',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Débloquez tout le potentiel de votre Coach IA et atteignez vos objectifs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 40),

                    // --- LISTE DES AVANTAGES ---
                    _buildFeatureRow(Icons.camera_alt, 'Analyses de repas illimitées'),
                    _buildFeatureRow(Icons.auto_awesome, 'Accès au modèle IA le plus puissant'),
                    _buildFeatureRow(Icons.history, 'Historique complet de vos macros'),
                    _buildFeatureRow(Icons.no_meals, 'Aucune publicité, jamais'),
                    const SizedBox(height: 40),

                    // --- OPTIONS D'ABONNEMENT ---
                    _buildPlanCard(
                      index: 1,
                      title: 'Annuel (Populaire)',
                      price: '39.99€ / an',
                      subtitle: 'Soit 3.33€/mois - 2 mois offerts !',
                      isPopular: true,
                    ),
                    const SizedBox(height: 16),
                    _buildPlanCard(
                      index: 0,
                      title: 'Mensuel',
                      price: '4.99€ / mois',
                      subtitle: 'Sans engagement, annulez quand vous voulez.',
                      isPopular: false,
                    ),
                    const SizedBox(height: 40),

                    // --- BOUTON D'ACHAT ---
                    ElevatedButton(
                      onPressed: _isLoading ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B66FF),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Débloquer AI Health Chef PRO', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),

                    // --- RESTAURER LES ACHATS ---
                    TextButton(
                      onPressed: () {
                        // Logique de restauration RevenueCat
                      },
                      child: const Text('Restaurer mes achats', style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour une ligne d'avantage
  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF6B66FF).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF6B66FF), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // Widget pour une carte de prix
  Widget _buildPlanCard({required int index, required String title, required String price, required String subtitle, required bool isPopular}) {
    final isSelected = _selectedPlan == index;
    final primaryColor = const Color(0xFF6B66FF);

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade800, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Radio button personnalisé
            Container(
              height: 24, width: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? primaryColor : Colors.grey, width: 2),
              ),
              child: isSelected ? Center(child: Container(height: 12, width: 12, decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle))) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8)),
                          child: const Text('POPULAIRE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}