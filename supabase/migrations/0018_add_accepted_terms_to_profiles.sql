-- ============================================================================
-- Traçabilité de l'acceptation des CGU/politique de confidentialité
-- (conformité RGPD art. 8/9 : âge minimum 16 ans relevé côté app, voir
-- lib/utils/age_policy.dart). Colonnes nullables, non destructif : les
-- comptes existants n'ont pas de valeur et ne sont pas bloqués par cette
-- migration (voir README pour le traitement des comptes < 16 ans déjà
-- créés, qui doit être décidé/exécuté manuellement).
-- ============================================================================

alter table public.profiles
  add column if not exists accepted_terms_at timestamptz,
  add column if not exists accepted_terms_version text;

comment on column public.profiles.accepted_terms_at is
  'Horodatage auquel l''utilisateur a coché la case d''acceptation des CGU/politique de confidentialité à l''inscription. Null pour les comptes créés avant l''ajout de cette case.';

comment on column public.profiles.accepted_terms_version is
  'Version des CGU/politique de confidentialité acceptée (voir kTermsVersion dans lib/screens/terms_screen.dart). Null pour les comptes créés avant l''ajout de cette case.';
