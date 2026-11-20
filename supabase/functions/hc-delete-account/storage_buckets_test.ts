import { assertEquals } from "jsr:@std/assert@1";
import { STORAGE_BUCKETS } from "./storage_buckets.ts";

/**
 * Empêche qu'un nouveau bucket (créé via `insert into storage.buckets` dans
 * une migration) soit oublié dans STORAGE_BUCKETS — l'oubli laisse les
 * fichiers de l'utilisateur supprimé orphelins (voir commentaire au-dessus
 * de STORAGE_BUCKETS dans storage_buckets.ts).
 */
Deno.test("STORAGE_BUCKETS liste bien tous les buckets créés dans supabase/migrations/", async () => {
  const migrationsDir = new URL("../../migrations/", import.meta.url);
  const bucketsInMigrations = new Set<string>();

  for await (const entry of Deno.readDir(migrationsDir)) {
    if (!entry.isFile || !entry.name.endsWith(".sql")) continue;
    const content = await Deno.readTextFile(new URL(entry.name, migrationsDir));
    const regex = /insert into storage\.buckets[^;]*values\s*\(\s*'([^']+)'/gi;
    for (const match of content.matchAll(regex)) {
      bucketsInMigrations.add(match[1]);
    }
  }

  // Si ce test échoue avec un Set vide, le chemin relatif vers
  // supabase/migrations/ a cassé (ex. déplacement de ce fichier de test) —
  // pas une absence réelle de bucket, à vérifier avant de "corriger" la liste.
  assertEquals(
    bucketsInMigrations.size > 0,
    true,
    "aucun bucket trouvé dans supabase/migrations/ — vérifier le chemin",
  );

  const missing = [...bucketsInMigrations].filter((id) => !STORAGE_BUCKETS.includes(id));
  assertEquals(missing, [], `buckets présents dans les migrations mais absents de STORAGE_BUCKETS: ${missing.join(", ")}`);
});
