-- ============================================================================
-- Rate limit simple sur la demande de suppression de compte
-- (supabase/functions/delete-account), pour éviter qu'un abus (bug client en
-- boucle, ou jeton volé) ne déclenche des tentatives de suppression en
-- rafale. Fenêtre glissante par utilisateur (ex: 3 tentatives/heure) : les
-- tables api_usage/global_api_usage (0008/0009) sont par jour calendaire,
-- pas adaptées à une fenêtre d'une heure.
--
-- Même principe que api_usage (0008) : table manipulée UNIQUEMENT par
-- l'Edge Function via service_role, aucune policy select/insert/update
-- donnée à authenticated/anon.
-- ============================================================================

create table if not exists public.delete_account_attempts (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  attempted_at timestamptz not null default now()
);

comment on table public.delete_account_attempts is
  'Horodatage de chaque tentative de suppression de compte, pour appliquer un rate limit (fenêtre glissante) côté Edge Function delete-account.';

create index if not exists idx_delete_account_attempts_user_id_attempted_at
  on public.delete_account_attempts (user_id, attempted_at desc);

alter table public.delete_account_attempts enable row level security;

-- Enregistre une nouvelle tentative et renvoie true si le nombre de
-- tentatives sur la fenêtre glissante [now - p_window_minutes, now] reste
-- sous (ou égal à) p_max_attempts, false sinon.
-- SECURITY DEFINER : seul service_role peut l'appeler (voir revoke/grant
-- ci-dessous) — un utilisateur ne peut pas l'invoquer pour un autre
-- user_id que le sien, ni réinitialiser son propre compteur.
create or replace function public.check_delete_account_rate_limit(
  p_user_id uuid,
  p_max_attempts integer,
  p_window_minutes integer
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  insert into public.delete_account_attempts (user_id, attempted_at)
  values (p_user_id, now());

  select count(*) into v_count
  from public.delete_account_attempts
  where user_id = p_user_id
    and attempted_at > now() - (p_window_minutes || ' minutes')::interval;

  return v_count <= p_max_attempts;
end;
$$;

revoke all on function public.check_delete_account_rate_limit(uuid, integer, integer) from public;
grant execute on function public.check_delete_account_rate_limit(uuid, integer, integer) to service_role;
