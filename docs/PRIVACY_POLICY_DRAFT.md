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
| Photo de profil (avatar) | Supabase Storage, bucket `avatars` (**public**) | Personnalisation du profil | Consentement |
| Photos de repas | Local + Supabase Storage, bucket `meal_photos` (**public**) | Analyse par IA, journal visuel du repas | Consentement (photo) + exécution du contrat (analyse) |
| Photos de progression (poids) | Local + Supabase Storage, bucket `weight_photos` (**public**) | Suivi visuel de la perte/prise de poids — **donnée de santé** | Consentement explicite |
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
2. **Buckets Storage publics** (`avatars`, `meal_photos`, `weight_photos`) : ces buckets sont actuellement **publics en lecture** (URL devinable si l'UUID du fichier est connu/fuite). Les photos de progression corporelle (`weight_photos`) sont une donnée de santé stockée dans un bucket public — recommandation : passer ces buckets en privé avec URL signée, comme déjà fait pour `chat_images` (migration 0019). **Non appliqué ici, à valider avec toi avant tout changement de bucket (risque de casser les URLs déjà stockées en base).**
3. **Suppression de compte** : voir bug identifié à la section 9.

## 4. Durées de conservation

- Compte actif : toutes les données sont conservées tant que le compte existe.
- Compteurs d'usage (`api_usage`, `global_api_usage`) : remis à zéro quotidiennement (colonne `day`), pas de purge automatique des anciennes lignes identifiée dans les migrations lues — **à vérifier/ajouter un job de purge si absent**.
- `delete_account_attempts` : pas de purge automatique identifiée — à vérifier.
- Suppression de compte : déclenche la suppression Supabase Auth (cascade sur toutes les tables liées par clé étrangère) + suppression des dossiers Storage `avatars`, `meal_photos`, `weight_photos` **et `chat_images` — BUG : ce dernier bucket est absent de la liste de nettoyage dans `delete-account/index.ts`, voir section 9** + purge locale complète (`local_data_purge.dart`).

## 5. Tes droits

Conformément au RGPD, tu disposes d'un droit d'accès, de rectification, d'effacement, de limitation, d'opposition et de portabilité de tes données, ainsi que du droit d'introduire une réclamation auprès de la CNIL (cnil.fr).

- **Accès/rectification** : directement dans l'app (écran Profil).
- **Effacement** : écran Profil > Sécurité > Supprimer mon compte (suppression immédiate, limitée à 3 tentatives/heure par anti-abus).
- **Portabilité** : exports CSV/PDF existants (journal des repas, bilans hebdo/mensuels) — **partiels**, voir section 7 pour les limites actuelles et la proposition d'export complet.
- **Contact pour toute demande** : bagaassami009@gmail.com

## 6. Âge minimum

L'application est réservée aux personnes de 16 ans ou plus (`kMinimumAge` dans `lib/utils/age_policy.dart`). Ce seuil correspond à l'âge de consentement numérique par défaut en France/RGPD (Art. 8), choisi pour éviter la collecte de données de santé de mineurs sans consentement parental vérifiable. **Aucune vérification d'âge autre que la déclaration par l'utilisateur n'est en place — point à faire valider par un juriste (suffisance d'une autodéclaration).**

## 7. Export de données — état actuel et proposition

Exports existants (`lib/utils/journal_export.dart`) :
- CSV du journal de repas (90 jours)
- PDF bilan nutritionnel hebdomadaire/mensuel
- Export .ics du plan de repas hebdomadaire

Ces exports sont **partiels** : ils ne couvrent pas l'hydratation, l'historique de chat, le profil complet, les métadonnées de compte, ni les photos. Ils ne constituent donc pas un export complet au sens du droit à la portabilité.

**Proposition (non implémentée, à valider avec toi séparément)** : un export JSON unique regroupant profil, repas, poids, hydratation, chat, plans de repas, horodatages — téléchargeable depuis Profil. Nécessite un arbitrage sur le format des photos (liens signés temporaires vs. non inclus).

## 8. Sécurité

- Mots de passe hashés par Supabase Auth (bcrypt), jamais stockés en clair côté app.
- Row Level Security (RLS) sur les tables Supabase (chaque utilisateur ne voit que ses propres lignes).
- Buckets Storage : `chat_images` privé avec policy RLS par dossier utilisateur ; `avatars`/`meal_photos`/`weight_photos` publics (voir recommandation section 3).
- Edge Functions : authentification par JWT Supabase obligatoire, quotas anti-abus (`_shared/quota.ts`).

## 9. Point signalé — bug de suppression de compte (chat_images)

`supabase/functions/delete-account/index.ts` définit :
```ts
const STORAGE_BUCKETS = ["avatars", "meal_photos", "weight_photos"];
```
Le bucket `chat_images` (ajouté en migration 0019) **n'y figure pas**. Conséquence : quand un utilisateur supprime son compte, ses images de chat restent orphelines dans Storage indéfiniment — non-conformité avec le droit à l'effacement pour cette catégorie de données.

**Correctif proposé (non appliqué, à valider)** :
```ts
const STORAGE_BUCKETS = ["avatars", "meal_photos", "weight_photos", "chat_images"];
```
Mécaniquement trivial (même convention de chemin `{user_id}/...` que les autres buckets), mais c'est un vrai bug de conformité qui doit être corrigé consciemment, pas glissé dans ce brouillon.

## 10. Contact

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

Same minimization recommendations apply (see French section 3): reduce the allergy/diet detail sent to the coach chat prompt; move `avatars`/`meal_photos`/`weight_photos` Storage buckets from public to private+signed URLs like `chat_images` already is. **Not applied — product decisions pending your approval.**

## 4. Retention

Same as French section 4: kept for the lifetime of the account; usage counters reset daily; account deletion cascades through Supabase Auth and wipes local data, but **currently misses the `chat_images` Storage bucket — see section 9 below, a real bug, not fixed here.**

## 5. Your rights

Access, rectification, erasure, restriction, objection, and portability, plus the right to lodge a complaint with your national data protection authority (CNIL in France). Access/rectification: in-app Profile screen. Erasure: Profile > Security > Delete account. Portability: existing partial CSV/PDF exports (see section 7).

## 6. Minimum age

16 years old (`kMinimumAge`), chosen to match the GDPR Art. 8 default digital-consent age and avoid collecting minors' health data without verifiable parental consent. **Self-declared only — no independent age verification; needs legal sign-off on whether self-declaration is sufficient.**

## 7. Data export — current state and proposal

Existing exports are partial (meal journal CSV, weekly/monthly nutrition PDF, weekly meal plan .ics) — missing hydration, chat history, full profile, account metadata, photos. **Proposed** (not implemented, needs your separate approval): a single JSON export covering all user data, downloadable from Profile.

## 8. Security

Password hashing via Supabase Auth, Row Level Security on every table, JWT-gated Edge Functions with anti-abuse quotas, `chat_images` bucket already private+signed (others still public, see section 3).

## 9. Flagged issue — account deletion bug (chat_images)

`supabase/functions/delete-account/index.ts` has `STORAGE_BUCKETS = ["avatars", "meal_photos", "weight_photos"]`, missing `"chat_images"` (added in migration 0019). Deleting an account currently leaves chat images orphaned in Storage forever — a real erasure-right compliance bug. Proposed fix (not applied, needs your approval): add `"chat_images"` to that array.

## 10. Contact

bagaassami009@gmail.com
