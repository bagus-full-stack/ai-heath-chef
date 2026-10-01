-- ============================================================================
-- ⚠️ À EXÉCUTER MANUELLEMENT, APRÈS VÉRIFICATION PAR UN HUMAIN. ⚠️
--
-- Ce script N'EST PAS une migration et n'est appelé par aucun script
-- automatique. Il met à NULL `chat_messages.image_url` pour toutes les
-- lignes déjà migrées vers Storage (`image_path` renseigné), afin de vider
-- le base64 devenu redondant.
--
-- Pré-requis avant de lancer ceci :
--   1. `supabase/migrations/0019_add_chat_images_bucket.sql` a été appliqué.
--   2. `supabase/scripts/backfill_chat_images.dart` a tourné jusqu'au bout
--      (voir son en-tête pour la commande) et sa sortie ne montre plus aucune
--      ligne en échec.
--   3. Vérification manuelle : confirmer qu'un échantillon de messages
--      affiche toujours bien son illustration dans l'app (URL signée sur
--      `image_path`) avant de supprimer le filet de sécurité `image_url`.
--
-- Après ce nettoyage, `image_path` devient la SEULE source d'illustration
-- pour les messages historiques (plus de repli possible) ; la colonne
-- `image_url` elle-même n'est pas supprimée (DROP COLUMN), seulement vidée,
-- au cas où on voudrait raffiner le backfill plus tard.
-- ============================================================================

update public.chat_messages
set image_url = null
where image_path is not null
  and image_url is not null;
