-- ============================================================================
-- Quota GLOBAL (toute l'app, tous utilisateurs confondus) par Edge Function
-- IA et par jour, en complément du quota par utilisateur de 0008.
--
-- Le quota par utilisateur (api_usage) protège contre l'abus d'un seul
-- compte, mais pas contre l'épuisement agrégé : beaucoup d'utilisateurs
-- normaux, chacun sous sa limite individuelle, peuvent ensemble dépasser le
-- budget/débit gratuit de la clé GEMINI_API_KEY partagée par toute l'app.
-- Ce plafond global agit comme un disjoncteur : une fois atteint, l'app
-- répond avec un message clair plutôt que de casser silencieusement pour
-- tout le monde en même temps (erreur API brute, quota Gemini épuisé...).
-- ============================================================================

create table if not exists public.global_api_usage (
  function_name text not null,
  day           date not null default current_date,
  call_count    integer not null default 0,
  primary key (function_name, day)
);

comment on table public.global_api_usage is
  'Compteur d''appels IA par fonction/jour, agrégé sur tous les utilisateurs — plafond de sécurité pour le budget/débit partagé (clé API commune à toute l''app).';

alter table public.global_api_usage enable row level security;

-- Incrémente atomiquement le compteur global du jour et renvoie true si
-- l'appel reste sous la limite (donc autorisé), false s'il la dépasse déjà.
-- SECURITY DEFINER, réservé à service_role (même principe que
-- increment_api_usage en 0008) : aucun utilisateur ne peut lire ou
-- influencer ce compteur directement.
create or replace function public.increment_global_api_usage(
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
  insert into public.global_api_usage (function_name, day, call_count)
  values (p_function_name, current_date, 1)
  on conflict (function_name, day)
  do update set call_count = public.global_api_usage.call_count + 1
  returning call_count into v_count;

  return v_count <= p_daily_limit;
end;
$$;

revoke all on function public.increment_global_api_usage(text, integer) from public;
grant execute on function public.increment_global_api_usage(text, integer) to service_role;
