# Politique de confidentialité — BROUILLON (FR)

> **AVERTISSEMENT** : ce document est un brouillon technique rédigé à partir d'une lecture du code source de l'application (pas du README). Il décrit factuellement ce que l'app fait. **Il n'a PAS été relu ni validé par un juriste** et ne constitue pas un document juridiquement opposable en l'état. Voir `docs/STORE_CHECKLIST.md` et la section finale pour la liste des points nécessitant une relecture par un avocat avant toute mise en ligne publique.

Dernière mise à jour de ce brouillon : 2026-10-03.

## 1. Responsable du traitement

Éditeur de l'application AI Health Chef : Baga Assami, développeur individuel (pas de société immatriculée à ce jour, à confirmer/mettre à jour avant publication).
Contact : bagaassami009@gmail.com

## 2. Données collectées

| Donnée | Où elle est stockée | Finalité | Base légale probable |
|---|---|---|---|
| Email, mot de passe (hashé par Supabase Auth) | Supabase Auth | Authentification, accès au compte | Exécution du contrat (Art. 6.1.b RGPD) |
| Profil : nom, sexe, âge, poids actuel/cible, taille, objectif, régime, allergies, préférence culinaire, ton du coach | Local (drift/SQLite) + Supabase (`profiles`) | Calcul des besoins nutritionnels, personnalisation des suggestions/coach | Exécution du contrat ; allergies/régime = **donnée de santé (Art. 9 RGPD)**, base légale = consentement explicite |
| Photo de profil (avatar) | Supabase Storage, bucket `avatars` (**privé**, accès par URL signée temporaire) | Personnalisation du profil | Consentement |
| Photos de repas | Local + Supabase Storage, bucket `meal_photos` (**privé**, accès par URL signée temporaire) | Analyse par IA, journal visuel du repas | Consentement (photo) + exécution du contrat (analyse) |
| Photos de progression (poids) | Local + Supabase Storage, bucket `weight_photos` (**privé**, accès par URL signée temporaire) | Suivi visuel de la perte/prise de poids — **donnée de santé** | Consentement explicite |
| Photos de menu / frigo-placard (scan) | Transmises à l'IA cloud, pas stockées de façon pérenne côté app (sauf cache temporaire local) | Reconnaissance de plats / ingrédients | Consentement |
| Historique de chat avec le coach IA | Supabase (`chat_messages`), images du chat dans Storage bucket `chat_images` (**privé**, accès signé) | Fonctionnalité de coaching conversationnel | Exécution du contrat |
| Entrées de poids et d'hydratation | Local + Supabase (`weight_entries`, `hydration_entries`) | Suivi de progression — **donnée de santé** pour le poids | Consentement explicite |
| Identifiants techniques (user ID Supabase, jeton de session) | Supabase Auth, mémoire locale de l'app | Authentification, synchronisation | Exécution du contrat |
| Statut d'abonnement (PRO/gratuit) | RevenueCat (identifié par le user ID Supabase comme `appUserID`), cache local | Gestion de l'abonnement payant | Exécution du contrat |
| Plans de repas hebdomadaires générés, suggestions de repas (cache) | Supabase (`weekly_meal_plans`, `meal_suggestions`) | Éviter de régénérer inutilement (coûts IA) | Intérêt légitime |
| Compteurs d'usage quotidien des fonctions IA | Supabase (`api_usage`, `global_api_usage`) — **pas de contenu, juste un compteur** | Anti-abus / quota | Intérêt légitime |
| Tentatives de suppression de compte (horodatage) | Supabase (`delete_account_attempts`) | Anti-abus (limite de 3/heure) | Intérêt légitime |
| Acceptation des CGU (version + date) | Supabase (`profiles.accepted_terms_version/at`) | Preuve de consentement | Obligation légale / intérêt légitime |

Donnée **non** collectée à ce jour (à vérifier avant publication si ça change) : aucune géolocalisation, aucun identifiant publicitaire, aucun carnet de contacts, aucune donnée de paiement en clair (gérée nativement par le store via RevenueCat/Apple/Google — l'app ne voit jamais le numéro de carte).

## 3. Destinataires des données (sous-traitants / tiers)

| Tiers | Donnée transmise | Rôle | Transfert hors UE | Risque identifié |
|---|---|---|---|---|
| **Supabase Inc.** | Toutes les données ci-dessus (base de données, Auth, Storage, Edge Functions) | Hébergement backend | Oui, selon la région du projet Supabase (à vérifier dans le dashboard — US par défaut sauf région EU choisie) | Vérifier la région du projet et les clauses contractuelles types (SCC) de Supabase |
| **Google (Gemini API)** | Photo de repas/produit/menu/frigo (base64) + prompt texte ; message de chat + historique + ton du coach + régime + allergies | Analyse d'image et chat coach par IA | Oui (serveurs Google, le plus souvent hors UE) | Allergies/régime = donnée de santé envoyée à un tiers US — **point sensible**, minimiser si possible (ex. n'envoyer que la liste d'allergies sans autre contexte) |
| **Cloudflare (Workers AI, modèle FLUX.1 schnell)** | Titre + description textuelle d'une suggestion de repas (pas de photo, pas de donnée perso directe) | Génération d'illustration de plat | Oui (réseau Cloudflare global) | Faible — pas de donnée personnelle identifiable dans le texte envoyé |
| **Pollinations.ai** | Idem Cloudflare (fallback si quota Cloudflare dépassé) | Génération d'illustration de plat | Oui | Faible, mais service tiers moins documenté juridiquement — à surveiller |
| **RevenueCat** | User ID Supabase (`appUserID`), événements d'achat | Gestion des abonnements | Oui (US) | Standard pour ce type de service, CGU RevenueCat à référencer |
| **Open Food Facts** | Code-barres scanné, terme de recherche | Lookup produit alimentaire | Appel anonyme, pas de compte, pas de donnée perso envoyée | Aucun — pas d'auth, pas d'identifiant utilisateur transmis |
| **Hugging Face** | Rien côté utilisateur : le téléphone télécharge directement le modèle Gemma3n depuis Hugging Face avec un jeton serveur partagé | Téléchargement du modèle d'IA locale | Oui (US) | Le jeton est partagé entre tous les utilisateurs (voir `supabase/functions/huggingface-token`) — pas une fuite de donnée perso, mais noter la limite |
| **Apple / Google (stores)** | Paiement d'abonnement, infos de facturation | Traitement du paiement natif | Géré entièrement par le store, l'app ne voit jamais les données bancaires | Aucun côté app |

### Recommandations de réduction/anonymisation (techniques, à valider)

1. **Chat coach → Gemini** : `allergies` et `dietType` sont injectés tels quels dans le prompt système envoyé à Gemini à chaque message (voir `coach-chat/index.ts`). Minimisation possible : n'envoyer qu'un résumé catégoriel (ex. "a des restrictions alimentaires") plutôt que la liste brute, si l'utilisateur n'a pas explicitement consenti à l'envoi détaillé. **Décision produit à prendre, pas appliquée ici.**
2. **Buckets Storage publics** (`avatars`, `meal_photos`, `weight_photos`) : **appliqué** (migration `0020_private_photo_buckets.sql`) — ces buckets sont désormais privés, avec policies RLS par dossier utilisateur identiques à `chat_images` (migration 0019), et accès exclusivement via URL signée temporaire (voir section 10).
3. **Suppression de compte** : voir point résolu à la section 9.

## 4. Durées de conservation

- Compte actif : toutes les données sont conservées tant que le compte existe.
- Compteurs d'usage (`api_usage`, `global_api_usage`) : remis à zéro quotidiennement (colonne `day`), pas de purge automatique des anciennes lignes identifiée dans les migrations lues — **à vérifier/ajouter un job de purge si absent**.
- `delete_account_attempts` : pas de purge automatique identifiée — à vérifier.
- Suppression de compte : déclenche la suppression Supabase Auth (cascade sur toutes les tables liées par clé étrangère) + suppression des dossiers Storage `avatars`, `meal_photos`, `weight_photos` et `chat_images` (voir section 9 — bug historique corrigé) + purge locale complète (`local_data_purge.dart`).

## 5. Tes droits

Conformément au RGPD, tu disposes d'un droit d'accès, de rectification, d'effacement, de limitation, d'opposition et de portabilité de tes données, ainsi que du droit d'introduire une réclamation auprès de la CNIL (cnil.fr).

- **Accès/rectification** : directement dans l'app (écran Profil).
- **Effacement** : écran Profil > Sécurité > Supprimer mon compte (suppression immédiate, limitée à 3 tentatives/heure par anti-abus).
- **Portabilité** : export JSON complet (profil, repas, poids, hydratation, chat, plans de repas, préférences, photos) depuis Profil > Sécurité > « Exporter toutes mes données », en plus des exports CSV/PDF existants (journal des repas, bilans hebdo/mensuels) — voir section 7.
- **Contact pour toute demande** : bagaassami009@gmail.com

## 6. Âge minimum

L'application est réservée aux personnes de 16 ans ou plus (`kMinimumAge` dans `lib/utils/age_policy.dart`). Ce seuil correspond à l'âge de consentement numérique par défaut en France/RGPD (Art. 8), choisi pour éviter la collecte de données de santé de mineurs sans consentement parental vérifiable. **Aucune vérification d'âge autre que la déclaration par l'utilisateur n'est en place — point à faire valider par un juriste (suffisance d'une autodéclaration).**

## 7. Export de données — couvert

Exports partiels existants (`lib/utils/journal_export.dart`) :
- CSV du journal de repas (90 jours)
- PDF bilan nutritionnel hebdomadaire/mensuel
- Export .ics du plan de repas hebdomadaire

**Export complet** (droit d'accès/portabilité, Art. 15/20 RGPD) : bouton « Exporter toutes mes données » dans Profil > Sécurité, qui génère un fichier JSON unique (`DataExportService`, voir section 11) regroupant profil, repas (avec ingrédients), poids, hydratation, historique du chat, plans de repas hebdomadaires, liste de courses, rappels personnalisés, consentements, et métadonnées/liens signés temporaires des photos. Partagé via le sélecteur natif (`share_plus`). Aucun secret ni token, et aucune donnée d'un autre utilisateur.

## 8. Sécurité

- Mots de passe hashés par Supabase Auth (bcrypt), jamais stockés en clair côté app.
- Row Level Security (RLS) sur les tables Supabase (chaque utilisateur ne voit que ses propres lignes).
- Buckets Storage : `avatars`, `meal_photos`, `weight_photos` et `chat_images` tous privés, avec policy RLS par dossier utilisateur et accès par URL signée temporaire (voir section 10).
- Edge Functions : authentification par JWT Supabase obligatoire, quotas anti-abus (`_shared/quota.ts`).

## 9. Point résolu — bug de suppression de compte (chat_images)

`supabase/functions/delete-account/storage_buckets.ts` liste désormais :
```ts
export const STORAGE_BUCKETS = ["avatars", "meal_photos", "weight_photos", "chat_images"];
```
Le bucket `chat_images` (ajouté en migration 0019) manquait à l'appel : les images de chat d'un compte supprimé restaient orphelines dans Storage indéfiniment. Corrigé.

Pour empêcher qu'un futur bucket soit oublié de la même façon, `supabase/functions/delete-account/storage_buckets_test.ts` scanne `supabase/migrations/*.sql` et échoue si un bucket créé par `insert into storage.buckets` est absent de `STORAGE_BUCKETS` ; ce test tourne en CI (`.github/workflows/ci.yml`, job `deno`).

La pagination (listage par pages de 1000 objets, relancée tant qu'une page est pleine) et le périmètre par utilisateur (dossier `{user_id}/...`, `user_id` dérivé exclusivement du JWT vérifié, jamais du corps de la requête) étaient déjà corrects — vérifiés par relecture de code, aucun changement nécessaire sur ces deux points.

## 10. Point résolu — buckets photos (avatars / meal_photos / weight_photos) passés en privé

Les buckets `avatars`, `meal_photos` et `weight_photos` étaient en lecture publique : une URL devinable (ou simplement fuitée) suffisait à accéder à une photo de profil, de repas ou de progression corporelle sans aucune authentification — point sensible pour `weight_photos`, qui contient une donnée de santé au sens de l'Art. 9 RGPD.

Migration `0020_private_photo_buckets.sql` : les 3 buckets sont passés en privé, avec policies RLS par dossier utilisateur (`(storage.foldername(name))[1] = auth.uid()::text`), identiques au modèle déjà en place pour `chat_images` depuis la migration 0019. L'app ajoute désormais `avatar_path`/`image_path` (chemin dans le bucket) à côté des anciennes colonnes `*_url` (conservées pour les lignes déjà synchronisées, non supprimées), et affiche les photos via une URL signée temporaire (1h, renouvelée côté app avant expiration) plutôt qu'une URL publique permanente.

Projet pas encore publié au moment de ce changement : pas de rétrocompatibilité ni de migration en deux temps jugées nécessaires — voir l'en-tête de la migration pour l'ordre d'application exact.

## 11. Point résolu — export complet des données (droit d'accès/portabilité)

Jusqu'ici, aucun export ne couvrait l'ensemble des données personnelles (voir ancienne section 7) — un manque au regard du droit de portabilité (Art. 20 RGPD).

`lib/services/data_export_service.dart` génère maintenant un JSON unique à la demande (bouton dans Profil > Sécurité) : profil (depuis Supabase, avec repli sur le cache local hors ligne), repas (fusion local + distant pour couvrir les repas créés sur un autre appareil), poids et hydratation (locaux, déjà synchronisés au démarrage de l'app), historique du chat et plans de repas hebdomadaires (depuis Supabase, paginés), liste de courses et rappels personnalisés (préférences locales), consentements (IA cloud, CGU), et le reste des préférences locales non sensibles. Les photos sont incluses par leurs métadonnées et une URL signée temporaire (1h) plutôt qu'une archive ZIP : l'app affiche déjà les photos via ce même mécanisme (`StorageImageService`), ce qui évite de dupliquer la logique de téléchargement/compression d'images uniquement pour l'export, au prix d'une URL qui expire si elle n'est pas consultée rapidement.

Jamais inclus : mots de passe, jetons de session, ou données d'un autre utilisateur (chaque requête est filtrée par l'id de l'utilisateur authentifié). Couvert par `test/services/data_export_service_test.dart`.

## 12. Contact

bagaassami009@gmail.com

---

# Privacy Policy — DRAFT (EN)

> **DISCLAIMER**: this is a technical draft produced by reading the actual source code (not the README). It factually describes what the app does. **It has NOT been reviewed by a lawyer** and is not a legally binding document as-is. See `docs/STORE_CHECKLIST.md` and the final section for what needs legal review before any public release.

Last updated: 2026-10-03.

## 1. Data controller

AI Health Chef is published by Baga Assami, an individual developer (no registered company as of this draft — confirm/update before publishing).
Contact: bagaassami009@gmail.com

## 2. Data collected

See the French table in section 2 above — identical content: account email/password, health profile (weight, height, age, goal, diet, allergies — special category health data under GDPR Art. 9), avatar/meal/progress/menu/pantry photos, coach chat history, weight/hydration entries, technical identifiers, subscription status, cached suggestions/plans, anti-abuse usage counters, deletion attempt timestamps, terms-acceptance record.

## 3. Recipients / processors

Same third parties as listed in the French section 3: **Supabase** (backend hosting, all data), **Google Gemini** (meal/product/menu/pantry photos + chat text + diet/allergies for the coach), **Cloudflare Workers AI** and **Pollinations.ai** (meal title/description text only, for illustration generation), **RevenueCat** (subscription management, Supabase user ID), **Open Food Facts** (anonymous barcode/search lookup, no personal data sent), **Hugging Face** (on-device model download via a shared server token), **Apple/Google** (native in-app payment, handled entirely by the store).

Same minimization recommendations apply (see French section 3): reduce the allergy/diet detail sent to the coach chat prompt (**not applied — product decision pending your approval**); move `avatars`/`meal_photos`/`weight_photos` Storage buckets from public to private+signed URLs like `chat_images` already is (**applied**, migration `0020_private_photo_buckets.sql` — resolved, see section 10).

## 4. Retention

Same as French section 4: kept for the lifetime of the account; usage counters reset daily; account deletion cascades through Supabase Auth and wipes local data, including the `avatars`, `meal_photos`, `weight_photos`, and `chat_images` Storage folders (see section 9 — a historical bug, now fixed).

## 5. Your rights

Access, rectification, erasure, restriction, objection, and portability, plus the right to lodge a complaint with your national data protection authority (CNIL in France). Access/rectification: in-app Profile screen. Erasure: Profile > Security > Delete account. Portability: full JSON export via Profile > Security > "Export all my data", in addition to the existing partial CSV/PDF exports (see section 7).

## 6. Minimum age

16 years old (`kMinimumAge`), chosen to match the GDPR Art. 8 default digital-consent age and avoid collecting minors' health data without verifiable parental consent. **Self-declared only — no independent age verification; needs legal sign-off on whether self-declaration is sufficient.**

## 7. Data export — covered

Existing partial exports (`lib/utils/journal_export.dart`): meal journal CSV, weekly/monthly nutrition PDF, weekly meal plan .ics.

**Full export** (right of access/portability, GDPR Art. 15/20): an "Export all my data" button in Profile > Security generates a single JSON file (`DataExportService`, see section 11) covering the profile, meals (with ingredients), weight, hydration, chat history, weekly meal plans, shopping list, custom reminders, consents, and photo metadata with temporary signed URLs. Shared via the native share sheet (`share_plus`). No secrets or tokens, and no other user's data.

## 8. Security

Password hashing via Supabase Auth, Row Level Security on every table, JWT-gated Edge Functions with anti-abuse quotas, and all four Storage buckets (`avatars`, `meal_photos`, `weight_photos`, `chat_images`) private with per-user-folder RLS and temporary signed URLs (see section 10).

## 9. Resolved — account deletion bug (chat_images)

`supabase/functions/delete-account/storage_buckets.ts` now exports `STORAGE_BUCKETS = ["avatars", "meal_photos", "weight_photos", "chat_images"]`. The `chat_images` bucket (added in migration 0019) was missing, leaving a deleted account's chat images orphaned in Storage forever. Fixed, and a Deno test (`storage_buckets_test.ts`, run in CI) now fails if any future bucket created in `supabase/migrations/` is missing from this array. Pagination (1000-object pages) and per-user folder scoping (`{user_id}/...`, derived only from the verified JWT) were already correct on review, no change needed there.

## 10. Resolved — photo buckets (avatars / meal_photos / weight_photos) made private

The `avatars`, `meal_photos`, and `weight_photos` buckets were publicly readable: a guessable (or leaked) URL was enough to access a profile, meal, or body-progress photo without any authentication — a sensitive point for `weight_photos`, which holds health data under GDPR Art. 9.

Migration `0020_private_photo_buckets.sql` made all 3 buckets private, with per-user-folder RLS policies (`(storage.foldername(name))[1] = auth.uid()::text`), identical to the model already in place for `chat_images` since migration 0019. The app now stores an `avatar_path`/`image_path` (path within the bucket) alongside the old `*_url` columns (kept for already-synced rows, not dropped), and displays photos via a temporary signed URL (1h, renewed client-side before expiry) instead of a permanent public URL.

The product was not yet published when this change was made: no backward compatibility or two-phase migration was deemed necessary — see the migration file header for the exact application order.

## 11. Resolved — full data export (right of access/portability)

No export used to cover all personal data (see former section 7) — a gap with respect to the right to data portability (GDPR Art. 20).

`lib/services/data_export_service.dart` now generates a single JSON file on demand (button in Profile > Security): profile (from Supabase, falling back to the local cache offline), meals (local+remote merge to cover meals created on another device), weight and hydration (local only, already synced on app start), chat history and weekly meal plans (from Supabase, paginated), shopping list and custom reminders (local preferences), consents (cloud AI, terms of service), and the rest of the non-sensitive local preferences. Photos are included as metadata plus a temporary (1h) signed URL rather than a ZIP archive: the app already displays photos through this same mechanism (`StorageImageService`), avoiding a duplicate image download/compression pipeline just for export, at the cost of a URL that expires if not opened promptly.

Never included: passwords, session tokens, or another user's data (every query is scoped to the authenticated user's id). Covered by `test/services/data_export_service_test.dart`.

## 12. Contact

bagaassami009@gmail.com
