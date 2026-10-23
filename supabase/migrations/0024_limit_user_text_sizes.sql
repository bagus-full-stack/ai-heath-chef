-- ============================================================================
-- Limites de taille sur les champs texte/JSON écrits directement par le client.
-- ============================================================================
-- Un utilisateur connecté peut appeler l'API Postgres sans passer par l'app :
-- sans limite, un seul compte pourrait remplir les 500 Mo du plan gratuit.
-- `not valid` : les lignes déjà présentes ne sont pas revérifiées, seules les
-- nouvelles écritures sont contrôlées.
-- ============================================================================

alter table public.chat_reports drop constraint if exists chat_reports_commentaire_len;
alter table public.chat_reports
  add constraint chat_reports_commentaire_len check (char_length(commentaire) <= 2000) not valid;

alter table public.chat_reports drop constraint if exists chat_reports_excerpt_len;
alter table public.chat_reports
  add constraint chat_reports_excerpt_len check (char_length(excerpt) <= 2000) not valid;

alter table public.chat_messages drop constraint if exists chat_messages_text_len;
alter table public.chat_messages
  add constraint chat_messages_text_len check (char_length(text) <= 10000) not valid;

alter table public.meals drop constraint if exists meals_ingredients_size;
alter table public.meals
  add constraint meals_ingredients_size check (pg_column_size(ingredients) <= 50000) not valid;
