# AI Health Chef

Application mobile Flutter de suivi nutritionnel : analyse de repas et de produits par photo ou code-barres via IA, coaching nutritionnel personnalisable par chat, rappels de repas, suivi des macros/calories et abonnement PRO.

## Fonctionnalités

- **Authentification** — inscription, connexion, mot de passe oublié (Supabase Auth)
- **Onboarding** — questionnaire de profil (objectifs, données physiques dont la taille) utilisé pour calculer les cibles nutritionnelles
- **Dashboard** — jauges de macros (calories, protéines, glucides, lipides) sur la journée, IMC calculé à partir du profil (catégorie OMS + plage), suivi de l'hydratation (objectif quotidien, ajout rapide en un tap, annulable), et journal des repas du jour avec la photo de chaque repas (suppression d'un repas par glissement, ou relance en un tap pour reloguer un repas déjà mangé)
- **Hors ligne (local-first)** — repas, pesées et prises d'eau enregistrés d'abord dans une base SQLite locale (fonctionne sans connexion), puis synchronisés vers Supabase dès que le réseau est disponible (au démarrage et à chaque retour de connexion) : survivent à une désinstallation et se retrouvent sur un nouvel appareil
- **Analyse nutritionnelle étendue (PRO)** — en plus des macros principales, fibres/sucres/graisses saturées sont estimés par l'IA (ou lus depuis Open Food Facts pour un scan code-barres) et affichés en moyenne quotidienne dans les Analyses avancées, avec un graphique d'évolution des calories sur 30 jours (ligne cible incluse, valeurs au tap)
- **Analyse de repas par photo** — capture caméra, compression d'image, envoi à une Edge Function Supabase (`analyze-meal`) qui retourne les ingrédients détectés et leurs valeurs nutritionnelles
- **Analyse de produit par photo** — même principe pour un produit emballé (Edge Function `analyze-product`), lit l'étiquette nutritionnelle plutôt qu'une assiette
- **Scan de menu restaurant** — photo de la carte d'un restaurant (Edge Function `analyze-menu`) : un plat détecté = une carte indépendante (portion + macros estimées), affichée sans total combiné puisque les plats d'une carte ne sont pas mangés ensemble, ajoutable individuellement au journal
- **Recette à partir du frigo/placard** — photo de l'intérieur d'un frigo ou d'un placard (Edge Function `analyze-pantry`) : inventaire des aliments identifiés, corrigible (ajout/suppression manuelle) avant de lancer la génération de 3 recettes (`meal-suggestions`) qui priorisent ces ingrédients déjà disponibles
- **Scan de code-barres** — recherche instantanée d'un produit (EAN/UPC) via la base publique Open Food Facts, sans appel IA
- **Coach IA** — chat avec un coach nutritionnel (Edge Function `coach-chat`), et idées de repas personnalisées selon le profil/objectif (Edge Function `meal-suggestions`, mises en cache un jour à la fois), chacune illustrée par une image générée via Pollinations.ai (Edge Function `meal-images`, voir ci-dessous). Chaque ingrédient d'une recette signale une correspondance avec une allergie déclarée et propose un substitut (mots-clés locaux, ex. lait → lait d'avoine), aussi utilisable en dépannage ("je n'ai pas ça dans mon placard") même sans allergie
- **Plan de repas hebdomadaire** — génère en un seul appel IA un plan complet (7 jours × 3 repas) adapté au profil/régime/allergies, mis en cache par semaine, ouvert depuis l'icône calendrier de l'écran "Idées repas" ; chaque repas garde recette/macros et peut être ajouté individuellement à la liste de courses, ou la semaine entière en un tap. Pas d'illustrations IA générées pour ce plan (21 repas d'un coup serait trop coûteux/lent) — les cartes retombent sur l'icône du moment de la journée. Export du plan en calendrier (`.ics`, un événement par repas à des heures par défaut) importable dans Google/Apple/Outlook Calendar via le partage natif
- **Liste de courses** — alimentée en un tap depuis les ingrédients d'une idée de repas du Coach IA (ou du plan hebdomadaire), cochable, persistée localement
- **Suivi du poids** — historique des pesées (synchronisé, voir [Hors ligne](#fonctionnalités) ci-dessus) avec courbe de progression, et rappel hebdomadaire de pesée réutilisant le système de rappels personnalisés (voir ci-dessous)
- **Jeûne intermittent** — minuteur avec objectif de durée au choix (12h à 24h), démarrage/arrêt manuel, anneau de progression coloré une fois l'objectif atteint (état purement local, pas de tâche de fond : le minuteur ne tourne qu'à l'écran ouvert)
- **Widget écran d'accueil (Android)** — calories du jour/objectif et streak actuel, mis à jour à chaque ouverture du dashboard ; pas d'équivalent iOS (nécessiterait une extension WidgetKit distincte, hors périmètre sans Mac)
- **Export du journal alimentaire** — export CSV des repas des N derniers jours (utilisable avec un nutritionniste, Excel/Sheets), ou bilan nutritionnel en PDF (hebdomadaire ou mensuel : moyennes de macros, cibles, évolution du poids pour le mensuel), tous partagés via le sélecteur natif
- **Personnalisation du Coach IA** — choix du ton des réponses (motivant, bienveillant, direct, humoristique)
- **Préférences alimentaires** — régime (végétarien, végétalien, pescétarien, halal, kasher) et allergies/intolérances, pris en compte par les idées de repas et le Coach IA
- **Rappels** — notifications locales quotidiennes pour les repas (petit-déjeuner/déjeuner/dîner, activables et personnalisables individuellement) et rappels personnalisés illimités (nom + heure au choix, quotidien ou un jour de la semaine donné — ex. le rappel de pesée hebdomadaire), réglables depuis Profil > Notifications. Tant qu'un créneau repas n'a jamais été réglé manuellement, son heure par défaut est déduite de l'historique de repas de l'utilisateur (heure habituelle sur les 30 derniers jours) plutôt qu'un horaire fixe générique. Les rappels personnalisés sont aussi sauvegardés sur Supabase et restaurés automatiquement sur un appareil "vide" (nouvelle install/nouveau téléphone) ; les créneaux fixes petit-déjeuner/déjeuner/dîner restent purement locaux (rapides à réactiver manuellement)
- **Profil & compte** — gestion du profil utilisateur, paramètres de compte, photo de profil
- **Sécurité et confidentialité** — changement du mot de passe depuis Profil > Sécurité (session active requise, pas de ré-saisie de l'ancien mot de passe). Le 2FA n'est pas encore implémenté (chantier séparé : nécessite aussi une vérification à la connexion, pas seulement un écran d'inscription)
- **Suppression de compte** — parcours complet depuis Profil > Sécurité > Supprimer mon compte : confirmation explicite (mot de confirmation à ressaisir), suppression côté serveur (Storage + lignes Postgres via cascade + compte Auth, Edge Function `delete-account`), purge locale (base SQLite, préférences, rappels programmés, widget écran d'accueil) puis déconnexion. Avertit qu'un abonnement Apple/Google actif n'est pas annulé automatiquement (lien vers la gestion des abonnements du store)
- **Centre d'aide** — FAQ groupée par thème + contact support par email
- **Conditions d'utilisation** — CGU et mentions légales (⚠️ contenu de brouillon, voir [Notes](#notes) ci-dessous)
- **À propos** — version de l'app (lue dynamiquement), liens vers l'aide et les CGU
- **Compte admin** — accès complet aux fonctionnalités PRO sans abonnement réel, activable uniquement depuis le SQL Editor Supabase (jamais depuis l'app)
- **Quotas IA par utilisateur** — limite quotidienne d'appels par utilisateur sur chaque Edge Function IA (20/jour pour `analyze-meal`/`analyze-product`/`analyze-menu`/`analyze-pantry`, 50/jour pour `coach-chat`, 10/jour pour `meal-suggestions`/`meal-images`), pour contenir les coûts en cas d'abus
- **Quota IA global (protection du budget partagé)** — en plus du quota par utilisateur, `analyze-meal`, `analyze-product`, `analyze-menu`, `analyze-pantry`, `coach-chat` et `meal-suggestions` (celles qui appellent la clé `GEMINI_API_KEY`, partagée par toute l'app) respectent aussi un plafond quotidien **agrégé, tous utilisateurs confondus** (500/jour pour `analyze-meal`/`analyze-product`/`analyze-menu`/`analyze-pantry`, 1000/jour pour `coach-chat`, 300/jour pour `meal-suggestions`) : un disjoncteur qui évite qu'un usage normal mais nombreux épuise silencieusement le débit/budget gratuit d'une seule clé partagée
- **Abonnement PRO** — paywall, checkout et gestion des achats in-app via RevenueCat (avec un **mode démo** intégré tant que les clés RevenueCat ne sont pas configurées, permettant de tester tout le parcours Paywall → Checkout → déblocage PRO sans compte Apple/Google payant)
- **IA locale (scan + chat, optionnelle, gratuite)** — Gemma3n exécuté directement sur l'appareil (`flutter_gemma`), activable depuis Profil > IA locale : analyse photo et chat coach fonctionnent alors sans connexion et sans consommer le quota cloud partagé. Repli automatique sur le cloud si le modèle n'est pas téléchargé ou échoue. Jamais derrière un abonnement PRO — voir [IA locale](#ia-locale) ci-dessous pour la configuration.
- **Bilingue Français/English** — sélecteur de langue depuis Profil > Langue (persisté), toute l'UI est traduite (ARB + `flutter_localizations`), et la langue choisie est aussi transmise à l'IA (analyse de repas/produit, coach, suggestions de repas — cloud et locale) pour qu'elle réponde dans la même langue

## Stack technique

- **Flutter** (SDK ^3.12.0) / Dart
- **Riverpod** (`flutter_riverpod`) — gestion d'état
- **go_router** — navigation, avec redirection automatique selon l'état d'authentification Supabase
- **Supabase** (`supabase_flutter`) — authentification, base de données PostgreSQL, Edge Functions, Storage
- **RevenueCat** (`purchases_flutter`) — achats in-app iOS/Android
- **camera** / **image_picker** / **flutter_image_compress** — capture et compression des photos de repas/produits
- **mobile_scanner** — scan de code-barres produit
- **http** — appel de l'API publique Open Food Facts (lookup produit par code-barres)
- **drift** / **drift_flutter** — base de données locale (SQLite) pour le mode hors ligne
- **connectivity_plus** — détection du retour réseau pour déclencher la synchronisation des repas en attente
- **uuid** — génération des id de repas côté client
- **flutter_local_notifications** / **timezone** / **flutter_timezone** — notifications locales programmées (rappels)
- **package_info_plus** — version de l'app affichée dans "À propos"
- **url_launcher** — ouverture du client mail (contact support)
- **share_plus** / **path_provider** — export CSV/PDF/.ics du journal alimentaire et partage via le sélecteur natif
- **pdf** — génération des bilans nutritionnels PDF (hebdomadaire/mensuel)
- **home_widget** — widget écran d'accueil Android (macros du jour + streak)
- **percent_indicator** — jauges circulaires du dashboard
- **fl_chart** — graphique d'évolution des calories sur 30 jours (Analyses avancées)
- **google_fonts**, **shared_preferences**, **flutter_dotenv**
- **flutter_gemma** / **flutter_gemma_litertlm** — IA locale (Gemma3n, scan + chat) exécutée sur l'appareil, sans connexion
- **flutter_localizations** / **intl** — localisation FR/EN (ARB, génération native Flutter)

## Architecture du projet

```
lib/
  config/       Paramètres du modèle IA locale (local_ai_config)
  l10n/         Localisation FR/EN : fichiers source app_fr.arb/app_en.arb, AppLocalizations
                généré par flutter gen-l10n, extension context.l10n
  local_db/     Base de données locale (drift/SQLite) et synchronisation hors ligne :
                app_database (schéma + migrations), meal_repository (source de vérité des
                repas, écrit en local puis pousse vers Supabase), weight_repository et
                hydration_repository (même principe : écrivent en local puis synchronisent
                vers Supabase dans les deux sens, restauration comprise), local_db_provider
  models/       UserProfile, Meal, Ingredient, SelectedPlan, ChatMessage, MealSuggestion,
                MealReminder, CustomReminder, MealAnalysisArgs, ShoppingItem
  providers/    State management Riverpod : auth, profile, dashboard (journal du jour,
                hydratation et widget écran d'accueil, lus depuis la base locale), meal
                (analyse/scan en cours : repas, produit, menu ou frigo/placard),
                meal_suggestions, weekly_meal_plan, pantry_recipes (recettes générées à
                partir d'un inventaire détecté), fasting (jeûne intermittent), chat,
                onboarding, purchase (entitlement PRO/admin), notification_settings,
                custom_reminders, shopping_list, local_ai (activation/téléchargement de
                l'IA locale), locale (langue choisie, persistée)
  screens/      Écrans de l'application (dashboard, coach, profil, compte, sécurité,
                onboarding, auth, caméra/scanner, analyse repas/produit, scan de menu,
                scan de frigo/placard + recettes générées, jeûne intermittent,
                notifications, suivi du poids, liste de courses, IA locale, préférences
                alimentaires, personnalisation coach, paywall/checkout, centre d'aide,
                CGU, à propos, coming-soon)
  services/     Accès Supabase (database_service, supabase_service), IA cloud via Edge
                Functions (ai_service), IA locale sur l'appareil (local_ai_service),
                RevenueCat (purchase_service), notifications locales
                (notification_service), lookup produit Open Food Facts
                (product_lookup_service), widget écran d'accueil Android
                (home_widget_service)
  router/       Configuration go_router (routes + redirections auth)
  utils/        Calcul des cibles nutritionnelles (nutrition_targets) et de l'IMC (bmi),
                résumés nutritionnels journaliers pour les exports PDF
                (daily_nutrition_summary), export calendrier .ics du plan hebdomadaire
                (ics_export), heures de repas habituelles déduites de l'historique
                (typical_meal_times), suggestion de substitut d'ingrédient par mots-clés
                (ingredient_substitution)
  widgets/      Composants réutilisables (layout principal, carte de suggestion de repas)
android/app/src/main/kotlin/.../HealthChefWidgetProvider.kt
                Rendu natif du widget écran d'accueil (RemoteViews), alimenté par les
                données poussées depuis home_widget_service.dart
supabase/
  migrations/   Schéma SQL versionné (0001 à 0017, voir ci-dessous)
  functions/    Edge Functions : analyze-meal, analyze-product, analyze-menu,
                analyze-pantry, coach-chat, meal-suggestions, meal-images,
                huggingface-token, delete-account — déployées en CI via la CLI
                Supabase (voir ci-dessous), qui bundle les imports relatifs. La
                vérification d'identité et le quota (quotidien par utilisateur +
                global partagé) vivent dans `_shared/quota.ts`, importé par
                chaque fonction IA ; `_shared/cors.ts` et `_shared/errors.ts`
                mutualisent de même les headers CORS et la classe d'erreur HTTP
                (`HttpError`), et `_shared/gemini.ts` mutualise le mécanisme de
                cascade entre modèles Gemini (fetch, timeout, retry) — chaque
                fonction garde néanmoins SA PROPRE liste de modèles `MODELS`
                (elles divergent entre fonctions par drift historique, non
                harmonisées). analyze-menu et analyze-pantry sont des quasi-copies
                d'analyze-meal (même contrat JSON `{ ingredients: [...] }`), seul le prompt
                change (carte de restaurant / inventaire de frigo plutôt qu'assiette).
                delete-account n'a pas de quota IA (aucun appel GEMINI_API_KEY) mais applique
                son propre rate limit (3 tentatives/heure, voir migration 0017).
test/           Tests unitaires (providers, utils)
```

## Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (compatible Dart ^3.12.0 — bump récent, requis par `flutter_gemma`)
- Un projet [Supabase](https://supabase.com) avec le schéma de base de données initialisé et les Edge Functions `analyze-meal`, `analyze-product`, `analyze-menu`, `analyze-pantry`, `coach-chat`, `meal-suggestions`, `meal-images`, `huggingface-token` et `delete-account` déployées (voir ci-dessous)
- (Optionnel) Un projet [RevenueCat](https://www.revenuecat.com) pour activer les achats réels

## Installation

```bash
flutter pub get
```

### Configuration Supabase

1. **Clés d'API** — copie `.env.example` vers `.env` et renseigne `SUPABASE_URL` et `SUPABASE_PUBLISHABLE_KEY` avec les valeurs de ton projet (Project Settings > API dans le dashboard Supabase). `lib/main.dart` charge ces variables via `flutter_dotenv` au démarrage.
2. **Schéma de base de données** — exécute les scripts SQL de `supabase/migrations/` **dans l'ordre** (0001 à 0019) depuis le **SQL Editor** du dashboard Supabase, ou laisse la CI le faire : `.github/workflows/deploy_functions.yml` lance automatiquement `supabase db push` sur push vers `master` dès qu'un fichier change dans `supabase/migrations/` (nécessite les secrets GitHub `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_ID` et `SUPABASE_DB_PASSWORD` — mot de passe de la base, Project Settings > Database). ⚠️ Ne mélange pas les deux : si tu as déjà appliqué une migration manuellement via le SQL Editor, le `supabase db push` CI échouera ou la rejouera en double tant que l'historique local (`supabase migration list`) n'est pas resynchronisé avec la prod.
   - `0001` : tables `profiles`, `meals`, `chat_messages` + policies RLS + bucket `avatars`
   - `0002` : taille (`height_cm`) sur `profiles`
   - `0003` : table `meal_suggestions` (cache des idées de repas IA)
   - `0004` : régime/allergies/ton du coach (`diet_type`, `allergies`, `coach_tone`) sur `profiles`
   - `0005` : signature de préférences sur `meal_suggestions` (invalide le cache si le régime change en cours de journée)
   - `0006` : photo de repas (`image_url` sur `meals`) + bucket `meal_photos`
   - `0007` : statut admin (`is_admin` sur `profiles`), verrouillé contre toute auto-promotion côté client
   - `0008` : table `api_usage` + fonction `increment_api_usage`, pour les quotas quotidiens par utilisateur sur les Edge Functions IA (voir ci-dessous)
   - `0009` : table `global_api_usage` + fonction `increment_global_api_usage`, pour le quota global (tous utilisateurs confondus) qui protège le budget/débit partagé de `GEMINI_API_KEY` (voir ci-dessous)
   - `0010` : fibres/sucres/graisses saturées (`total_fiber`/`total_sugar`/`total_sat_fat` sur `meals`), en plus des macros principales
   - `0011` : tables `weight_entries`, `hydration_entries` et `custom_reminders_backup` — synchronisation cross-device du poids, de l'hydratation et des rappels personnalisés (voir [Notes](#notes))
   - `0012` : photo de progression (`image_url`/`local_image_path` sur `weight_entries`) + bucket `weight_photos`
   - `0013` : table `weekly_meal_plans` (cache du plan de repas hebdomadaire généré par l'IA)
   - `0014` : préférence de cuisine (`cuisine_preference` sur `profiles`), pour orienter les idées de repas générées
   - `0015` : illustration IA d'un plat recommandé par le coach (`image_url` sur `chat_messages`)
   - `0016` : variante de `increment_global_api_usage` acceptant un incrément explicite (`p_increment`), utilisée par `meal-images` quand plusieurs images sont générées en un seul appel
   - `0017` : table `delete_account_attempts` + fonction `check_delete_account_rate_limit`, pour le rate limit (3 tentatives/heure) sur la suppression de compte
   - `0018` : traçabilité de l'acceptation des CGU (`accepted_terms_at`/`accepted_terms_version` sur `profiles`)
   - `0019` : illustrations du coach dans Storage plutôt qu'en base64 (`image_path` sur `chat_messages`) + bucket **privé** `chat_images` (policies scopées à `{user_id}/...`, URL signée générée à la demande côté app) — voir `supabase/scripts/backfill_chat_images.dart` pour migrer les anciens messages (`image_url`, conservée en lecture pour rétrocompatibilité) vers ce bucket
3. **Edge Functions** — déploie `analyze-meal`, `analyze-product`, `analyze-menu`, `analyze-pantry`, `coach-chat`, `meal-suggestions`, `meal-images`, `huggingface-token` et `delete-account` (`supabase/functions/`), et configure le secret `GEMINI_API_KEY` (clé API du modèle IA Google Gemini) via `supabase secrets set GEMINI_API_KEY=<clé>` ou l'onglet Edge Functions > Secrets du dashboard. Les secrets `SUPABASE_URL`/`SUPABASE_ANON_KEY`/`SUPABASE_SERVICE_ROLE_KEY` utilisés pour les quotas (et par `delete-account`) sont injectés automatiquement par Supabase, rien à configurer pour eux. En CI, `.github/workflows/deploy_functions.yml` déploie automatiquement tous les sous-dossiers de `supabase/functions/`, `delete-account` inclus — aucune modification du workflow n'est nécessaire.
   - Les fonctions IA (`analyze-meal`, `analyze-product`, `analyze-menu`, `analyze-pantry`, `coach-chat`, `meal-suggestions`, `meal-images`) importent la logique commune depuis `supabase/functions/_shared/` (`quota.ts`, `cors.ts`, `errors.ts`, `gemini.ts`) via des imports relatifs (`../_shared/...`) : la CLI Supabase les bundle automatiquement au déploiement, il n'y a rien à copier manuellement. Chaque fonction garde en revanche sa propre liste de modèles Gemini (`MODELS`), volontairement non harmonisée (voir ci-dessus).
4. **Illustrations des idées de repas (optionnel, 100% gratuit)** — `meal-images` génère une image IA par suggestion, en cascade entre deux fournisseurs gratuits :
   - **Cloudflare Workers AI (FLUX.1 [schnell])**, essayé en premier — meilleure qualité, gratuit jusqu'à ~10 000 Neurons/jour (~100 images, partagées entre tous les utilisateurs de l'app), sans carte bancaire requise. Crée un compte gratuit sur [dash.cloudflare.com](https://dash.cloudflare.com), récupère ton **Account ID** (visible sur le Dashboard) et crée un **API Token** avec la permission "Workers AI" (My Profile > API Tokens), puis configure les secrets `CLOUDFLARE_ACCOUNT_ID` et `CLOUDFLARE_API_TOKEN`.
   - **[Pollinations.ai](https://pollinations.ai)**, utilisé en repli si Cloudflare échoue ou n'est pas configuré — fonctionne **sans compte** (accès anonyme, gratuit, limité en débit). Pour un accès plus rapide et sans watermark, crée un compte sur [auth.pollinations.ai](https://auth.pollinations.ai) et configure le secret `POLLINATIONS_TOKEN`.

   Configure les secrets utilisés via `supabase secrets set <NOM>=<valeur>` ou l'onglet Edge Functions > Secrets du dashboard. Aucun de ces tokens n'est exposé dans l'app cliente (utilisés uniquement côté Edge Function) ; en l'absence de tous, `meal-images` retombe sur l'accès anonyme Pollinations.
5. **IA locale (optionnel)** <a name="ia-locale"></a> — le scan et le chat coach peuvent tourner directement sur l'appareil (Gemma3n via `flutter_gemma`), sans connexion et sans consommer le quota cloud partagé, activable depuis Profil > IA locale dans l'app. Configuration :
   - Crée un compte sur [huggingface.co](https://huggingface.co), demande l'accès au modèle "gated" [google/gemma-3n-E2B-it-litert-lm](https://huggingface.co/google/gemma-3n-E2B-it-litert-lm) (acceptation de licence), puis génère un token d'accès (Settings > Access Tokens).
   - Déploie `huggingface-token` et configure le secret `HUGGINGFACE_TOKEN` avec ce token. Cette fonction est volontairement **sans quota** — elle ne consomme aucune API payante, elle donne juste le token à un utilisateur authentifié pour qu'il télécharge le modèle (~3,66 Go) directement depuis son appareil vers Hugging Face ; le token n'est jamais embarqué dans le binaire de l'app.
   - **Android** : `minSdk` est passé à **30** (Android 11+) dans `android/app/build.gradle.kts` — requis par le moteur d'inférence `.litertlm` (`flutter_gemma_litertlm`). ⚠️ Ceci relève la version Android minimale pour **toute l'app**, pas seulement l'IA locale — vérifie que ça correspond à ton public cible avant de publier.
   - **iOS** : la cible de déploiement est passée à 15.0 dans `project.pbxproj`. Un fichier `ios/Runner/Runner.entitlements` a été créé (mémoire étendue, nécessaire pour l'inférence sur un modèle de plusieurs Go) mais **doit être rattaché manuellement au projet dans Xcode** (Signing & Capabilities) — non fait automatiquement, ni testé, faute de Mac disponible pendant le développement de cette fonctionnalité.
6. **Compte admin (optionnel)** — pour donner à un compte l'accès complet aux fonctionnalités PRO sans abonnement réel, exécute depuis le SQL Editor : `update public.profiles set is_admin = true where email = 'ton-email@exemple.com';`. Ce champ n'est modifiable que depuis le SQL Editor (aucun moyen de le changer depuis l'app, voir migration 0007).

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
- **IA locale (Gemma3n)** : `flutter_gemma_litertlm` ajoute plus de 100 Mo de bibliothèques natives (moteur d'inférence + accélérateurs NPU Qualcomm/GPU), et ne fonctionne pleinement qu'en arm64 — un APK universel (par défaut) les embarque pour rien sur les 3 architectures. Pour tester/sideloader sans ce surpoids x3, utilise `flutter build apk --release --target-platform android-arm64` (un seul arm64, build aussi plus rapide).
- Pour le Play Store, préfère `flutter build appbundle --release` (format `.aab` requis) : Google Play ne livre que l'architecture du téléphone de chaque utilisateur, donc pas de surpoids pour eux même sans `--target-platform`.

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

- **Repas, poids et hydratation hors ligne** — écrits dans une base SQLite locale (`lib/local_db/`) avant toute tentative réseau, puis synchronisés vers Supabase (tables `meals`/`weight_entries`/`hydration_entries`) au prochain démarrage ou retour de connexion, sans action de l'utilisateur. Pour le poids et l'hydratation, la synchronisation est aussi descendante (`syncEntries()` rapatrie les lignes présentes sur Supabase mais absentes en local) : l'historique se restaure après une désinstallation et se partage entre appareils. Le poids actuel du profil (`profiles.current_weight`, mis à jour à chaque pesée) reste la valeur utilisée pour l'IMC et les cibles caloriques, indépendamment de cet historique.
- **Notifications locales, rappels personnalisés sauvegardés** — les rappels (créneaux fixes et personnalisés) sont programmés en local sur l'appareil (`flutter_local_notifications`) et persistés dans `shared_preferences`. Les rappels personnalisés sont en plus sauvegardés dans la table Supabase `custom_reminders_backup` à chaque modification, et restaurés automatiquement (nouvelle installation ou nouvel appareil sans rappel local) — voir `lib/providers/custom_reminders_provider.dart`. Les créneaux fixes petit-déjeuner/déjeuner/dîner suivent désormais la même sauvegarde (table `custom_reminders_backup`, colonne `fixed_reminders`, voir migration 0021 et `lib/providers/notification_settings_provider.dart`). ⚠️ Restauration one-shot dans les deux cas, pas de fusion en cas d'usage simultané sur deux appareils avant leur première synchronisation.
- **Photos de repas** — uploadées dans le bucket `meal_photos` uniquement pour les analyses par photo ("Repas"/"Produit") ; un repas issu d'un scan de code-barres n'a pas de photo.
- **Identité visuelle** — le logo source (`assets/icon/icon.png` / `icon_foreground.png`) alimente à la fois l'icône d'app (générée par `flutter_launcher_icons`, voir `pubspec.yaml`) et, depuis peu, le splash screen (Android/iOS) et l'écran de connexion. L'identifiant d'app est unifié en `com.aihealthchef.app` sur Android/iOS/macOS/Linux (Windows n'a pas d'identifiant de ce type).
- **CGU/mentions légales à finaliser** — le contenu de `lib/screens/terms_screen.dart` décrit honnêtement le fonctionnement actuel de l'app (données collectées, absence de conseil médical, contenu généré par IA, abonnement, âge minimum) et identifie l'éditeur (Baga Assami, projet personnel sans société immatriculée) et son contact (`kSupportEmail`), mais reste un brouillon : le texte doit être relu par un professionnel du droit avant toute publication publique — un bandeau d'avertissement s'affiche sur l'écran tant que ce n'est pas fait.
- **Âge minimum (RGPD art. 8/9)** — l'app est réservée aux personnes de 16 ans ou plus (`kMinimumAge` dans `lib/utils/age_policy.dart`), sans flux de consentement parental : en-dessous, la création de profil est bloquée (onboarding et écran "Mes objectifs"). L'inscription (`signup_screen.dart`) exige en plus une case explicite "J'ai au moins 16 ans et j'accepte les CGU…", dont l'horodatage et la version acceptée sont tracés dans `profiles.accepted_terms_at`/`accepted_terms_version` (migration 0018). Ceci n'empêche pas, par construction, qu'un compte créé avant ce changement ait un âge < 16 ans déjà enregistré ; requête de détection en lecture seule : `supabase/scripts/detect_underage_accounts.sql` (non exécutée automatiquement par l'app, aucun traitement/suppression automatique — décision humaine requise sur les comptes trouvés).
- **Quotas IA** — les limites quotidiennes sont volontairement généreuses pour un usage personnel normal ; ajuste les valeurs passées à `checkAndIncrementQuota(...)` dans chaque `supabase/functions/<nom>/index.ts` si besoin (4ᵉ argument = quota par utilisateur, 5ᵉ argument optionnel = quota global partagé par toute l'app, voir migration 0009). Cette fonction vit dans `supabase/functions/_shared/quota.ts` et est importée par chaque Edge Function IA (voir Architecture ci-dessus) : un changement dans `_shared/quota.ts` s'applique à toutes d'un coup, pas besoin de le reporter manuellement. Un compte admin (`profiles.is_admin`) n'en est **pas** exempté — le quota s'applique à tout le monde, y compris toi.

## Ressources Flutter

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
