# Google Play — formulaire "Data safety" (brouillon de réponses)

> Brouillon technique basé sur une lecture du code. À faire valider par toi avant de le saisir dans Play Console (Politique de confidentialité d'app > Sécurité des données). Les catégories/libellés ci-dessous suivent la terminologie Play Console actuelle (2026) ; vérifie qu'ils n'ont pas changé au moment de remplir le formulaire.

## Does your app collect or share any of the required user data types?
**Yes.**

## Data types collected

| Catégorie Play | Type précis | Collecté ? | Partagé avec un tiers ? | Finalité déclarée | Optionnel ? |
|---|---|---|---|---|---|
| Personal info | Email address | Oui | Non (sauf Supabase comme sous-traitant d'hébergement) | Account management, App functionality | Non (requis à l'inscription) |
| Personal info | Name | Oui | Non | App functionality (personnalisation) | Oui |
| Photos | Photos | Oui | Oui — Google Gemini (analyse), Cloudflare/Pollinations (génération d'illustration, texte seul) | App functionality (analyse de repas/produit/menu/frigo) | Oui (scan optionnel) |
| Health and fitness | Health info (poids, taille, allergies, régime) | Oui | Oui — Google Gemini (régime/allergies dans le chat coach) | App functionality, Personalization | Oui (profil) |
| Health and fitness | Fitness info (objectif, suivi de poids/hydratation) | Oui | Non (hors Gemini pour le contexte du coach) | App functionality | Oui |
| Messages | In-app messages | Oui (historique chat coach) | Oui — Google Gemini (contenu des messages) | App functionality | Oui (usage du coach) |
| App activity | App interactions | Oui (compteurs d'usage IA) | Non | Analytics (anti-abus/quota), App functionality | Non (technique) |
| Financial info | Purchase history | Oui (statut abonnement) | Oui — RevenueCat | App functionality (gestion abonnement) | Non (si abonnement) |
| Device or other IDs | User ID (Supabase) | Oui | Oui — RevenueCat (`appUserID`) | App functionality | Non |

## Is all of the user data collected by your app encrypted in transit?
**Yes** (HTTPS/TLS vers Supabase et toutes les Edge Functions ; vérifie que Cloudflare/Pollinations/Hugging Face sont aussi appelés en HTTPS — à confirmer, probable par défaut).

## Do you provide a way for users to request that their data be deleted?
**Yes** — in-app : Profil > Sécurité > Supprimer mon compte (suppression immédiate). Il faut aussi déclarer une **URL web** de demande de suppression (exigence Play depuis 2023 pour les comptes supprimables) — voir `docs/STORE_CHECKLIST.md`, point à créer si absent.

## Health data — déclaration spécifique

Le profil (poids, taille, allergies, régime) et les photos de progression constituent des données de santé au sens large. Play demande une déclaration explicite pour "Health info" — cocher cette catégorie et lister les finalités (personnalisation nutritionnelle, pas de diagnostic médical).

## Points à trancher avant de remplir le formulaire définitif

1. Confirmer si "Photos" doit être déclaré comme partagé avec Google (Gemini) même quand l'IA locale (Gemma3n on-device) est utilisée à la place — par prudence, déclarer le partage car le chemin cloud reste possible/par défaut.
2. Confirmer la position Play sur Cloudflare Workers AI / Pollinations.ai : ils ne reçoivent que du texte (titre/description de plat), pas de donnée personnelle identifiable — probablement pas à déclarer comme "Photos" partagées, mais à vérifier.
3. Open Food Facts : aucune donnée personnelle envoyée (appel anonyme) — pas de déclaration nécessaire pour ce flux.
4. Hugging Face : aucune donnée utilisateur envoyée (téléchargement de modèle avec jeton serveur partagé) — pas de déclaration nécessaire.

**Tout ce document doit être relu par toi (pas par un juriste obligatoirement, mais tu es responsable du contenu déclaré à Google) avant soumission.**
