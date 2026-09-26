-- ============================================================================
-- Sync cross-device du poids, de l'hydratation et des rappels personnalisés
-- ============================================================================
-- Jusqu'ici ces données vivaient uniquement dans la base SQLite locale
-- (lib/local_db/) : perdues à la désinstallation, non partagées entre
-- appareils. Ces 3 tables leur donnent une copie Supabase, synchronisée
-- selon le même principe offline-first que `meals` (0001_init_schema.sql).

-- ============================================================================
-- 1. WEIGHT_ENTRIES — historique des pesées (courbe de progression)
-- ============================================================================
create table if not exists public.weight_entries (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  weight_kg   numeric(5, 2) not null check (weight_kg > 0),
  recorded_at timestamptz not null default now()
);

comment on table public.weight_entries is 'Historique des pesées de l''utilisateur, pour la courbe de progression.';

create index if not exists idx_weight_entries_user_id_recorded_at
  on public.weight_entries (user_id, recorded_at);

alter table public.weight_entries enable row level security;

drop policy if exists "weight_entries_select_own" on public.weight_entries;
create policy "weight_entries_select_own" on public.weight_entries
  for select using (auth.uid() = user_id);

drop policy if exists "weight_entries_insert_own" on public.weight_entries;
create policy "weight_entries_insert_own" on public.weight_entries
  for insert with check (auth.uid() = user_id);

drop policy if exists "weight_entries_update_own" on public.weight_entries;
create policy "weight_entries_update_own" on public.weight_entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "weight_entries_delete_own" on public.weight_entries;
create policy "weight_entries_delete_own" on public.weight_entries
  for delete using (auth.uid() = user_id);

-- ============================================================================
-- 2. HYDRATION_ENTRIES — prises d'eau du jour (carte Hydratation du dashboard)
-- ============================================================================
create table if not exists public.hydration_entries (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  amount_ml   integer not null check (amount_ml > 0),
  recorded_at timestamptz not null default now()
);

comment on table public.hydration_entries is 'Prises d''eau enregistrées par l''utilisateur.';

create index if not exists idx_hydration_entries_user_id_recorded_at
  on public.hydration_entries (user_id, recorded_at);

alter table public.hydration_entries enable row level security;

drop policy if exists "hydration_entries_select_own" on public.hydration_entries;
create policy "hydration_entries_select_own" on public.hydration_entries
  for select using (auth.uid() = user_id);

drop policy if exists "hydration_entries_insert_own" on public.hydration_entries;
create policy "hydration_entries_insert_own" on public.hydration_entries
  for insert with check (auth.uid() = user_id);

drop policy if exists "hydration_entries_update_own" on public.hydration_entries;
create policy "hydration_entries_update_own" on public.hydration_entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "hydration_entries_delete_own" on public.hydration_entries;
create policy "hydration_entries_delete_own" on public.hydration_entries
  for delete using (auth.uid() = user_id);

-- ============================================================================
-- 3. CUSTOM_REMINDERS_BACKUP — sauvegarde des rappels personnalisés
-- ============================================================================
-- Les rappels eux-mêmes restent programmés en local (flutter_local_notifications,
-- voir NotificationService) : cette table ne sert qu'à restaurer la liste
-- (nom + heure + jour) sur un nouvel appareil ou après réinstallation.
-- Une seule ligne par utilisateur (upsert à chaque modification côté client).
create table if not exists public.custom_reminders_backup (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  reminders  jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

comment on table public.custom_reminders_backup is 'Sauvegarde de la liste des rappels personnalisés, pour restauration multi-appareil.';

drop trigger if exists trg_custom_reminders_backup_set_updated_at on public.custom_reminders_backup;
create trigger trg_custom_reminders_backup_set_updated_at
  before update on public.custom_reminders_backup
  for each row
  execute function public.set_updated_at();

alter table public.custom_reminders_backup enable row level security;

drop policy if exists "custom_reminders_backup_select_own" on public.custom_reminders_backup;
create policy "custom_reminders_backup_select_own" on public.custom_reminders_backup
  for select using (auth.uid() = user_id);

drop policy if exists "custom_reminders_backup_insert_own" on public.custom_reminders_backup;
create policy "custom_reminders_backup_insert_own" on public.custom_reminders_backup
  for insert with check (auth.uid() = user_id);

drop policy if exists "custom_reminders_backup_update_own" on public.custom_reminders_backup;
create policy "custom_reminders_backup_update_own" on public.custom_reminders_backup
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "custom_reminders_backup_delete_own" on public.custom_reminders_backup;
create policy "custom_reminders_backup_delete_own" on public.custom_reminders_backup
  for delete using (auth.uid() = user_id);
