import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// On importe notre routeur personnalisé
import 'router/app_router.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On charge les variables d'environnement depuis le fichier .env
  // (voir .env.example pour le modèle à remplir).
  await dotenv.load();

  // On lit la mémoire du téléphone
  final prefs = await SharedPreferences.getInstance();
  // S'il n'y a rien dans la mémoire (premier lancement), ça vaudra 'true'
  final showOnboarding = prefs.getBool('showOnboarding') ?? true;

  // Initialisation de Supabase à partir des clés du fichier .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  // Initialisation de RevenueCat (achats in-app natifs).
  // Nécessite les clés API RevenueCat, voir lib/services/purchase_service.dart.
  await PurchaseService.instance.configure(
    appUserId: Supabase.instance.client.auth.currentUser?.id,
  );

  // On configure notre routeur avec cette information
  setupRouter(showOnboarding);

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
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      // On connecte simplement la variable de notre nouveau fichier
      routerConfig: appRouter,
    );
  }
}