-- ============================================================================
-- Fodli — Schéma de base de données initial
-- ============================================================================
-- Ce script est idempotent (IF NOT EXISTS) et peut être exécuté depuis le
-- dashboard Supabase (SQL Editor) ou via `supabase db push`.
--
-- Périmètre couvert (déduit du code Flutter existant) :
--   - profiles       : profil métier lié à auth.users (1-1)
--   - meals          : repas loggés par l'utilisateur, avec ingrédients en JSONB
--   - chat_messages  : historique du chat avec le coach IA
--   - storage.hc_avatars: bucket public pour les photos de profil
--
-- Non couvert (géré hors base de données) :
--   - Abonnements/paiements : gérés par RevenueCat (SDK purchases_flutter),
--     aucune table Supabase associée dans le code actuel.
-- ============================================================================

-- Extension nécessaire pour gen_random_uuid()
create extension if not exists pgcrypto;

-- ============================================================================
-- 1. PROFILES — profil métier (1 ligne par utilisateur auth)
-- ============================================================================
create table if not exists health_chef.profiles (
  user_id        uuid primary key references auth.users (id) on delete cascade,
  email          text,
  full_name      text not null default 'Utilisateur',
  sex            text not null default 'other' check (sex in ('male', 'female', 'other')),
  age            integer not null default 0 check (age >= 0),
  current_weight numeric(5, 2) not null default 0 check (current_weight >= 0),
  target_weight  numeric(5, 2) not null default 0 check (target_weight >= 0),
  goal           text not null default 'maintain' check (goal in ('loseWeight', 'gainMuscle', 'maintain')),
  avatar_url     text,
  updated_at     timestamptz not null default now()
);

comment on table health_chef.profiles is 'Profil nutrition/santé de chaque utilisateur, 1-1 avec auth.users.';

-- Maintien automatique de updated_at
create or replace function health_chef.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_set_updated_at on health_chef.profiles;
create trigger trg_profiles_set_updated_at
  before update on health_chef.profiles
  for each row
  execute function health_chef.set_updated_at();

alter table health_chef.profiles enable row level security;

drop policy if exists "profiles_select_own" on health_chef.profiles;
create policy "profiles_select_own" on health_chef.profiles
  for select using (auth.uid() = user_id);

drop policy if exists "profiles_insert_own" on health_chef.profiles;
create policy "profiles_insert_own" on health_chef.profiles
  for insert with check (auth.uid() = user_id);

drop policy if exists "profiles_update_own" on health_chef.profiles;
create policy "profiles_update_own" on health_chef.profiles
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "profiles_delete_own" on health_chef.profiles;
create policy "profiles_delete_own" on health_chef.profiles
  for delete using (auth.uid() = user_id);

-- ============================================================================
-- 2. MEALS — repas loggés (scan photo ou saisie manuelle)
-- ============================================================================
create table if not exists health_chef.meals (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  name        text not null,
  total_kcal  integer not null check (total_kcal >= 0),
  total_prot  numeric(7, 2) not null default 0 check (total_prot >= 0),
  total_gluc  numeric(7, 2) not null default 0 check (total_gluc >= 0),
  total_lip   numeric(7, 2) not null default 0 check (total_lip >= 0),
  -- Snapshot des ingrédients au moment du log : [{name, weight, kcal, prot, gluc, lip}, ...]
  ingredients jsonb not null default '[]'::jsonb,
  created_at  timestamptz not null default now()
);

comment on table health_chef.meals is 'Repas enregistrés par l''utilisateur, avec le détail des ingrédients en JSONB.';

create index if not exists idx_meals_user_id_created_at
  on health_chef.meals (user_id, created_at desc);

alter table health_chef.meals enable row level security;

drop policy if exists "meals_select_own" on health_chef.meals;
create policy "meals_select_own" on health_chef.meals
  for select using (auth.uid() = user_id);

drop policy if exists "meals_insert_own" on health_chef.meals;
create policy "meals_insert_own" on health_chef.meals
  for insert with check (auth.uid() = user_id);

drop policy if exists "meals_update_own" on health_chef.meals;
create policy "meals_update_own" on health_chef.meals
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "meals_delete_own" on health_chef.meals;
create policy "meals_delete_own" on health_chef.meals
  for delete using (auth.uid() = user_id);

-- ============================================================================
-- 3. CHAT_MESSAGES — historique du chat avec le coach IA
-- ============================================================================
create table if not exists health_chef.chat_messages (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  role       text not null check (role in ('user', 'assistant')),
  text       text not null,
  created_at timestamptz not null default now()
);

comment on table health_chef.chat_messages is 'Historique des messages échangés entre l''utilisateur et le coach IA (Gemini).';

create index if not exists idx_chat_messages_user_id_created_at
  on health_chef.chat_messages (user_id, created_at desc);

alter table health_chef.chat_messages enable row level security;

drop policy if exists "chat_messages_select_own" on health_chef.chat_messages;
create policy "chat_messages_select_own" on health_chef.chat_messages
  for select using (auth.uid() = user_id);

drop policy if exists "chat_messages_insert_own" on health_chef.chat_messages;
create policy "chat_messages_insert_own" on health_chef.chat_messages
  for insert with check (auth.uid() = user_id);

drop policy if exists "chat_messages_delete_own" on health_chef.chat_messages;
create policy "chat_messages_delete_own" on health_chef.chat_messages
  for delete using (auth.uid() = user_id);

-- ============================================================================
-- 4. STORAGE — bucket "hc_avatars" pour les photos de profil
-- ============================================================================
insert into storage.buckets (id, name, public)
values ('hc_avatars', 'hc_avatars', true)
on conflict (id) do nothing;

-- Lecture publique (getPublicUrl utilisé côté app)
drop policy if exists "hc_avatars_public_read" on storage.objects;
create policy "hc_avatars_public_read" on storage.objects
  for select using (bucket_id = 'hc_avatars');

-- Écriture/màj/suppression uniquement dans son propre dossier {user_id}/...
drop policy if exists "hc_avatars_write_own_folder" on storage.objects;
create policy "hc_avatars_write_own_folder" on storage.objects
  for insert with check (
    bucket_id = 'hc_avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "hc_avatars_update_own_folder" on storage.objects;
create policy "hc_avatars_update_own_folder" on storage.objects
  for update using (
    bucket_id = 'hc_avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "hc_avatars_delete_own_folder" on storage.objects;
create policy "hc_avatars_delete_own_folder" on storage.objects
  for delete using (
    bucket_id = 'hc_avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
