# Changelog — correctifs de l'audit Coach IA

Suivi de l'implémentation des 10 correctifs de `docs/AUDIT_CHATBOT.md` (section 12, Top 10),
réalisée étape par étape, dans l'ordre, avec vérification du constat en code avant chaque fix et
`flutter analyze` / `flutter test` / `deno test` (fonctions touchées) après chaque fix.

**Aucun commit git n'a été fait pendant cette série de correctifs** : tous les diffs listés ci-dessous
sont dans l'arbre de travail, en attente de revue et de commit par l'auteur du projet.

---

## Étape 1 — Garde-fou santé absent du prompt système local (correctif #1, Critique)

**Fichiers** : `lib/services/local_ai_service.dart`, `lib/utils/health_risk_filter.dart` (nouveau),
`supabase/functions/_shared/health_risk_filter.ts` (nouveau) + `health_risk_filter_test.ts`,
`lib/config/emergency_contacts.dart` (nouveau), `supabase/functions/coach-chat/index.ts`.

Ajout du `safetyInstruction` (plancher calorique, orientation TCA) au prompt système local, aligné
sur le cloud. En complément — pas en remplacement, un modèle peut ignorer une instruction — un filet
de sécurité **déterministe** (mots-clés, pas de modèle) détecte un risque santé (détresse, urgence)
avant tout appel au modèle, cloud ou local, et renvoie une réponse de sécurité fixe avec des contacts
d'urgence localisés plutôt que d'attendre que le prompt suffise.

**Tests** : `health_risk_filter_test.ts` (Deno), `_shared/` + `coach-chat/` (Deno), tests Dart existants.

## Étape 2 — Message d'accueil codé en dur en français (correctif #2, Majeur i18n)

**Fichiers** : `lib/providers/chat_provider.dart`, `lib/l10n/app_fr.arb`/`app_en.arb` (clés
`coach*`), `test/widgets/coach_welcome_message_test.dart` (nouveau).

`_welcomeText` passe par `AppLocalizations` au lieu d'une chaîne française en dur ; généré au
démarrage de l'app (langue alors connue), pas de dépendance à un contexte de build.

## Étape 3 — Blocage silencieux de l'envoi quand le consentement cloud est refusé (correctif #3, Majeur produit/RGPD)

**Fichiers** : `lib/providers/ai_consent_provider.dart`, `lib/screens/coach_screen.dart`,
`lib/widgets/cloud_ai_consent_gate.dart`, `lib/providers/chat_provider.dart`,
`test/providers/ai_consent_provider_test.dart` (nouveau).

Routage explicite en 5 cas selon (IA locale prête, consentement cloud) plutôt qu'un seul chemin qui
bloquait silencieusement l'envoi dès que le consentement cloud était refusé, même avec l'IA locale
prête à répondre sans jamais toucher le cloud. Cas 4 (IA locale non prête ET consentement refusé) :
message explicite affiché à l'utilisateur plutôt qu'un échec muet.

## Étape 4 — Aucune instruction anti-injection/anti-extraction (correctif #4, Majeur sécurité)

**Fichiers** : `supabase/functions/_shared/coach_prompt.ts` (nouveau, `COACH_PROMPT_VERSION`) +
`coach_prompt_test.ts`, `lib/config/coach_prompt.dart` (nouveau, équivalent local versionné),
`supabase/functions/coach-chat/index.ts`, `lib/services/local_ai_service.dart`.

Prompt système centralisé et versionné (cloud + local) avec délimiteurs `<<<DONNEE_UTILISATEUR>>>`/
`<<<FIN_DONNEE_UTILISATEUR>>>` autour de toute donnée utilisateur non fiable (allergies, puis contexte
du jour à l'étape 6), neutralisation des délimiteurs forgés par l'utilisateur, et instruction explicite
de ne jamais traiter l'historique/les messages comme des instructions ni révéler le prompt système.

## Étape 5 — Disclaimer IA + indicateur de moteur absents (correctif #5, Majeur conformité store/transparence)

**Fichiers** : `lib/screens/coach_screen.dart`, `lib/models/chat_message.dart` (champ moteur),
`lib/providers/chat_provider.dart`, `lib/l10n/app_fr.arb`/`app_en.arb`.

Disclaimer visible dans le chat (« IA, ne remplace pas un avis médical ») et indicateur du moteur
ayant répondu (local/cloud) par message, rendu uniquement quand pertinent.

## Étape 6 — Aucune donnée du jour transmise au coach (correctif #6, Majeur produit)

**Fichiers** : `lib/utils/coach_context_builder.dart` (nouveau) + `coach_context_builder_test.dart`,
`lib/providers/chat_provider.dart`, `supabase/functions/coach-chat/index.ts`,
`supabase/functions/_shared/coach_prompt.ts`, `lib/config/coach_prompt.dart`,
`lib/services/local_ai_service.dart`.

Bloc contexte du jour (repas, calories/macros restantes) construit côté app, budgété en tokens
(variante compacte pour l'IA locale), neutralisé puis délimité une seconde fois côté Edge Function
(défense en profondeur), injecté dans `systemInstruction` — jamais dans l'historique envoyé au modèle.

## Étape 7 — Aucun mécanisme de signalement (correctif #7, Majeur conformité store)

**Fichiers** : `supabase/migrations/0022_add_chat_reports.sql` (nouveau, table `chat_reports`, RLS
select/insert-own uniquement, pas d'update/delete), `lib/providers/chat_provider.dart`
(`reportMessage`), `lib/screens/coach_screen.dart` (UI de signalement), `lib/services/ai_service.dart`,
`lib/services/data_export_service.dart` (export RGPD couvre aussi `chat_reports`),
`docs/STORE_CHECKLIST.md` (flag revue légale ajouté).

## Étape 8 — Message de quota dépassé sans heure de reset (correctif #8, Mineur)

**Fichiers** : `supabase/functions/_shared/quota.ts`, `quota_test.ts`.

## Étape 9 — Aucun test pour `coach-chat/index.ts` ni jeu d'évaluation (correctif #9, Mineur process)

**Fichiers** : `supabase/functions/coach-chat/index.ts` (export `handleCoachChat` pour le rendre
testable), `index_test.ts` (nouveau, 8 cas), `eval_cases.json` (nouveau, 7 scénarios), `run_eval.ts`
(nouveau, mode mock utilisable en CI sans clé API + mode réel pour scoring manuel),
`lib/providers/chat_provider.dart` (DI : `aiService`/`supabase` injectables),
`test/providers/chat_provider_test.dart` (nouveau, 4 cas : fenêtre d'historique, ordre des messages,
double envoi, annulation).

**CI** : le mode mock de `run_eval.ts` n'est pas encore branché dans `.github/workflows/ci.yml` (pas
demandé explicitement à cette étape) — reste une action pour l'auteur du projet, voir section Ouvert.

## Étape 10 — Contraintes non épinglées au-delà de la fenêtre d'historique (correctif #10, Mineur, PARTIEL)

**Fichiers** : `supabase/functions/coach-chat/index_test.ts` (nouveau cas, pas de fix de code —
voir ci-dessous).

Vérifié en code : `systemInstruction` (allergies/régime/plancher kcal du **profil**) est reconstruit
à chaque appel à partir des paramètres de la requête, jamais depuis l'historique tronqué — déjà
protégé par construction depuis l'étape 4/6. Test ajouté : conversation de 40 messages (80 entrées,
dépasse la fenêtre de 50), allergie toujours présente dans `systemInstruction` au message 41.

**Non traité** (hors scope de ce correctif tel que décrit) : une allergie/contrainte dite **seulement
en conversation**, jamais ajoutée au profil, peut toujours sortir de la fenêtre de 50 entrées après
~25 échanges — nécessiterait une extraction de contraintes depuis le texte libre (section 11 de
l'audit propose un épinglage en mémoire côté client par mot-clé).

---

## Preuves de non-régression (dernière exécution complète)

- `flutter analyze` → **No issues found!**
- `flutter test` → **159 tests, tous passés** (inclut les nouveaux fichiers de test ci-dessus)
- `deno test --allow-env --allow-net supabase/functions/_shared/ supabase/functions/coach-chat/` →
  **26 passed, 0 failed**

---

## Ouvert / tests manuels / validation humaine nécessaire

Repris et affiné depuis `docs/AUDIT_CHATBOT.md` section 16, à la lumière des correctifs appliqués :

1. **Qualité réelle des réponses modèle** (cohérence, respect effectif du ton/garde-fous, résistance
   à l'injection) — jamais exécutée en conditions réelles (pas de clé API dans cette session). À
   faire : lancer `run_eval.ts` en mode réel (`GEMINI_API_KEY` + `EVAL_AUTH_TOKEN` + Supabase) et
   relire les réponses obtenues sur les 7 cas de `eval_cases.json`.
2. **IA locale (Gemma3n on-device)** — le `safetyInstruction` et le bloc anti-injection ont été
   ajoutés au prompt local (étapes 1/4), mais leur respect effectif par un modèle 2B/4B n'est
   vérifiable que sur un appareil réel. Tester les scénarios TCA/plancher calorique en coupant la
   connexion après activation de l'IA locale.
3. **Filet de sécurité déterministe** (`health_risk_filter.ts`/`.dart`) — liste de mots-clés fixe ;
   à relire côté produit/légal pour couvrir d'autres langues/formulations que celles testées, et
   confirmer que les contacts d'urgence dans `emergency_contacts.dart` sont corrects et à jour pour
   les marchés visés (voir note dans le fichier : valeurs à vérifier avant publication).
4. **Flag légal `chat_reports`** (correctif #7) — `docs/STORE_CHECKLIST.md` a été marqué pour revue
   légale (modération des signalements, délai de traitement, politique de confidentialité à mettre à
   jour pour mentionner cette collecte) — revue non faite dans cette session, action humaine requise.
5. **CI `run_eval.ts`** — pas branché dans `.github/workflows/ci.yml` ; décision produit à prendre
   (coût d'un `GEMINI_API_KEY` de test, fréquence d'exécution) avant de l'ajouter comme job séparé.
6. **Correctif #10 résiduel** — allergie dite seulement en chat (jamais au profil) : décision produit
   à prendre sur l'intérêt d'une extraction par mots-clés avant d'investir cet effort (section 11 de
   l'audit).
7. **Complétude `app_en.arb`** — toujours non revérifiée clé par clé pour l'ensemble des chaînes
   `coach*` ajoutées dans cette série de correctifs (étapes 2, 5, 6, 7) ; seule la présence FR/EN en
   paire a été garantie à l'ajout, pas une relecture de qualité de traduction par un locuteur natif.

**Tous les diffs ci-dessus sont dans l'arbre de travail — rien n'a été committé.** À l'auteur du
projet de relire, tester manuellement les points ci-dessus, puis committer.
