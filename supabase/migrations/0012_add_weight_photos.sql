-- ============================================================================
-- Photo de progression (bucket "hc_weight_photos"), attachée optionnellement à
-- une pesée — même principe que hc_meal_photos (0006_add_meal_photos.sql).
-- ============================================================================

alter table health_chef.weight_entries
  add column if not exists image_url text;

comment on column health_chef.weight_entries.image_url is
  'URL publique de la photo de progression associée à cette pesée (bucket hc_weight_photos). Optionnelle.';

insert into storage.buckets (id, name, public)
values ('hc_weight_photos', 'hc_weight_photos', true)
on conflict (id) do nothing;

drop policy if exists "hc_weight_photos_public_read" on storage.objects;
create policy "hc_weight_photos_public_read" on storage.objects
  for select using (bucket_id = 'hc_weight_photos');

drop policy if exists "hc_weight_photos_write_own_folder" on storage.objects;
create policy "hc_weight_photos_write_own_folder" on storage.objects
  for insert with check (
    bucket_id = 'hc_weight_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "hc_weight_photos_update_own_folder" on storage.objects;
create policy "hc_weight_photos_update_own_folder" on storage.objects
  for update using (
    bucket_id = 'hc_weight_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "hc_weight_photos_delete_own_folder" on storage.objects;
create policy "hc_weight_photos_delete_own_folder" on storage.objects
  for delete using (
    bucket_id = 'hc_weight_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
