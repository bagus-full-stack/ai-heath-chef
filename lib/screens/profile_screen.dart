import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);

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
            // Avatar & Info
            const Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150'), // Mock avatar
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Alexandre Martin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Text('Pro', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 10)),
                )
              ],
            ),
            const SizedBox(height: 4),
            Text('alexandre.martin@email.com', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 40),

            // Section Général
            const Align(alignment: Alignment.centerLeft, child: Text('GÉNÉRAL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
            const SizedBox(height: 16),
            _buildMenuCard([
              _buildMenuItem(Icons.person_outline, 'Compte', onTap: () {}),
              _buildMenuItem(Icons.notifications_none, 'Notifications', badge: '2 Nouveaux', onTap: () {}),
              _buildMenuItem(Icons.credit_card, 'Abonnement', badge: 'Actif', badgeColor: primaryColor, onTap: () { context.push('/paywall'); }),
              _buildMenuItem(Icons.security, 'Sécurité et Confidentialité', showBorder: false, onTap: () {}),
            ]),
            const SizedBox(height: 30),

            // Section Assistance
            const Align(alignment: Alignment.centerLeft, child: Text('ASSISTANCE', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
            const SizedBox(height: 16),
            _buildMenuCard([
              _buildMenuItem(Icons.help_outline, 'Centre d\'aide', onTap: () {}),
              _buildMenuItem(Icons.description_outlined, 'Conditions d\'utilisation', showBorder: false, onTap: () {}),
            ]),
            const SizedBox(height: 30),

            // Déconnexion
            OutlinedButton.icon(
              onPressed: () => context.go('/'), // Retour au login
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('Déconnexion', style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('HEALTHTECH AI • VERSION 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
            const SizedBox(height: 40), // Espace pour la bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, spreadRadius: 1)],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool showBorder = true, String? badge, Color badgeColor = Colors.indigo, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(border: showBorder ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54, size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
            if (badge != null) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            if (badge != null) const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}