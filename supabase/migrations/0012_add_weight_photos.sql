-- ============================================================================
-- Photo de progression (bucket "weight_photos"), attachée optionnellement à
-- une pesée — même principe que meal_photos (0006_add_meal_photos.sql).
-- ============================================================================

alter table public.weight_entries
  add column if not exists image_url text;

comment on column public.weight_entries.image_url is
  'URL publique de la photo de progression associée à cette pesée (bucket weight_photos). Optionnelle.';

insert into storage.buckets (id, name, public)
values ('weight_photos', 'weight_photos', true)
on conflict (id) do nothing;

drop policy if exists "weight_photos_public_read" on storage.objects;
create policy "weight_photos_public_read" on storage.objects
  for select using (bucket_id = 'weight_photos');

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
