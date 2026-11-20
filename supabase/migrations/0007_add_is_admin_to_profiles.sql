-- ============================================================================
-- Compte admin : accès complet aux fonctionnalités PRO indépendamment de
-- tout abonnement RevenueCat. À activer manuellement depuis le SQL Editor
-- du dashboard Supabase pour un compte de confiance uniquement — il n'existe
-- volontairement AUCUN moyen de le modifier depuis l'application.
--
-- Exemple pour promouvoir un compte :
--   update health_chef.profiles set is_admin = true where email = 'toi@exemple.com';
-- ============================================================================

alter table health_chef.profiles
  add column if not exists is_admin boolean not null default false;

comment on column health_chef.profiles.is_admin is
  'Compte admin avec accès complet aux fonctionnalités PRO, indépendamment de tout abonnement RevenueCat. À activer uniquement depuis le SQL Editor Supabase.';

-- La policy RLS "profiles_update_own" autorise déjà chaque utilisateur à
-- modifier SA PROPRE ligne (n'importe quelle colonne) — sans restriction
-- supplémentaire, un utilisateur pourrait donc s'auto-promouvoir admin via
-- un appel direct à l'API Supabase (hors de l'app).
-- ATTENTION : le REVOKE ci-dessous est INEFFICACE tant que "authenticated" a
-- le droit UPDATE sur toute la table (défaut Supabase), et il ne couvre pas
-- l'INSERT. La vraie protection est le trigger de 0023_protect_is_admin.sql.
revoke update (is_admin) on health_chef.profiles from authenticated;
