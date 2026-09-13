# AI Health Chef

Application mobile Flutter de suivi nutritionnel : analyse de repas et de produits par photo ou code-barres via IA, coaching nutritionnel personnalisable par chat, rappels de repas, suivi des macros/calories et abonnement PRO.

## Fonctionnalités

- **Authentification** — inscription, connexion, mot de passe oublié (Supabase Auth)
- **Onboarding** — questionnaire de profil (objectifs, données physiques dont la taille) utilisé pour calculer les cibles nutritionnelles
- **Dashboard** — jauges de macros (calories, protéines, glucides, lipides) sur la journée, IMC calculé à partir du profil (catégorie OMS + plage), et journal des repas du jour avec la photo de chaque repas
- **Analyse de repas par photo** — capture caméra, compression d'image, envoi à une Edge Function Supabase (`analyze-meal`) qui retourne les ingrédients détectés et leurs valeurs nutritionnelles
- **Analyse de produit par photo** — même principe pour un produit emballé (Edge Function `analyze-product`), lit l'étiquette nutritionnelle plutôt qu'une assiette
- **Scan de code-barres** — recherche instantanée d'un produit (EAN/UPC) via la base publique Open Food Facts, sans appel IA
- **Coach IA** — chat avec un coach nutritionnel (Edge Function `coach-chat`), et idées de repas personnalisées selon le profil/objectif (Edge Function `meal-suggestions`, mises en cache un jour à la fois)
- **Personnalisation du Coach IA** — choix du ton des réponses (motivant, bienveillant, direct, humoristique)
- **Préférences alimentaires** — régime (végétarien, végétalien, pescétarien, halal, kasher) et allergies/intolérances, pris en compte par les idées de repas et le Coach IA
- **Rappels** — notifications locales quotidiennes pour les repas (petit-déjeuner/déjeuner/dîner, activables et personnalisables individuellement) et rappels personnalisés illimités (nom + heure au choix), réglables depuis Profil > Notifications
- **Profil & compte** — gestion du profil utilisateur, paramètres de compte, photo de profil
- **Centre d'aide** — FAQ groupée par thème + contact support par email
- **Conditions d'utilisation** — CGU et mentions légales (⚠️ contenu de brouillon, voir [Notes](#notes) ci-dessous)
- **À propos** — version de l'app (lue dynamiquement), liens vers l'aide et les CGU
- **Compte admin** — accès complet aux fonctionnalités PRO sans abonnement réel, activable uniquement depuis le SQL Editor Supabase (jamais depuis l'app)
- **Quotas IA par utilisateur** — limite quotidienne d'appels par utilisateur sur chaque Edge Function IA (20/jour pour `analyze-meal`/`analyze-product`, 50/jour pour `coach-chat`, 10/jour pour `meal-suggestions`), pour contenir les coûts en cas d'abus
- **Abonnement PRO** — paywall, checkout et gestion des achats in-app via RevenueCat (avec un **mode démo** intégré tant que les clés RevenueCat ne sont pas configurées, permettant de tester tout le parcours Paywall → Checkout → déblocage PRO sans compte Apple/Google payant)

## Stack technique

- **Flutter** (SDK ^3.11.0) / Dart
- **Riverpod** (`flutter_riverpod`) — gestion d'état
- **go_router** — navigation, avec redirection automatique selon l'état d'authentification Supabase
- **Supabase** (`supabase_flutter`) — authentification, base de données PostgreSQL, Edge Functions, Storage
- **RevenueCat** (`purchases_flutter`) — achats in-app iOS/Android
- **camera** / **image_picker** / **flutter_image_compress** — capture et compression des photos de repas/produits
- **mobile_scanner** — scan de code-barres produit
- **http** — appel de l'API publique Open Food Facts (lookup produit par code-barres)
- **flutter_local_notifications** / **timezone** / **flutter_timezone** — notifications locales programmées (rappels)
- **package_info_plus** — version de l'app affichée dans "À propos"
- **url_launcher** — ouverture du client mail (contact support)
- **percent_indicator** — jauges circulaires du dashboard
- **google_fonts**, **shared_preferences**, **flutter_dotenv**

## Architecture du projet

```
lib/
  models/       UserProfile, Meal, Ingredient, SelectedPlan, ChatMessage, MealSuggestion,
                MealReminder, CustomReminder, MealAnalysisArgs
  providers/    State management Riverpod : auth, profile, dashboard (journal du jour),
                meal (analyse/scan en cours), meal_suggestions, chat, onboarding, purchase
                (entitlement PRO/admin), notification_settings, custom_reminders
  screens/      Écrans de l'application (dashboard, coach, profil, compte, onboarding,
                auth, caméra/scanner, analyse repas/produit, notifications, préférences
                alimentaires, personnalisation coach, paywall/checkout, centre d'aide,
                CGU, à propos, coming-soon)
  services/     Accès Supabase (database_service, supabase_service), IA via Edge
                Functions (ai_service), RevenueCat (purchase_service), notifications
                locales (notification_service), lookup produit Open Food Facts
                (product_lookup_service)
  router/       Configuration go_router (routes + redirections auth)
  utils/        Calcul des cibles nutritionnelles (nutrition_targets) et de l'IMC (bmi)
  widgets/      Composants réutilisables (layout principal, carte de suggestion de repas)
supabase/
  migrations/   Schéma SQL versionné (0001 à 0008, voir ci-dessous)
  functions/    Edge Functions : analyze-meal, analyze-product, coach-chat, meal-suggestions
                (+ _shared/quota.ts, vérification d'identité et quota quotidien réutilisés
                par les quatre fonctions)
test/           Tests unitaires (providers, utils)
```

## Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (compatible Dart ^3.11.0)
- Un projet [Supabase](https://supabase.com) avec le schéma de base de données initialisé et les Edge Functions `analyze-meal`, `analyze-product`, `coach-chat` et `meal-suggestions` déployées (voir ci-dessous)
- (Optionnel) Un projet [RevenueCat](https://www.revenuecat.com) pour activer les achats réels

## Installation

```bash
flutter pub get
```

### Configuration Supabase

1. **Clés d'API** — copie `.env.example` vers `.env` et renseigne `SUPABASE_URL` et `SUPABASE_PUBLISHABLE_KEY` avec les valeurs de ton projet (Project Settings > API dans le dashboard Supabase). `lib/main.dart` charge ces variables via `flutter_dotenv` au démarrage.
2. **Schéma de base de données** — exécute les scripts SQL de `supabase/migrations/` **dans l'ordre** (0001 à 0008) depuis le **SQL Editor** du dashboard Supabase (ou via `supabase db push` si tu utilises la CLI Supabase) :
   - `0001` : tables `profiles`, `meals`, `chat_messages` + policies RLS + bucket `avatars`
   - `0002` : taille (`height_cm`) sur `profiles`
   - `0003` : table `meal_suggestions` (cache des idées de repas IA)
   - `0004` : régime/allergies/ton du coach (`diet_type`, `allergies`, `coach_tone`) sur `profiles`
   - `0005` : signature de préférences sur `meal_suggestions` (invalide le cache si le régime change en cours de journée)
   - `0006` : photo de repas (`image_url` sur `meals`) + bucket `meal_photos`
   - `0007` : statut admin (`is_admin` sur `profiles`), verrouillé contre toute auto-promotion côté client
   - `0008` : table `api_usage` + fonction `increment_api_usage`, pour les quotas quotidiens par utilisateur sur les Edge Functions IA (voir ci-dessous)
3. **Edge Functions** — déploie `analyze-meal`, `analyze-product`, `coach-chat` et `meal-suggestions` (`supabase/functions/`, ainsi que le dossier partagé `supabase/functions/_shared/`) avec `supabase functions deploy <nom>`, et configure le secret `GEMINI_API_KEY` (clé API du modèle IA Google Gemini) via `supabase secrets set GEMINI_API_KEY=<clé>` ou l'onglet Edge Functions > Secrets du dashboard. Les secrets `SUPABASE_URL`/`SUPABASE_ANON_KEY`/`SUPABASE_SERVICE_ROLE_KEY` utilisés pour les quotas sont injectés automatiquement par Supabase, rien à configurer pour eux.
4. **Compte admin (optionnel)** — pour donner à un compte l'accès complet aux fonctionnalités PRO sans abonnement réel, exécute depuis le SQL Editor : `update public.profiles set is_admin = true where email = 'ton-email@exemple.com';`. Ce champ n'est modifiable que depuis le SQL Editor (aucun moyen de le changer depuis l'app, voir migration 0007).

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

### Signature release (Play Store)

Le build release est signé via `android/key.properties`, qui référence un keystore local (`.jks`). Ni l'un ni l'autre ne sont commités (voir `.gitignore`) — si `key.properties` est absent, le build retombe automatiquement sur la clé debug (utile en CI sans les secrets).

Pour générer ta propre clé sur une nouvelle machine :

```bash
keytool -genkeypair -v -keystore android/app/upload-keystore.jks \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Puis crée `android/key.properties` :

```
storePassword=<mot de passe du keystore>
keyPassword=<mot de passe de la clé, identique au précédent pour un keystore PKCS12>
keyAlias=upload
storeFile=upload-keystore.jks
```

⚠️ **Le fichier `.jks` et ses mots de passe sont irremplaçables** : sans eux, impossible de publier une mise à jour de l'app existante sur le Play Store (il faudrait republier sous un nouvel identifiant). Sauvegarde-les immédiatement dans un gestionnaire de mots de passe ou un stockage sécurisé, en dehors de ce dépôt.

## Tests

```bash
flutter test
```

## Notes

- **Notifications locales, pas de synchronisation** — les rappels (créneaux fixes et personnalisés) sont programmés en local sur l'appareil (`flutter_local_notifications`) et persistés dans `shared_preferences` : ils ne sont pas sauvegardés dans Supabase, donc ne survivent pas à une désinstallation et ne se synchronisent pas entre appareils.
- **Photos de repas** — uploadées dans le bucket `meal_photos` uniquement pour les analyses par photo ("Repas"/"Produit") ; un repas issu d'un scan de code-barres n'a pas de photo.
- **CGU/mentions légales à finaliser** — le contenu de `lib/screens/terms_screen.dart` décrit honnêtement le fonctionnement actuel de l'app (données collectées, absence de conseil médical, contenu généré par IA, abonnement), mais reste un brouillon : l'identité légale de l'éditeur (`[Nom de l'éditeur à compléter]`) et l'adresse de contact doivent être complétées, et le texte doit être relu par un professionnel du droit avant toute publication publique — un bandeau d'avertissement s'affiche sur l'écran tant que ce n'est pas fait.
- **Adresse de contact** — actuellement `support@aihealthchef.app` (`lib/screens/about_screen.dart`, constante `kSupportEmail`), à remplacer par une vraie boîte surveillée avant publication.
- **Quotas IA** — les limites quotidiennes (`supabase/functions/_shared/quota.ts`) sont volontairement généreuses pour un usage personnel normal ; ajuste les valeurs passées à `checkAndIncrementQuota(...)` dans chaque Edge Function si besoin. Un compte admin (`profiles.is_admin`) n'en est **pas** exempté — le quota s'applique à tout le monde, y compris toi.

## Ressources Flutter

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
