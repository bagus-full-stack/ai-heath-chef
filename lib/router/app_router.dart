import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT DE TOUS TES ÉCRANS ---
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/coach_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/meal_analysis_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/paywall_screen.dart';
import '../widgets/main_layout.dart';

// --- 1. CLASSE OUTIL : Pont entre Supabase et GoRouter ---
// Permet à l'application de réagir instantanément aux connexions/déconnexions
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
    );
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Clés de navigation (nécessaires pour le bon fonctionnement du ShellRoute)
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// --- 2. DÉCLARATION DU ROUTEUR ---
// On le déclare en "late" car il va être initialisé dans la fonction setupRouter
late final GoRouter appRouter;

// --- 3. FONCTION D'INITIALISATION ---
// Elle est appelée depuis main.dart et reçoit l'info : l'utilisateur a-t-il déjà vu l'onboarding ?
void setupRouter(bool showOnboarding) {
  appRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,

    // Page de démarrage dynamique
    initialLocation: showOnboarding ? '/onboarding' : '/',

    // On écoute l'état de Supabase
    refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),

    // --- 4. LA LOGIQUE DE REDIRECTION (Le "Videur") ---
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;

      final isGoingToLogin = state.matchedLocation == '/';
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';
      final isGoingToForgotPassword = state.matchedLocation == '/forgot_password';

      final isAuthScreen = isGoingToLogin || isGoingToOnboarding || isGoingToForgotPassword;

      // RÈGLE 1 : Si NON connecté et essaie d'aller sur une page privée
      if (!isLoggedIn && !isAuthScreen) {
        return '/'; // Retour au Login
      }

      // RÈGLE 2 : Si DÉJÀ connecté et essaie d'aller sur une page publique
      if (isLoggedIn && isAuthScreen) {
        return '/dashboard'; // Accès direct au Dashboard
      }

      // RÈGLE 3 : Sinon, on laisse passer
      return null;
    },

    // --- 5. DÉCLARATION DES ROUTES ---
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/meal_analysis',
        builder: (context, state) {
          // On récupère le chemin de l'image passé en paramètre
          final imagePath = state.extra as String?;
          return MealAnalysisScreen(imagePath: imagePath);
        },
      ),

      // --- SHELL ROUTE (Gère la barre de navigation en bas) ---
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          // MainLayout est le "cadre" qui contient la BottomNavigationBar
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/coach',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const CoachScreen(),
          ),
          GoRoute(
            path: '/profile',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}