// Buckets contenant des fichiers par utilisateur (dossier `{user_id}/...`,
// voir policies de storage.objects dans 0001/0006/0012/0019). Les lignes des
// tables Postgres (profiles, meals, chat_messages, meal_suggestions,
// weight_entries, hydration_entries, custom_reminders_backup,
// weekly_meal_plans, api_usage) ont TOUTES un `on delete cascade` vers
// auth.users : elles sont supprimées automatiquement par
// `auth.admin.deleteUser` (voir index.ts), sans DELETE explicite. Seul le
// Storage (aucune relation FK avec auth.users) doit être nettoyé à la main.
//
// ⚠️ À CHAQUE NOUVEAU BUCKET créé par une migration (`insert into
// storage.buckets`), ajoute-le ici. Un bucket oublié ici laisse les fichiers
// de l'utilisateur supprimé orphelins indéfiniment (non-conformité RGPD,
// droit à l'effacement). `storage_buckets_test.ts` (même dossier) échoue si
// un bucket créé dans supabase/migrations/ manque dans cette liste.
//
// Module séparé de index.ts (qui appelle Deno.serve au niveau racine) pour
// que le test puisse importer cette constante sans démarrer un serveur HTTP.
export const STORAGE_BUCKETS = ["avatars", "meal_photos", "weight_photos", "chat_images"];
