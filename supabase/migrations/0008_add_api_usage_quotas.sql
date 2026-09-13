-- ============================================================================
-- Quotas quotidiens par utilisateur sur les appels IA (Edge Functions), pour
-- éviter qu'un compte (ou la clé anon extraite de l'app) puisse spammer
-- analyze-meal / analyze-product / coach-chat / meal-suggestions et faire
-- exploser la facture Gemini sans plafond.
--
-- Cette table n'est manipulée QUE par les Edge Functions via la clé
-- service_role (qui contourne RLS) — aucune policy select/insert/update
-- n'est donnée à "authenticated"/"anon" : un utilisateur ne doit jamais
-- pouvoir lire ou modifier son propre compteur directement.
-- ============================================================================

create table if not exists public.api_usage (
  user_id       uuid not null references auth.users (id) on delete cascade,
  function_name text not null,
  day           date not null default current_date,
  call_count    integer not null default 0,
  primary key (user_id, function_name, day)
);

comment on table public.api_usage is
  'Compteur d''appels IA par utilisateur/fonction/jour, utilisé pour appliquer des quotas quotidiens côté Edge Functions.';

alter table public.api_usage enable row level security;

-- Incrémente atomiquement le compteur du jour et renvoie true si l'appel
-- reste sous la limite (donc autorisé), false s'il la dépasse déjà.
-- SECURITY DEFINER : s'exécute avec les droits du propriétaire (contourne
-- RLS sur api_usage), mais seul le rôle service_role peut l'appeler (voir
-- revoke/grant ci-dessous) — un utilisateur ne peut pas l'invoquer pour un
-- autre user_id que le sien, ni pour gonfler/réinitialiser son propre quota.
create or replace function public.increment_api_usage(
  p_user_id uuid,
  p_function_name text,
  p_daily_limit integer
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  insert into public.api_usage (user_id, function_name, day, call_count)
  values (p_user_id, p_function_name, current_date, 1)
  on conflict (user_id, function_name, day)
  do update set call_count = public.api_usage.call_count + 1
  returning call_count into v_count;

  return v_count <= p_daily_limit;
end;
$$;

revoke all on function public.increment_api_usage(uuid, text, integer) from public;
grant execute on function public.increment_api_usage(uuid, text, integer) to service_role;
