import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"
import { STORAGE_BUCKETS } from "./storage_buckets.ts"

// 1. Headers CORS complets
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const STORAGE_LIST_PAGE_SIZE = 1000;

const RATE_LIMIT_MAX_ATTEMPTS = 3;
const RATE_LIMIT_WINDOW_MINUTES = 60;

/**
 * Supprime tout le contenu du dossier `{userId}/` d'un bucket, par pages
 * (la liste est toujours relue à l'offset 0 après chaque suppression, pour
 * ne pas sauter d'entrées pendant que le dossier se vide).
 */
async function deleteUserFolder(
    // deno-lint-ignore no-explicit-any
    serviceClient: any,
    bucket: string,
    userId: string,
): Promise<void> {
    while (true) {
        const { data: files, error } = await serviceClient.storage
            .from(bucket)
            .list(userId, { limit: STORAGE_LIST_PAGE_SIZE });
        if (error) throw error;
        if (!files || files.length === 0) break;

        const paths = files.map((f: { name: string }) => `${userId}/${f.name}`);
        const { error: removeError } = await serviceClient.storage.from(bucket).remove(paths);
        if (removeError) throw removeError;

        if (files.length < STORAGE_LIST_PAGE_SIZE) break;
    }
}

Deno.serve(async (req) => {
    // === GESTION DU PREFLIGHT (CORS) ===
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    const jsonHeaders = { ...corsHeaders, 'Content-Type': 'application/json' };

    let body: Record<string, unknown> = {};
    try {
        body = await req.json();
    } catch (_e) {
        // Corps vide/malformé toléré : `confirm` sera simplement absent et
        // rejeté par la vérification plus bas.
    }
    const lang = body?.lang === 'en' ? 'en' : 'fr';
    const isEn = lang === 'en';

    // === AUTHENTIFICATION : l'id de l'utilisateur à supprimer vient
    // EXCLUSIVEMENT du JWT vérifié ici, jamais du body — un utilisateur ne
    // peut donc jamais demander la suppression d'un autre compte. ===
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
        return new Response(
            JSON.stringify({ error: isEn ? "Authentication required." : "Authentification requise." }),
            { status: 401, headers: jsonHeaders },
        );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    const userClient = createClient(supabaseUrl, anonKey, {
        global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData?.user) {
        return new Response(
            JSON.stringify({ error: isEn ? "Invalid authentication." : "Authentification invalide." }),
            { status: 401, headers: jsonHeaders },
        );
    }
    const userId = userData.user.id;
    const serviceClient = createClient(supabaseUrl, serviceRoleKey);

    // === RATE LIMIT (3 tentatives/heure) : compte TOUTE requête authentifiée
    // reçue ici, avant même la vérification de `confirm`, pour se protéger
    // d'un appel en boucle quelle que soit la forme du body. ===
    const { data: allowed, error: rateLimitError } = await serviceClient.rpc(
        'check_delete_account_rate_limit',
        {
            p_user_id: userId,
            p_max_attempts: RATE_LIMIT_MAX_ATTEMPTS,
            p_window_minutes: RATE_LIMIT_WINDOW_MINUTES,
        },
    );
    if (rateLimitError) {
        console.error('Erreur rate limit (delete-account) :', rateLimitError.message);
        return new Response(
            JSON.stringify({
                error: isEn
                    ? "Account deletion temporarily failed. Please try again later."
                    : "La suppression du compte a temporairement échoué. Réessaie plus tard.",
            }),
            { status: 500, headers: jsonHeaders },
        );
    }
    if (!allowed) {
        return new Response(
            JSON.stringify({
                error: isEn
                    ? "Too many attempts. Please try again in an hour."
                    : "Trop de tentatives. Réessaie dans une heure.",
            }),
            { status: 429, headers: jsonHeaders },
        );
    }

    // === GARDE-FOU MINIMAL : le client doit explicitement confirmer. ===
    if (body?.confirm !== true) {
        return new Response(
            JSON.stringify({ error: isEn ? "Explicit confirmation required." : "Confirmation explicite requise." }),
            { status: 400, headers: jsonHeaders },
        );
    }

    // === SUPPRESSION : Storage (pas de cascade possible) puis l'utilisateur
    // Auth (cascade automatique vers toutes les tables Postgres). Idempotent
    // en cas de nouvel essai : supprimer un dossier déjà vide est un no-op,
    // et tant que l'utilisateur Auth existe encore, le JWT reste valide pour
    // relancer l'appel après un échec partiel. ===
    try {
        for (const bucket of STORAGE_BUCKETS) {
            await deleteUserFolder(serviceClient, bucket, userId);
        }

        const { error: deleteUserError } = await serviceClient.auth.admin.deleteUser(userId);
        if (deleteUserError) {
            throw deleteUserError;
        }

        return new Response(JSON.stringify({ success: true }), { status: 200, headers: jsonHeaders });
    } catch (error) {
        console.error('Erreur fatale Edge Function (Delete Account) :', (error as Error).message);
        return new Response(
            JSON.stringify({
                error: isEn
                    ? "Account deletion failed. Please try again, your data has not been lost."
                    : "La suppression du compte a échoué. Réessaie, tes données n'ont pas été perdues.",
            }),
            { status: 500, headers: jsonHeaders },
        );
    }
})
