-- ============================================================================
-- Photo du repas/produit (bucket "hc_meal_photos"), affichée dans le journal du
-- Dashboard. Optionnelle : un repas issu d'un scan de code-barres n'a pas de
-- photo (image_url reste null dans ce cas).
-- ============================================================================

alter table health_chef.meals
  add column if not exists image_url text;

comment on column health_chef.meals.image_url is
  'URL publique de la photo du repas/produit (bucket hc_meal_photos). Null pour un repas issu d''un scan de code-barres.';

insert into storage.buckets (id, name, public)
values ('hc_meal_photos', 'hc_meal_photos', true)
on conflict (id) do nothing;

-- Lecture publique (getPublicUrl utilisé côté app, affiché dans le journal)
drop policy if exists "hc_meal_photos_public_read" on storage.objects;
create policy "hc_meal_photos_public_read" on storage.objects
  for select using (bucket_id = 'hc_meal_photos');

-- Écriture/màj/suppression uniquement dans son propre dossier {user_id}/...
drop policy if exists "hc_meal_photos_write_own_folder" on storage.objects;
create policy "hc_meal_photos_write_own_folder" on storage.objects
  for insert with check (
    bucket_id = 'hc_meal_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "hc_meal_photos_update_own_folder" on storage.objects;
create policy "hc_meal_photos_update_own_folder" on storage.objects
  for update using (
    bucket_id = 'hc_meal_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "hc_meal_photos_delete_own_folder" on storage.objects;
create policy "hc_meal_photos_delete_own_folder" on storage.objects
  for delete using (
    bucket_id = 'hc_meal_photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
