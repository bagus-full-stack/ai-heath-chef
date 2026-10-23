-- ============================================================================
-- Verrouille `profiles.is_admin` contre toute modification depuis l'API.
-- ============================================================================
-- La migration 0007 faisait `revoke update (is_admin) ... from authenticated`,
-- mais un REVOKE au niveau d'une colonne n'a aucun effet tant que le droit
-- UPDATE existe sur toute la table (cas par défaut de Supabase), et l'INSERT
-- n'était pas restreint : un utilisateur connecté pouvait donc se promouvoir
-- admin (quota IA illimité + PRO gratuit). Ce déclencheur refuse tout
-- changement venant d'un JWT `authenticated`/`anon` ; le SQL Editor (rôle
-- postgres) et service_role restent libres de modifier la colonne.
-- ============================================================================

create or replace function public.prevent_is_admin_change()
returns trigger
language plpgsql
as $$
begin
  if auth.role() in ('authenticated', 'anon')
     and ((tg_op = 'INSERT' and new.is_admin)
          or (tg_op = 'UPDATE' and new.is_admin is distinct from old.is_admin)) then
    raise exception 'is_admin ne peut pas être modifié depuis l''API';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_is_admin on public.profiles;
create trigger profiles_protect_is_admin
  before insert or update on public.profiles
  for each row execute function public.prevent_is_admin_change();
