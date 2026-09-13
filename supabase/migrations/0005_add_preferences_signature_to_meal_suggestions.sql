-- ============================================================================
-- Le cache quotidien des idées de repas (meal_suggestions) ne tenait pas
-- compte d'un changement de régime/allergies en cours de journée : si
-- l'utilisateur modifiait ses préférences après une première génération, le
-- cache du jour continuait à servir les anciennes suggestions (qui peuvent
-- désormais enfreindre la nouvelle contrainte) jusqu'à un "Régénérer" manuel.
--
-- On stocke donc la signature régime+allergies utilisée pour générer le
-- cache, comparée à la signature courante avant de le réutiliser.
-- ============================================================================

alter table public.meal_suggestions
  add column if not exists preferences_signature text not null default '';

comment on column public.meal_suggestions.preferences_signature is
  'Signature "diet_type|allergies triées" utilisée au moment de la génération, pour détecter un changement de préférences et invalider le cache du jour.';
