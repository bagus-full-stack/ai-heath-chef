-- ============================================================================
-- Photo du repas/produit (bucket "meal_photos"), affichée dans le journal du
-- Dashboard. Optionnelle : un repas issu d'un scan de code-barres n'a pas de
-- photo (image_url reste null dans ce cas).
-- ============================================================================

alter table public.meals
  add column if not exists image_url text;

comment on column public.meals.image_url is
  'URL publique de la photo du repas/produit (bucket meal_photos). Null pour un repas issu d''un scan de code-barres.';

insert into storage.buckets (id, name, public)
values ('meal_photos', 'meal_photos', true)
on conflict (id) do nothing;

-- Lecture publique (getPublicUrl utilisé côté app, affiché dans le journal)
drop policy if exists "meal_photos_public_read" on storage.objects;
create policy "meal_photos_public_read" on storage.objects
  for select using (bucket_id = 'meal_photos');

-- Écriture/màj/suppression uniquement dans son propre dossier {user_id}/...
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
