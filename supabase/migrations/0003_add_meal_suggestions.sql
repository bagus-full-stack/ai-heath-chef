-- ============================================================================
-- MEAL_SUGGESTIONS — cache des idées de repas générées par l'IA (une entrée
-- par utilisateur et par jour). Évite de rappeler l'IA à chaque ouverture de
-- l'écran Coach/"Idées repas" tant que l'utilisateur ne demande pas
-- explicitement de nouvelles idées (bouton "Régénérer").
-- ============================================================================

create table if not exists public.meal_suggestions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  day         date not null,
  -- Snapshot des suggestions du jour : [{timeSlot, title, kcal, prot, gluc, lip, description}, ...]
  suggestions jsonb not null default '[]'::jsonb,
  created_at  timestamptz not null default now(),
  unique (user_id, day)
);

comment on table public.meal_suggestions is 'Cache quotidien des idées de repas générées par l''IA pour un utilisateur.';

alter table public.meal_suggestions enable row level security;

drop policy if exists "meal_suggestions_select_own" on public.meal_suggestions;
create policy "meal_suggestions_select_own" on public.meal_suggestions
  for select using (auth.uid() = user_id);

drop policy if exists "meal_suggestions_insert_own" on public.meal_suggestions;
create policy "meal_suggestions_insert_own" on public.meal_suggestions
  for insert with check (auth.uid() = user_id);

drop policy if exists "meal_suggestions_update_own" on public.meal_suggestions;
create policy "meal_suggestions_update_own" on public.meal_suggestions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "meal_suggestions_delete_own" on public.meal_suggestions;
create policy "meal_suggestions_delete_own" on public.meal_suggestions
  for delete using (auth.uid() = user_id);
