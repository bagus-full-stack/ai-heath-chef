import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'local_db/weight_repository.dart';
import 'local_db/hydration_repository.dart';
import 'local_db/local_db_provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'config/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On charge les variables d'environnement depuis le fichier .env
  // (voir .env.example pour le modèle à remplir).
  await dotenv.load();

  // Initialisation de l'IA locale (Gemma3n, format .litertlm). Enregistre
  // uniquement le moteur d'inférence ici — le token Hugging Face n'est
  // récupéré (via l'Edge Function hc-huggingface-token) qu'au moment où
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
    // Instance partagée entre plusieurs apps : les tables vivent dans ce schéma.
    postgrestOptions: const PostgrestClientOptions(schema: 'health_chef'),
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
  final weightRepository = WeightRepository(localDb);
  final hydrationRepository = HydrationRepository(localDb);
  unawaited(mealRepository.syncPendingMeals());
  unawaited(weightRepository.syncEntries());
  unawaited(hydrationRepository.syncEntries());
  Connectivity().onConnectivityChanged.listen((results) {
    if (!results.contains(ConnectivityResult.none)) {
      mealRepository.syncPendingMeals();
      weightRepository.syncEntries();
      hydrationRepository.syncEntries();
    }
  });

  runApp(ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(localDb)],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).value;

    return MaterialApp.router(
      title: 'Fodli',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      // Les jetons AppColors lisent un drapeau statique : on le synchronise avec la
      // luminosité effective, et la clé reconstruit l'arbre quand elle change.
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        AppColors.dark = dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          // Icônes de la barre d'état lisibles dans les deux thèmes.
          value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: KeyedSubtree(key: ValueKey(dark), child: child ?? const SizedBox.shrink()),
        );
      },
      // On connecte simplement la variable de notre nouveau fichier
      routerConfig: appRouter,
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  AppColors.dark = dark; // pour que les getters ci-dessous donnent la bonne variante
  final brand = AppColors.brand;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF134E3F),
    brightness: brightness,
    primary: brand,
    onPrimary: Colors.white,
    surface: AppColors.surface,
  );
  final grey = dark ? const Color(0xFF8A918F) : const Color(0xFF6B7280);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    // Interrupteur « off » : contour et pouce assez contrastés (le gris sur gris par défaut se perd).
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : grey,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.transparent : grey,
      ),
    ),
  );
}
