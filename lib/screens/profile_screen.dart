import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Fonction de déconnexion
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      // Afficher un petit indicateur de chargement natif
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // On demande à Supabase de fermer la session
      await ref.read(authServiceProvider).signOut();

      // On ferme l'indicateur de chargement
      if (context.mounted) Navigator.pop(context);

      // ET C'EST TOUT !
      // Pas besoin de faire un context.go('/') car notre routeur intelligent
      // va détecter la déconnexion et renvoyer l'utilisateur au Login automatiquement.

    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la déconnexion : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFF6B66FF);

    // On récupère l'utilisateur actuellement connecté pour afficher son email
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? 'Utilisateur inconnu';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('MON PROFIL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- EN-TÊTE PROFIL ---
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=68'), // Image de test
                  ),
                  const SizedBox(height: 16),
                  const Text('Chef Santé', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(userEmail, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        SizedBox(width: 8),
                        Text('Membre Premium', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- MENU DES OPTIONS ---
            _buildMenuOption(icon: Icons.track_changes, title: 'Mes objectifs', onTap: () {}),
            _buildMenuOption(icon: Icons.restaurant_menu, title: 'Mes préférences alimentaires', onTap: () {}),
            _buildMenuOption(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {}),
            _buildMenuOption(icon: Icons.help_outline, title: 'Aide et support', onTap: () {}),

            const SizedBox(height: 40),

            // --- BOUTON DE DÉCONNEXION ---
            OutlinedButton.icon(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('Se déconnecter', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.redAccent, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),

            Text('AI Health Chef v1.0.0', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET RÉUTILISABLE POUR LE MENU ---
  Widget _buildMenuOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.black87),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}