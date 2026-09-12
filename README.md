# AI Health Chef

Application mobile Flutter de suivi nutritionnel : analyse de repas par photo via IA, coaching nutritionnel par chat, suivi des macros/calories et abonnement PRO.

## Fonctionnalités

- **Authentification** — inscription, connexion, mot de passe oublié (Supabase Auth)
- **Onboarding** — questionnaire de profil (objectifs, données physiques dont la taille) utilisé pour calculer les cibles nutritionnelles
- **Dashboard** — jauges de macros (calories, protéines, glucides, lipides) sur la journée, et IMC calculé à partir du profil (catégorie OMS + plage)
- **Analyse de repas par photo** — capture caméra, compression d'image, envoi à une Edge Function Supabase (`analyze-meal`) qui retourne les ingrédients détectés et leurs valeurs nutritionnelles
- **Coach IA** — chat avec un coach nutritionnel (Edge Function `coach-chat`)
- **Profil & compte** — gestion du profil utilisateur, paramètres de compte
- **Abonnement PRO** — paywall, checkout et gestion des achats in-app via RevenueCat (avec un **mode démo** intégré tant que les clés RevenueCat ne sont pas configurées, permettant de tester tout le parcours Paywall → Checkout → déblocage PRO sans compte Apple/Google payant)

## Stack technique

- **Flutter** (SDK ^3.11.0) / Dart
- **Riverpod** (`flutter_riverpod`) — gestion d'état
- **go_router** — navigation, avec redirection automatique selon l'état d'authentification Supabase
- **Supabase** (`supabase_flutter`) — authentification, base de données PostgreSQL, Edge Functions
- **RevenueCat** (`purchases_flutter`) — achats in-app iOS/Android
- **camera** / **image_picker** / **flutter_image_compress** — capture et compression des photos de repas
- **percent_indicator** — jauges circulaires du dashboard
- **google_fonts**, **shared_preferences**

## Architecture du projet

```
lib/
  models/       Modèles de données (UserProfile, Meal, Ingredient, SelectedPlan, ChatMessage)
  providers/    State management Riverpod (auth, dashboard, meal, onboarding, profile, purchase, chat)
  screens/      Écrans de l'application
  services/       Accès Supabase, IA (Edge Functions) et RevenueCat (database_service, ai_service, supabase_service, purchase_service)
  router/        Configuration go_router (routes + redirections auth)
  utils/          Calcul des cibles nutritionnelles (nutrition_targets) et de l'IMC (bmi)
  widgets/        Composants réutilisables (jauges, cartes de repas, layout principal)
test/             Tests unitaires (providers, utils)
```

## Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (compatible Dart ^3.11.0)
- Un projet [Supabase](https://supabase.com) avec le schéma de base de données initialisé et les Edge Functions `analyze-meal` et `coach-chat` déployées (voir ci-dessous)
- (Optionnel) Un projet [RevenueCat](https://www.revenuecat.com) pour activer les achats réels

## Installation

```bash
flutter pub get
```

### Configuration Supabase

1. **Clés d'API** — copie `.env.example` vers `.env` et renseigne `SUPABASE_URL` et `SUPABASE_PUBLISHABLE_KEY` avec les valeurs de ton projet (Project Settings > API dans le dashboard Supabase). `lib/main.dart` charge ces variables via `flutter_dotenv` au démarrage.
2. **Schéma de base de données** — exécute les scripts SQL de `supabase/migrations/` dans l'ordre (0001 puis 0002) depuis le **SQL Editor** du dashboard Supabase (ou via `supabase db push` si tu utilises la CLI Supabase). Ils créent les tables `profiles`, `meals`, `chat_messages`, leurs policies RLS, et le bucket de stockage `avatars`.
3. **Edge Functions** — déploie `analyze-meal` et `coach-chat` (`supabase/functions/`) avec `supabase functions deploy <nom>`, et configure les secrets qu'elles utilisent (ex. clé API du modèle IA) via `supabase secrets set` ou l'onglet Edge Functions > Secrets du dashboard.

### Configuration RevenueCat (optionnel)

Sans configuration, l'application fonctionne en **mode démo** (achats simulés, aucun appel réseau). Pour activer les achats réels, renseigne tes clés API publiques dans `lib/services/purchase_service.dart` (`_androidApiKey` / `_iosApiKey`) et configure l'entitlement `pro` correspondant dans le dashboard RevenueCat.

## Lancer l'application

```bash
flutter run
```

## Build de l'APK

```bash
flutter build apk --release
```

L'APK généré se trouve dans `build/app/outputs/flutter-apk/app-release.apk`.

- Le fichier `.env` (voir [Configuration Supabase](#configuration-supabase)) doit exister à la racine avant le build : il est embarqué comme asset et chargé au démarrage, sans lui l'app plante au lancement.
- `flutter build apk --release --split-per-abi` génère un APK par architecture (ARM/x86), plus léger qu'un APK universel.
- Pour le Play Store, préfère `flutter build appbundle --release` (format `.aab` requis).
- ⚠️ Le build release est actuellement signé avec la clé **debug** (`android/app/build.gradle.kts`) — suffisant pour tester sur un appareil, mais à remplacer par une vraie clé de signature avant toute publication sur le Play Store.

## Tests

```bash
flutter test
```

## Ressources Flutter

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
