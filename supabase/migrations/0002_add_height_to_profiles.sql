-- ============================================================================
-- Ajout de la taille au profil, nécessaire pour calculer l'IMC et affiner
-- les objectifs nutritionnels (computeNutritionTargets utilisait jusqu'ici
-- une taille moyenne assumée par sexe, faute de champ dédié).
-- ============================================================================

alter table public.profiles
  add column if not exists height_cm numeric(5, 1) not null default 0 check (height_cm >= 0);

comment on column public.profiles.height_cm is
  'Taille en centimètres. 0 = non renseignée (profils créés avant cette colonne).';
