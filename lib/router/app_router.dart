import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importe tous tes écrans
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/coach_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/meal_analysis_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/paywall_screen.dart';
import '../widgets/main_layout.dart';

// 1. PETITE CLASSE OUTIL : Fait le pont entre Supabase et GoRouter
// Elle prévient GoRouter dès que quelqu'un se connecte ou se déconnecte.
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

// Clés de navigation
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// 2. NOTRE ROUTEUR INTELLIGENT
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/', // Page de démarrage par défaut

  // On écoute les changements d'état de Supabase en temps réel
  refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),

  // 3. LA LOGIQUE DE REDIRECTION (Le "Videur" de la boîte de nuit)
  redirect: (context, state) {
    // On demande à Supabase : "Y a-t-il une session active en ce moment ?"
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    // On regarde sur quelle page l'utilisateur essaie d'aller
    final isGoingToLogin = state.matchedLocation == '/';
    final isGoingToOnboarding = state.matchedLocation == '/onboarding';
    final isGoingToForgotPassword = state.matchedLocation == '/forgot_password';

    // Est-ce une page "publique" liée à l'authentification ?
    final isAuthScreen = isGoingToLogin || isGoingToOnboarding || isGoingToForgotPassword;

    // RÈGLE 1 : Si NON connecté et essaie d'aller sur une page privée (ex: Dashboard)
    if (!isLoggedIn && !isAuthScreen) {
      return '/'; // On le renvoie immédiatement au Login
    }

    // RÈGLE 2 : Si DÉJÀ connecté et essaie d'aller sur la page de Login
    if (isLoggedIn && isGoingToLogin) {
      return '/dashboard'; // On l'envoie directement au Dashboard
    }

    // RÈGLE 3 : Sinon, on le laisse passer normalement
    return null;
  },

  // --- TES ROUTES ---
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
        final imagePath = state.extra as String?;
        return MealAnalysisScreen(imagePath: imagePath);
      },
    ),

    // --- SHELL ROUTE (Barre de navigation en bas) ---
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
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