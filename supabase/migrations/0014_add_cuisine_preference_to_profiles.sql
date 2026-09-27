-- ============================================================================
-- Préférence de cuisine (origine culinaire) rattachée au profil. Utilisée
-- pour orienter les idées de repas générées par l'IA (meal-suggestions) vers
-- des plats d'une cuisine donnée, en plus du régime/allergies déjà pris en
-- compte (voir migration 0004).
-- ============================================================================

alter table public.profiles
  add column if not exists cuisine_preference text not null default 'none'
    check (cuisine_preference in (
      'none', 'mediterranean', 'maghrebine', 'asian', 'indian',
      'middleEastern', 'african', 'latinAmerican', 'european'
    ));

comment on column public.profiles.cuisine_preference is
  'Cuisine préférée pour orienter les suggestions de repas IA : none (aucune préférence), mediterranean, maghrebine, asian, indian, middleEastern, african, latinAmerican, european.';
