# Checklist de publication (Play Store / App Store)

Brouillon technique, à cocher/compléter avant soumission. Pas une garantie de conformité — voir la liste "relecture juridique" en fin de document.

## Compte et conformité RGPD

- [ ] `docs/PRIVACY_POLICY_DRAFT.md` relu, validé (juridiquement si besoin), hébergé sur une **URL publique** (site web, GitHub Pages, ou page dédiée) — Play et Apple exigent un lien web, pas juste un écran in-app.
- [ ] `lib/screens/privacy_screen.dart` lié depuis Profil, Aide, et l'écran d'inscription (fait dans cette tâche, voir code).
- [ ] Suppression de compte : in-app **et** via une URL web (exigence Play Console depuis 2023 pour toute app proposant un compte supprimable) — actuellement seulement in-app (`/delete_account`), **URL web à créer**.
- [ ] Corriger le bug `chat_images` manquant dans `delete-account/index.ts` (voir `docs/PRIVACY_POLICY_DRAFT.md` section 9) avant publication, pour que la suppression soit réellement complète.
- [ ] Âge minimum (16 ans) déclaré cohérent avec la classification de contenu du store (PEGI/rating).

## Permissions déclarées

- [ ] Caméra (`camera`, `image_picker`) — scan repas/produit/menu/frigo.
- [ ] Notifications locales (`flutter_local_notifications`) — rappels de repas/hydratation.
- [ ] Alarmes exactes (Android, si `flutter_local_notifications` les utilise pour les rappels programmés) — vérifier `android/app/src/main/AndroidManifest.xml` pour `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, et justifier dans Play Console (Android 14+ demande une déclaration explicite).
- [ ] Vérifier qu'aucune permission inutilisée ne traîne dans le manifest (ex. localisation, contacts) — pas identifiée dans le code lu, à confirmer par un `grep` sur `AndroidManifest.xml`.

## Catégorie et avertissement santé

- [ ] Catégorie app : "Santé et fitness" ou "Nutrition" selon les options du store.
- [ ] Disclaimer explicite "ne remplace pas un avis médical / n'est pas un dispositif médical" — déjà présent dans les CGU (`terms_screen.dart`), vérifier qu'il apparaît aussi dans la fiche store (description publique).
- [ ] Vérifier la cohérence avec le garde-fou déjà codé dans `coach-chat/index.ts` (refus de recommander <1200/1500 kcal, redirection vers un professionnel en cas de signal de trouble alimentaire).

## Abonnement (RevenueCat)

- [ ] Règles du store respectées : achat intégré natif obligatoire (pas de lien de paiement externe pour du contenu numérique), ce qui est déjà le cas (`purchases_flutter`).
- [ ] CGU mentionnent le renouvellement automatique et la gestion via les réglages du store — à vérifier dans `terms_screen.dart` section abonnement.
- [ ] Mode démo RevenueCat : confirmer qu'il est désactivé en build release (voir tâche séparée sur l'entitlement serveur, actuellement en attente).

## Signing / build

- [ ] `applicationId` Android figé (vérifier `android/app/build.gradle` — pas de `com.example.*`).
- [ ] `minSdkVersion` Android ≥ 30 si c'est la cible choisie (à vérifier dans `android/app/build.gradle` — Play exige a minima l'API level le plus récent selon la politique en vigueur à la date de soumission, vérifier le seuil courant).
- [ ] Taille de l'AAB dans les limites Play (actuellement 150 Mo via Play Asset Delivery, ou taille de base sans assets volumineux — `flutter_gemma`/modèle Gemma3n étant téléchargé à la demande et non embarqué, ça aide).
- [ ] Signature de release configurée (`key.properties`, keystore) — pas vérifié dans cette tâche, à confirmer séparément.
- [ ] Test en interne/fermé sur Play Console avant la mise en production (`Closed testing` track) — recommandé avant toute release publique, surtout avec des données de santé.

## Store listing

- [ ] Icône, captures d'écran, description cohérentes avec le contenu réel de l'app.
- [ ] Lien vers la politique de confidentialité (URL publique, voir ci-dessus) dans la fiche Play Console et dans App Store Connect.
- [ ] Mentions des licences tierces (Open Food Facts/ODbL, Gemma, FLUX.1, Pollinations) — voir `lib/screens/licenses_screen.dart` ajouté dans cette tâche ; vérifier si le store demande une mention publique en plus de l'écran in-app (généralement non obligatoire mais recommandé pour ODbL).

## iOS (si publication Apple prévue)

- [ ] `Info.plist` : descriptions d'usage caméra/photos (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`) présentes et honnêtes.
- [ ] App Tracking Transparency : probablement non applicable (pas de tracking publicitaire identifié dans le code), à confirmer.
- [ ] Test sur un Mac (obligatoire pour build/signature iOS) — non fait dans cette tâche, environnement Windows.

## À faire relire par un juriste avant toute mise en ligne publique

1. `lib/screens/terms_screen.dart` (CGU complètes) et `lib/screens/privacy_screen.dart` / `docs/PRIVACY_POLICY_DRAFT.md` (politique de confidentialité).
2. Mentions légales (identité de l'éditeur — actuellement "développeur individuel, pas de société immatriculée", à formaliser si l'activité devient commerciale).
3. Suffisance de l'autodéclaration d'âge (16 ans) sans vérification indépendante, au regard de l'Art. 8 RGPD et des données de santé traitées.
4. Transferts de données hors UE vers Google (Gemini), Cloudflare, Pollinations.ai, RevenueCat, Hugging Face, et Supabase selon la région réelle du projet — clauses contractuelles types (SCC), analyse d'impact (AIPD/DPIA) à envisager pour le traitement de données de santé à cette échelle.
5. Statut "donnée de santé" (Art. 9 RGPD) du profil/allergies/poids/photos de progression, et base légale retenue (consentement explicite vs autre base) — confirmation juridique de l'adéquation du mécanisme de consentement in-app ajouté dans cette tâche.
6. Garde-fous du coach IA (refus des régimes extrêmes, redirection en cas de trouble alimentaire) : suffisance au regard d'une éventuelle qualification de "dispositif médical" ou de conseil de santé réglementé.
