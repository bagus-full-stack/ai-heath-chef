-- ============================================================================
-- Illustration IA optionnelle d'un message du coach, générée quand celui-ci
-- recommande un plat précis (voir coach-chat/index.ts, balise [DISH: ...],
-- et meal-images/index.ts pour la génération de l'image).
-- ============================================================================

alter table public.chat_messages
  add column if not exists image_url text;

comment on column public.chat_messages.image_url is
  'Data URI de l''illustration générée pour un plat recommandé par le coach. NULL si aucun plat précis n''a été suggéré.';
