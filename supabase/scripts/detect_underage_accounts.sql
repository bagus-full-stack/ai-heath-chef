-- ============================================================================
-- Détection des comptes < 16 ans créés avant la case de consentement
-- (migration 0018_add_accepted_terms_to_profiles.sql) — RGPD art. 8/9.
-- ============================================================================
-- Lecture seule. Un compte sans accepted_terms_at n'a jamais vu la case
-- "J'ai au moins 16 ans..." du nouveau signup_screen.dart : c'est le
-- meilleur proxy disponible, l'app ne stocke pas de date de création de
-- profil distincte de auth.users.created_at.
--
-- Traitement : volontairement PAS automatisé ici. Décision humaine requise
-- (contacter le compte, exiger confirmation d'âge, ou suppression RGPD) avant
-- toute action sur un vrai compte utilisateur — voir delete-account/index.ts
-- pour la procédure de suppression existante si c'est la décision prise.
select
  p.user_id,
  p.age,
  p.email,
  u.created_at as account_created_at,
  p.accepted_terms_at
from public.profiles p
join auth.users u on u.id = p.user_id
where p.age < 16
  and p.accepted_terms_at is null
order by u.created_at;
