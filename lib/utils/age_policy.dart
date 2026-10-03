/// Âge minimum pour créer un compte (RGPD art. 8/9 : en deçà, le traitement
/// de données personnelles nécessiterait le consentement d'un titulaire de
/// l'autorité parentale, flux non implémenté dans l'app — voir onboarding et
/// inscription, seuls points de contrôle de cette borne).
const int kMinimumAge = 16;

/// Borne haute, inchangée depuis l'origine (valeur physiologique plausible,
/// sans lien avec la conformité RGPD).
const int kMaximumAge = 120;

/// Prédicat unique de validité d'âge pour la création/l'édition de profil,
/// réutilisé par onboarding_screen.dart et account_screen.dart.
bool isValidAge(int age) => age >= kMinimumAge && age <= kMaximumAge;
