# AI Health Chef

Application mobile Flutter de suivi nutritionnel : analyse de repas par photo via IA, coaching nutritionnel par chat, suivi des macros/calories et abonnement PRO.

## Fonctionnalités

- **Authentification** — inscription, connexion, mot de passe oublié (Supabase Auth)
- **Onboarding** — questionnaire de profil (objectifs, données physiques) utilisé pour calculer les cibles nutritionnelles
- **Dashboard** — jauges de macros (calories, protéines, glucides, lipides) sur la journée
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
  utils/          Calcul des cibles nutritionnelles (nutrition_targets)
  widgets/        Composants réutilisables (jauges, cartes de repas, layout principal)
test/             Tests unitaires (providers, utils)
```

## Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (compatible Dart ^3.11.0)
- Un projet [Supabase](https://supabase.com) avec les Edge Functions `analyze-meal` et `coach-chat` déployées
- (Optionnel) Un projet [RevenueCat](https://www.revenuecat.com) pour activer les achats réels

## Installation

```bash
flutter pub get
```

### Configuration Supabase

L'URL et la clé publique (anon) Supabase sont actuellement définies directement dans `lib/main.dart`. Pour pointer vers ton propre projet, remplace-les par les tiennes (Project Settings > API dans le dashboard Supabase).

### Configuration RevenueCat (optionnel)

Sans configuration, l'application fonctionne en **mode démo** (achats simulés, aucun appel réseau). Pour activer les achats réels, renseigne tes clés API publiques dans `lib/services/purchase_service.dart` (`_androidApiKey` / `_iosApiKey`) et configure l'entitlement `pro` correspondant dans le dashboard RevenueCat.

## Lancer l'application

```bash
flutter run
```

## Tests

```bash
flutter test
```

## Ressources Flutter

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
