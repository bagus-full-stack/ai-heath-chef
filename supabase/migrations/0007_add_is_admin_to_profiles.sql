-- ============================================================================
-- Compte admin : accès complet aux fonctionnalités PRO indépendamment de
-- tout abonnement RevenueCat. À activer manuellement depuis le SQL Editor
-- du dashboard Supabase pour un compte de confiance uniquement — il n'existe
-- volontairement AUCUN moyen de le modifier depuis l'application.
--
-- Exemple pour promouvoir un compte :
--   update public.profiles set is_admin = true where email = 'toi@exemple.com';
-- ============================================================================

alter table public.profiles
  add column if not exists is_admin boolean not null default false;

comment on column public.profiles.is_admin is
  'Compte admin avec accès complet aux fonctionnalités PRO, indépendamment de tout abonnement RevenueCat. À activer uniquement depuis le SQL Editor Supabase.';

-- La policy RLS "profiles_update_own" autorise déjà chaque utilisateur à
-- modifier SA PROPRE ligne (n'importe quelle colonne) — sans restriction
-- supplémentaire, un utilisateur pourrait donc s'auto-promouvoir admin via
-- un appel direct à l'API Supabase (hors de l'app). On retire explicitement
-- le droit de modifier cette colonne précise au rôle "authenticated" (celui
-- de l'app) ; seule une connexion avec les pleins pouvoirs (SQL Editor,
-- service_role) peut encore la modifier.
revoke update (is_admin) on public.profiles from authenticated;
