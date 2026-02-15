// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import 'package:ai_health_chef/screens/login_screen.dart';
// import 'package:ai_health_chef/screens/dashboard_screen.dart';
// import 'package:ai_health_chef/screens/meal_analysis_screen.dart';
// import 'package:ai_health_chef/screens/onboarding_screen.dart';
// import 'package:ai_health_chef/screens/coach_screen.dart';
// import 'package:ai_health_chef/widgets/main_layout.dart';
// import 'package:ai_health_chef/screens/profile_screen.dart';
// import 'package:ai_health_chef/screens/forgot_password_screen.dart';
// import 'package:ai_health_chef/screens/paywall_screen.dart';
//
//
// // --- INITIALISATION ---
// void main() async {
//   // Nécessaire pour initialiser des plugins avant le lancement de l'app
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Initialisation de Supabase (Remplace par tes vraies clés Supabase plus tard)
//   await Supabase.initialize(
//     url: 'https://atmandnlqyyjaofezyig.supabase.co',
//     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0bWFuZG5scXl5amFvZmV6eWlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2Nzc4OTUsImV4cCI6MjA4NjI1Mzg5NX0.MHmN5m1rqJvSnMHda9kYplXXnA7KsJBJBgnyptrpq1A',
//   );
//
//   // ProviderScope est OBLIGATOIRE pour utiliser Riverpod dans toute l'app
//   runApp(const ProviderScope(child: MyApp()));
// }
//
// // --- CONFIGURATION DU ROUTEUR ---
// // On crée des clés pour séparer la navigation globale de la navigation des onglets
// final _rootNavigatorKey = GlobalKey<NavigatorState>();
// final _shellNavigatorKey = GlobalKey<NavigatorState>();
//
// final _router = GoRouter(
//   navigatorKey: _rootNavigatorKey,
//   initialLocation: '/',
//   routes: [
//     GoRoute(
//       path: '/',
//       builder: (context, state) => const LoginScreen(),
//     ),
//     GoRoute(
//       path: '/onboarding',
//       builder: (context, state) => const OnboardingScreen(),
//     ),
//     GoRoute(
//       path: '/meal_analysis',
//       builder: (context, state) {
//         final imagePath = state.extra as String?;
//         return MealAnalysisScreen(imagePath: imagePath);
//       },
//     ),
//     GoRoute(
//       path: '/forgot_password',
//       builder: (context, state) => const ForgotPasswordScreen(),
//     ),
//     GoRoute(
//       path: '/paywall',
//       builder: (context, state) => const PaywallScreen(),
//     ),
//
//     // --- SHELL ROUTE (Les écrans avec la Bottom Navigation Bar) ---
//     ShellRoute(
//       navigatorKey: _shellNavigatorKey,
//       builder: (context, state, child) {
//         // Enveloppe les écrans enfants dans le MainLayout
//         return MainLayout(child: child);
//       },
//       routes: [
//         GoRoute(
//           path: '/dashboard',
//           parentNavigatorKey: _shellNavigatorKey,
//           builder: (context, state) => const DashboardScreen(),
//         ),
//         GoRoute(
//           path: '/coach',
//           parentNavigatorKey: _shellNavigatorKey,
//           builder: (context, state) => const CoachScreen(),
//         ),
//         GoRoute(
//           path: '/profile',
//           parentNavigatorKey: _shellNavigatorKey,
//           builder: (context, state) => const ProfileScreen(),
//         ),
//       ],
//     ),
//   ],
// );
//
// // --- APPLICATION PRINCIPALE ---
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp.router(
//       title: 'AI Health Chef',
//       debugShowCheckedModeBanner: false, // Enlève le petit bandeau "DEBUG"
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF6B66FF), // Ton violet principal
//           background: Colors.white,
//         ),
//         useMaterial3: true,
//       ),
//       routerConfig: _router, // On connecte GoRouter
//     );
//   }
// }
//
// // --- ÉCRAN TEMPORAIRE ---
// // Juste pour tester que le router fonctionne avant de créer tes vrais écrans
// class PlaceholderScreen extends StatelessWidget {
//   final String title;
//   const PlaceholderScreen({super.key, required this.title});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(title)),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () {
//             // Test simple de navigation
//             if (title.contains('Connexion')) {
//               context.go('/dashboard');
//             } else {
//               context.go('/');
//             }
//           },
//           child: const Text('Aller à la page suivante'),
//         ),
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// On importe notre routeur personnalisé
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase (les clés seront à changer plus tard)
  await Supabase.initialize(
    url: 'https://atmandnlqyyjaofezyig.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0bWFuZG5scXl5amFvZmV6eWlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2Nzc4OTUsImV4cCI6MjA4NjI1Mzg5NX0.MHmN5m1rqJvSnMHda9kYplXXnA7KsJBJBgnyptrpq1A',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Health Chef',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B66FF),
          background: Colors.white,
        ),
        useMaterial3: true,
      ),
      // On connecte simplement la variable de notre nouveau fichier
      routerConfig: appRouter,
    );
  }
}