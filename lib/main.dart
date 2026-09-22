import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// On importe notre routeur personnalisé
import 'router/app_router.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'local_db/app_database.dart';
import 'local_db/meal_repository.dart';
import 'local_db/local_db_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On charge les variables d'environnement depuis le fichier .env
  // (voir .env.example pour le modèle à remplir).
  await dotenv.load();

  // Initialisation de l'IA locale (Gemma3n, format .litertlm). Enregistre
  // uniquement le moteur d'inférence ici — le token Hugging Face n'est
  // récupéré (via l'Edge Function huggingface-token) qu'au moment où
  // l'utilisateur lance explicitement le téléchargement du modèle depuis
  // Profil > IA locale, pas au démarrage de l'app.
  await FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()]);

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

  // Initialisation des notifications locales (rappels de repas).
  await NotificationService.instance.initialize();

  // On configure notre routeur avec cette information
  setupRouter(showOnboarding);

  // Base locale (repas hors ligne) partagée entre le provider Riverpod et le
  // déclenchement de synchronisation au retour du réseau ci-dessous.
  final localDb = AppDatabase();
  final mealRepository = MealRepository(localDb);
  unawaited(mealRepository.syncPendingMeals());
  Connectivity().onConnectivityChanged.listen((results) {
    if (!results.contains(ConnectivityResult.none)) {
      mealRepository.syncPendingMeals();
    }
  });

  runApp(ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(localDb)],
    child: const MyApp(),
  ));
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