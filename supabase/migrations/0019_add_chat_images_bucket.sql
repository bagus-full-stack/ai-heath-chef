-- ============================================================================
-- Stocke les illustrations IA du coach dans Supabase Storage plutôt qu'en
-- base64 dans Postgres (voir 0015_add_image_url_to_chat_messages.sql) :
-- bucket PRIVÉ "chat_images" (lecture/écriture/suppression réservées au
-- propriétaire via policies scopées à son dossier {user_id}/...), même
-- principe que "meal_photos" (0006) et "avatars" (0001) mais privé — ce sont
-- des conversations personnelles, pas des photos à exposer publiquement.
--
-- `image_url` (data URI base64) n'est PAS supprimée ni modifiée par cette
-- migration : elle reste disponible en lecture pour l'historique existant
-- tant que le script de backfill (supabase/scripts/backfill_chat_images.dart)
-- n'a pas migré chaque ligne vers `image_path`. Elle ne doit plus jamais être
-- réalimentée pour un nouveau message côté app.
-- ============================================================================

alter table public.chat_messages
  add column if not exists image_path text;

comment on column public.chat_messages.image_path is
  'Chemin de l''illustration dans le bucket Storage chat_images ({user_id}/{uuid}.jpg). Remplace image_url (data URI) pour tout nouveau message ; voir supabase/scripts/backfill_chat_images.dart pour migrer l''historique existant.';

insert into storage.buckets (id, name, public)
values ('chat_images', 'chat_images', false)
on conflict (id) do nothing;

-- Bucket PRIVÉ : contrairement à "avatars"/"meal_photos", pas de policy de
-- lecture publique — l'app génère une URL signée à la demande
-- (createSignedUrl) pour afficher une illustration.
drop policy if exists "chat_images_read_own_folder" on storage.objects;
create policy "chat_images_read_own_folder" on storage.objects
  for select using (
    bucket_id = 'chat_images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "chat_images_write_own_folder" on storage.objects;
create policy "chat_images_write_own_folder" on storage.objects
  for insert with check (
    bucket_id = 'chat_images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "chat_images_update_own_folder" on storage.objects;
create policy "chat_images_update_own_folder" on storage.objects
  for update using (
    bucket_id = 'chat_images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "chat_images_delete_own_folder" on storage.objects;
create policy "chat_images_delete_own_folder" on storage.objects
  for delete using (
    bucket_id = 'chat_images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
