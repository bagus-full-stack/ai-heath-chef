import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child; // L'écran actuel (Dashboard, Coach ou Profil)

  const MainLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    // On regarde l'URL actuelle pour allumer le bon bouton
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/coach')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0; // Par défaut
  }

  void _onItemTapped(int index, BuildContext context) {
    // On navigue vers la bonne page quand on clique sur un bouton
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/coach');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);

    return Scaffold(
      body: child, // Affiche l'écran sélectionné
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Coach'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}