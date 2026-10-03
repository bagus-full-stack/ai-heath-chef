-- ============================================================================
-- ⚠️ À EXÉCUTER MANUELLEMENT, APRÈS AVOIR CHOISI UNE DES DEUX OPTIONS. ⚠️
--
-- Traite les lignes qui ont encore une ancienne URL publique (`*_url`) mais
-- pas de chemin Storage (`*_path`) — typiquement des données de test
-- antérieures à 0020_private_photo_buckets.sql. Rien n'est automatique : ce
-- script n'est appelé par aucune migration.
--
-- 1. D'abord ce SELECT, pour voir ce qui serait concerné par les deux
--    options ci-dessous avant de choisir :
-- ============================================================================

select 'profiles' as table_name, user_id::text as row_id, avatar_url as old_url
  from public.profiles where avatar_path is null and avatar_url is not null
union all
select 'meals', id::text, image_url
  from public.meals where image_path is null and image_url is not null
union all
select 'weight_entries', id::text, image_url
  from public.weight_entries where image_path is null and image_url is not null;

-- ============================================================================
-- OPTION A — Backfill : déduit le chemin Storage à partir du schéma d'upload
-- connu (`{user_id}/{nom de fichier}`, voir uploadAvatar/_uploadPhoto dans
-- l'app) plutôt que de parser l'URL publique. Les fichiers eux-mêmes ne sont
-- pas déplacés ni touchés — seul le pointeur `*_path` est renseigné, pointant
-- vers le fichier déjà existant dans le bucket (maintenant privé).
-- Décommenter pour l'utiliser :
-- ============================================================================

-- update public.profiles
-- set avatar_path = user_id || '/avatar.jpg'
-- where avatar_path is null and avatar_url is not null;
--
-- update public.meals
-- set image_path = user_id || '/' || id || '.jpg'
-- where image_path is null and image_url is not null;
--
-- update public.weight_entries
-- set image_path = user_id || '/' || id || '.jpg'
-- where image_path is null and image_url is not null;

-- ============================================================================
-- OPTION B — Remise à zéro : pour des données de test qu'on ne tient pas à
-- préserver. Vide `*_url` (le pointeur devient simplement absent, l'app
-- affiche un placeholder) ; les fichiers restent dans le bucket (désormais
-- privé, donc déjà inoffensifs) et peuvent être supprimés séparément depuis
-- le dashboard Supabase > Storage si besoin de libérer l'espace.
-- Décommenter pour l'utiliser :
-- ============================================================================

-- update public.profiles set avatar_url = null where avatar_path is null and avatar_url is not null;
-- update public.meals set image_url = null where image_path is null and image_url is not null;
-- update public.weight_entries set image_url = null where image_path is null and image_url is not null;
