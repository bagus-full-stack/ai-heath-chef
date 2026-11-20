-- ============================================================================
-- Complète 0024 (limites de taille) et purge les compteurs/tentatives anciens.
-- ============================================================================
-- `not valid` : seules les nouvelles écritures sont contrôlées (voir 0024).

alter table health_chef.custom_reminders_backup drop constraint if exists custom_reminders_backup_size;
alter table health_chef.custom_reminders_backup
  add constraint custom_reminders_backup_size check (
    pg_column_size(reminders) <= 50000
    and (fixed_reminders is null or pg_column_size(fixed_reminders) <= 5000)
  ) not valid;

alter table health_chef.profiles drop constraint if exists profiles_full_name_len;
alter table health_chef.profiles
  add constraint profiles_full_name_len check (char_length(full_name) <= 100) not valid;

alter table health_chef.profiles drop constraint if exists profiles_allergies_size;
alter table health_chef.profiles
  add constraint profiles_allergies_size check (
    cardinality(allergies) <= 50 and pg_column_size(allergies) <= 5000
  ) not valid;

alter table health_chef.meal_suggestions drop constraint if exists meal_suggestions_size;
alter table health_chef.meal_suggestions
  add constraint meal_suggestions_size check (pg_column_size(suggestions) <= 100000) not valid;

alter table health_chef.weekly_meal_plans drop constraint if exists weekly_meal_plans_size;
alter table health_chef.weekly_meal_plans
  add constraint weekly_meal_plans_size check (pg_column_size(suggestions) <= 300000) not valid;

-- chat_messages.image_url (data URI legacy) : plus jamais écrite par l'app (voir
-- 0019, remplacée par image_path). Un CHECK bloquerait aussi le backfill, qui met
-- à jour d'anciennes lignes ; on refuse donc seulement les INSERT venant de l'API.
create or replace function health_chef.prevent_chat_image_url_insert()
returns trigger
language plpgsql
as $$
begin
  if auth.role() in ('authenticated', 'anon') and new.image_url is not null then
    raise exception 'image_url est obsolète : utiliser image_path';
  end if;
  return new;
end;
$$;

drop trigger if exists chat_messages_no_image_url on health_chef.chat_messages;
create trigger chat_messages_no_image_url
  before insert on health_chef.chat_messages
  for each row execute function health_chef.prevent_chat_image_url_insert();

-- Purge opportuniste, bornée à l'utilisateur de l'appel (préfixe de clé/index) :
-- pas de pg_cron requis, donc compatible Supabase self-host.
create or replace function health_chef.increment_api_usage(
  p_user_id uuid,
  p_function_name text,
  p_daily_limit integer
) returns boolean
language plpgsql
security definer
set search_path = health_chef
as $$
declare
  v_count integer;
begin
  delete from health_chef.api_usage
  where user_id = p_user_id and day < current_date - 30;

  insert into health_chef.api_usage (user_id, function_name, day, call_count)
  values (p_user_id, p_function_name, current_date, 1)
  on conflict (user_id, function_name, day)
  do update set call_count = health_chef.api_usage.call_count + 1
  returning call_count into v_count;

  return v_count <= p_daily_limit;
end;
$$;

create or replace function health_chef.check_delete_account_rate_limit(
  p_user_id uuid,
  p_max_attempts integer,
  p_window_minutes integer
) returns boolean
language plpgsql
security definer
set search_path = health_chef
as $$
declare
  v_count integer;
begin
  delete from health_chef.delete_account_attempts
  where user_id = p_user_id
    and attempted_at < now() - make_interval(mins => greatest(p_window_minutes, 1440));

  insert into health_chef.delete_account_attempts (user_id, attempted_at)
  values (p_user_id, now());

  select count(*) into v_count
  from health_chef.delete_account_attempts
  where user_id = p_user_id
    and attempted_at > now() - make_interval(mins => p_window_minutes);

  return v_count <= p_max_attempts;
end;
$$;
