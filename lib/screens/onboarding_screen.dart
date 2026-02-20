import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Les données de nos 3 pages d'explication
  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Prends tes repas en photo',
      'description': 'Plus besoin de peser ou de chercher dans de longues listes. Une simple photo de ton assiette suffit.',
      'icon': Icons.camera_alt_rounded,
    },
    {
      'title': 'Analyse IA instantanée',
      'description': 'Notre intelligence artificielle détecte les ingrédients et calcule tes macros avec une précision bluffante.',
      'icon': Icons.auto_awesome,
    },
    {
      'title': 'Atteins tes objectifs',
      'description': 'Suis tes calories quotidiennes et discute avec ton Coach IA personnel pour rester motivé à 100%.',
      'icon': Icons.track_changes_rounded,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- BOUTON PASSER (SKIP) ---
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                child: TextButton(
                  onPressed: () => _finishOnboarding(), // Va vers l'écran de Login
                  child: Text('Passer', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ),
              ),
            ),

            // --- LE CARROUSEL ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Cercle avec icône
                        Container(
                          height: 220,
                          width: 220,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page['icon'],
                            size: 100,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 60),

                        // Titre
                        Text(
                          page['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Description
                        Text(
                          page['description'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // --- INDICATEURS ET BOUTON PRINCIPAL ---
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  // Les petits points animés (Dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        // Le point actif est plus large (24) que les inactifs (8)
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? primaryColor : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Bouton Suivant / C'est parti
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        // Dernière page : on redirige vers l'inscription/connexion
                        _finishOnboarding();
                      } else {
                        // Pages précédentes : on fait glisser vers la droite
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? "C'est parti !" : 'Suivant',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    // On sauvegarde dans la mémoire du téléphone qu'on a vu cet écran
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);

    // Ensuite, on va vers l'écran de connexion
    if (mounted) context.go('/');
  }
}