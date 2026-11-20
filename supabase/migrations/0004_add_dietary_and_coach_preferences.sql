-- ============================================================================
-- Préférences alimentaires (régime + allergies) et personnalisation du ton
-- du Coach IA, rattachées au profil. Utilisées pour adapter les idées de
-- repas (meal-suggestions) et les réponses du coach (coach-chat) à chaque
-- utilisateur.
-- ============================================================================

alter table health_chef.profiles
  add column if not exists diet_type text not null default 'none'
    check (diet_type in ('none', 'vegetarian', 'vegan', 'pescetarian', 'halal', 'kosher')),
  add column if not exists allergies text[] not null default '{}'::text[],
  add column if not exists coach_tone text not null default 'motivant'
    check (coach_tone in ('motivant', 'bienveillant', 'direct', 'humoristique'));

comment on column health_chef.profiles.diet_type is
  'Régime alimentaire suivi : none, vegetarian, vegan, pescetarian, halal, kosher.';
comment on column health_chef.profiles.allergies is
  'Allergies/intolérances déclarées (texte libre), à éviter dans les suggestions IA.';
comment on column health_chef.profiles.coach_tone is
  'Ton du Coach IA choisi par l''utilisateur : motivant, bienveillant, direct, humoristique.';
