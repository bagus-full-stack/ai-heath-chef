-- ============================================================================
-- Ajoute une variante de `increment_global_api_usage` acceptant un montant
-- d'incrément explicite (`p_increment`), en plus de la version à 2 arguments
-- de la migration 0009 (qui incrémente toujours de 1 et reste utilisée telle
-- quelle par les autres Edge Functions).
--
-- Utilisée par `meal-images` : un seul appel peut générer plusieurs images
-- (jusqu'à 6, voir MAX_MEALS_PER_CALL dans meal-images/index.ts), et le
-- quota global doit refléter le nombre d'images réellement demandées — pas
-- 1 crédit par appel HTTP — pour protéger efficacement le budget gratuit
-- Cloudflare Workers AI partagé par toute l'app.
-- ============================================================================

create or replace function public.increment_global_api_usage(
  p_function_name text,
  p_daily_limit integer,
  p_increment integer
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  insert into public.global_api_usage (function_name, day, call_count)
  values (p_function_name, current_date, p_increment)
  on conflict (function_name, day)
  do update set call_count = public.global_api_usage.call_count + p_increment
  returning call_count into v_count;

  return v_count <= p_daily_limit;
end;
$$;

revoke all on function public.increment_global_api_usage(text, integer, integer) from public;
grant execute on function public.increment_global_api_usage(text, integer, integer) to service_role;
