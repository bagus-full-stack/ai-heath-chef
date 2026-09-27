-- ============================================================================
-- WEEKLY_MEAL_PLANS — cache du plan de repas hebdomadaire généré par l'IA
-- (une entrée par utilisateur et par semaine). Table dédiée plutôt que de
-- réutiliser meal_suggestions (cache quotidien) : les deux caches peuvent
-- coexister pour la même date (ex: lundi = jour du cache quotidien ET début
-- de semaine du plan hebdo), une même colonne `day` entrerait en conflit.
-- ============================================================================

create table if not exists public.weekly_meal_plans (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  week_start  date not null,
  -- Snapshot du plan : [{timeSlot, title, kcal, prot, gluc, lip, description, ingredients, steps, day}, ...]
  suggestions jsonb not null default '[]'::jsonb,
  preferences_signature text not null default '',
  created_at  timestamptz not null default now(),
  unique (user_id, week_start)
);

comment on table public.weekly_meal_plans is 'Cache hebdomadaire du plan de repas généré par l''IA pour un utilisateur.';

alter table public.weekly_meal_plans enable row level security;

drop policy if exists "weekly_meal_plans_select_own" on public.weekly_meal_plans;
create policy "weekly_meal_plans_select_own" on public.weekly_meal_plans
  for select using (auth.uid() = user_id);

drop policy if exists "weekly_meal_plans_insert_own" on public.weekly_meal_plans;
create policy "weekly_meal_plans_insert_own" on public.weekly_meal_plans
  for insert with check (auth.uid() = user_id);

drop policy if exists "weekly_meal_plans_update_own" on public.weekly_meal_plans;
create policy "weekly_meal_plans_update_own" on public.weekly_meal_plans
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "weekly_meal_plans_delete_own" on public.weekly_meal_plans;
create policy "weekly_meal_plans_delete_own" on public.weekly_meal_plans
  for delete using (auth.uid() = user_id);
