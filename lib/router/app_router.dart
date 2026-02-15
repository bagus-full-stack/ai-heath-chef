import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Importe tous tes écrans ici
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/coach_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/meal_analysis_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/paywall_screen.dart';
import '../widgets/main_layout.dart';

// Clés de navigation pour gérer la Bottom Navigation Bar
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// On crée notre routeur public
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/', // Page de démarrage
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

    // --- SHELL ROUTE (Écrans avec la barre de navigation en bas) ---
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