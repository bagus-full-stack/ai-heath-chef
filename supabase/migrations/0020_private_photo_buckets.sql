-- ============================================================================
-- Passe les buckets avatars / meal_photos / weight_photos en PRIVÉ, même
-- principe que chat_images (0019_add_chat_images_bucket.sql) : ce sont des
-- photos de profil, de repas et de progression — des données personnelles
-- (de santé pour les deux dernières) qu'une URL publique devinable ou
-- partagée exposerait sans expiration ni révocation possible.
--
-- Colonnes `*_path` ajoutées À CÔTÉ des colonnes `*_url` existantes (non
-- supprimées, non renseignées par cette migration) : stockent désormais le
-- chemin dans le bucket, pour générer une URL signée à la demande côté app
-- (lib/services/storage_image_service.dart, `createSignedUrl`).
--
-- Projet pas encore publié : aucun client externe ne dépend des URLs
-- publiques actuelles, donc pas de rétrocompatibilité ni de double
-- migration — contrairement à 0019, les anciennes policies de lecture
-- publique sont supprimées ici, pas seulement absentes pour le nouveau
-- bucket.
--
-- Ordre d'application :
--   1. Déployer le build de l'app qui écrit `*_path` et affiche via URL
--      signée (StorageImageService) au lieu de `getPublicUrl`.
--   2. Appliquer cette migration (buckets privés + nouvelles policies).
--   3. Traiter les anciennes données de test : voir
--      supabase/scripts/handle_test_photos_before_private.sql (à lancer
--      manuellement, deux options commentées).
-- ============================================================================

alter table public.profiles
  add column if not exists avatar_path text;
comment on column public.profiles.avatar_path is
  'Chemin de la photo de profil dans le bucket Storage avatars ({user_id}/{uuid}.jpg). Remplace avatar_url (URL publique) pour tout nouvel upload.';

alter table public.meals
  add column if not exists image_path text;
comment on column public.meals.image_path is
  'Chemin de la photo du repas/produit dans le bucket Storage meal_photos ({user_id}/{meal_id}.jpg). Remplace image_url (URL publique) pour tout nouveau repas.';

alter table public.weight_entries
  add column if not exists image_path text;
comment on column public.weight_entries.image_path is
  'Chemin de la photo de progression dans le bucket Storage weight_photos ({user_id}/{entry_id}.jpg). Remplace image_url (URL publique) pour toute nouvelle pesée.';

update storage.buckets set public = false where id in ('avatars', 'meal_photos', 'weight_photos');

-- avatars ---------------------------------------------------------------
drop policy if exists "avatars_public_read" on storage.objects;
drop policy if exists "avatars_read_own_folder" on storage.objects;
create policy "avatars_read_own_folder" on storage.objects
  for select using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars_write_own_folder" on storage.objects;
create policy "avatars_write_own_folder" on storage.objects
  for insert with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars_update_own_folder" on storage.objects;
create policy "avatars_update_own_folder" on storage.objects
  for update using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars_delete_own_folder" on storage.objects;
create policy "avatars_delete_own_folder" on storage.objects
  for delete using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- meal_photos -------------------------------------------------------------
drop policy if exists "meal_photos_public_read" on storage.objects;
drop policy if exists "meal_photos_read_own_folder" on storage.objects;
create policy "meal_photos_read_own_folder" on storage.objects
  for select using (
    bucket_id = 'meal_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "meal_photos_write_own_folder" on storage.objects;
create policy "meal_photos_write_own_folder" on storage.objects
  for insert with check (
    bucket_id = 'meal_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "meal_photos_update_own_folder" on storage.objects;
create policy "meal_photos_update_own_folder" on storage.objects
  for update using (
    bucket_id = 'meal_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "meal_photos_delete_own_folder" on storage.objects;
create policy "meal_photos_delete_own_folder" on storage.objects
  for delete using (
    bucket_id = 'meal_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- weight_photos -------------------------------------------------------------
drop policy if exists "weight_photos_public_read" on storage.objects;
drop policy if exists "weight_photos_read_own_folder" on storage.objects;
create policy "weight_photos_read_own_folder" on storage.objects
  for select using (
    bucket_id = 'weight_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "weight_photos_write_own_folder" on storage.objects;
create policy "weight_photos_write_own_folder" on storage.objects
  for insert with check (
    bucket_id = 'weight_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "weight_photos_update_own_folder" on storage.objects;
create policy "weight_photos_update_own_folder" on storage.objects
  for update using (
    bucket_id = 'weight_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "weight_photos_delete_own_folder" on storage.objects;
create policy "weight_photos_delete_own_folder" on storage.objects
  for delete using (
    bucket_id = 'weight_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
