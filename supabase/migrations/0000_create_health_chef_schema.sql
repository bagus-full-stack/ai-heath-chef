-- ============================================================================
-- Schéma dédié à l'app : l'instance Supabase est partagée entre plusieurs apps,
-- donc rien de ce projet ne vit dans "public" (tables, fonctions, triggers).
-- ============================================================================
-- Les buckets Storage (storage.buckets/objects) et auth.users restent partagés.
-- Le schéma doit AUSSI être exposé à PostgREST : ajouter `health_chef` à
-- PGRST_DB_SCHEMAS (self-host : `.env` du stack, puis redémarrer le service rest).

create schema if not exists health_chef;

grant usage on schema health_chef to authenticated, service_role;

-- Droits par défaut sur les tables créées ensuite par ce rôle (RLS filtre par
-- utilisateur). anon n'a volontairement aucun accès : toutes les policies exigent auth.uid().
alter default privileges in schema health_chef
  grant select, insert, update, delete on tables to authenticated, service_role;
