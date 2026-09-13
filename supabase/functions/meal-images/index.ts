import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

// 1. Headers CORS complets
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

/**
 * Copie volontaire de la logique de `_shared/quota.ts` (voir les autres
 * Edge Functions du projet) plutôt qu'un import relatif : cette fonction est
 * déployée depuis l'éditeur du Dashboard Supabase, qui ne bundle que les
 * fichiers ajoutés explicitement à CETTE fonction et ne voit pas le dossier
 * `_shared` partagé par les autres. La dupliquer ici évite l'erreur
 * "Module not found .../_shared/quota.ts" au déploiement.
 */
interface QuotaCheckResult {
    ok: boolean;
    userId?: string;
    response?: Response;
}

async function checkAndIncrementQuota(
    req: Request,
    functionName: string,
    dailyLimit: number,
    corsHeaders: Record<string, string>,
): Promise<QuotaCheckResult> {
    const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json" };

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
        return {
            ok: false,
            response: new Response(
                JSON.stringify({ error: "Authentification requise." }),
                { status: 401, headers: jsonHeaders },
            ),
        };
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const userClient = createClient(supabaseUrl, anonKey, {
        global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData?.user) {
        return {
            ok: false,
            response: new Response(
                JSON.stringify({ error: "Authentification invalide." }),
                { status: 401, headers: jsonHeaders },
            ),
        };
    }
    const userId = userData.user.id;

    const serviceClient = createClient(supabaseUrl, serviceRoleKey);
    const { data: allowed, error: quotaError } = await serviceClient.rpc(
        "increment_api_usage",
        { p_user_id: userId, p_function_name: functionName, p_daily_limit: dailyLimit },
    );

    if (quotaError) {
        console.error(`Erreur quota (${functionName}) :`, quotaError.message);
        return { ok: true, userId };
    }

    if (!allowed) {
        return {
            ok: false,
            response: new Response(
                JSON.stringify({
                    error: `Limite quotidienne atteinte (${dailyLimit}/jour) pour cette fonctionnalité. Réessaie demain.`,
                }),
                { status: 429, headers: jsonHeaders },
            ),
        };
    }

    return { ok: true, userId };
}

/**
 * Hash simple et déterministe (FNV-1a) d'une chaîne, utilisé comme seed
 * Pollinations : un même titre de repas produit toujours la même image
 * (cohérence visuelle d'un jour à l'autre pour un plat identique), au lieu
 * d'une image aléatoire à chaque génération.
 */
function seedFromTitle(title: string): number {
    let hash = 0x811c9dc5;
    for (let i = 0; i < title.length; i++) {
        hash ^= title.charCodeAt(i);
        hash = Math.imul(hash, 0x01000193);
    }
    return Math.abs(hash) % 1_000_000;
}

// Liste de secours si l'introspection des modèles disponibles (voir
// fetchAvailableModels) échoue : modèles historiquement documentés par
// Pollinations pour la génération d'image texte -> image.
const FALLBACK_MODELS = ["flux", "turbo", "sana", "stable-diffusion"];

/**
 * Récupère la liste des modèles d'image actuellement proposés par
 * Pollinations pour le niveau d'accès de l'appelant (anonyme, ou le tien si
 * POLLINATIONS_TOKEN est configuré — les modèles avancés ne sont visibles
 * qu'avec un compte). Repli sur [FALLBACK_MODELS] si l'appel échoue, pour ne
 * jamais bloquer la génération d'images sur un problème d'introspection.
 */
async function fetchAvailableModels(token: string | null): Promise<string[]> {
    try {
        const headers: Record<string, string> = {};
        if (token) {
            headers['Authorization'] = `Bearer ${token}`;
        }
        const response = await fetch('https://image.pollinations.ai/models', { headers });
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        const data = await response.json();
        const models = Array.isArray(data) ? data.filter((m) => typeof m === 'string') : [];
        if (models.length === 0) {
            throw new Error('Liste de modèles vide.');
        }
        return models;
    } catch (err) {
        console.warn(
            'Impossible de récupérer les modèles Pollinations disponibles, repli sur la liste par défaut :',
            (err as Error).message,
        );
        return FALLBACK_MODELS;
    }
}

/**
 * Génère l'illustration d'un repas via Pollinations.ai et la renvoie en data
 * URI base64. On utilise le token du compte (secret POLLINATIONS_TOKEN) s'il
 * est configuré — accès plus rapide et sans watermark — sinon on retombe
 * automatiquement sur l'offre anonyme (gratuite, sans compte). Le token
 * n'est JAMAIS exposé côté client : Pollinations recommande explicitement
 * de ne l'utiliser que côté serveur (voir APIDOCS.md).
 *
 * Comme pour les autres Edge Functions IA du projet (voir MODELS dans
 * coach-chat/meal-suggestions), on essaie chaque modèle disponible dans
 * l'ordre jusqu'à ce qu'un fonctionne, au lieu de dépendre d'un seul modèle
 * qui pourrait être temporairement indisponible ou hors du niveau d'accès.
 */
async function generateMealImage(
    title: string,
    description: string,
    token: string | null,
    models: string[],
): Promise<string | null> {
    const prompt =
        `Professional appetizing food photography of ${title}. ${description}. ` +
        `Restaurant plating, natural light, shallow depth of field, high detail.`;
    const seed = seedFromTitle(title);
    const headers: Record<string, string> = {};
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }

    let lastError = '';
    for (const modelName of models) {
        const url =
            `https://image.pollinations.ai/prompt/${encodeURIComponent(prompt)}` +
            `?width=640&height=420&nologo=true&seed=${seed}&model=${modelName}&referrer=aihealthchef.app`;

        try {
            const response = await fetch(url, { headers });
            if (!response.ok) {
                lastError = `HTTP ${response.status}`;
                console.warn(`Échec modèle "${modelName}" pour "${title}" : ${lastError}`);
                continue;
            }
            const contentType = response.headers.get('content-type') ?? '';
            if (!contentType.startsWith('image/')) {
                lastError = `Réponse non-image (${contentType || 'type inconnu'})`;
                console.warn(`Échec modèle "${modelName}" pour "${title}" : ${lastError}`);
                continue;
            }
            const bytes = new Uint8Array(await response.arrayBuffer());
            let binary = '';
            for (let i = 0; i < bytes.length; i++) {
                binary += String.fromCharCode(bytes[i]);
            }
            const base64 = btoa(binary);
            return `data:${contentType};base64,${base64}`;
        } catch (err) {
            lastError = (err as Error).message;
            console.warn(`Erreur réseau modèle "${modelName}" pour "${title}" :`, lastError);
            continue;
        }
    }

    console.warn(`Tous les modèles d'image ont échoué pour "${title}". Dernière erreur : ${lastError}`);
    return null;
}

Deno.serve(async (req) => {
    // === GESTION DU PREFLIGHT (CORS) ===
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    // === QUOTA QUOTIDIEN PAR UTILISATEUR ===
    const quota = await checkAndIncrementQuota(req, 'meal-images', 10, corsHeaders);
    if (!quota.ok) {
        return quota.response!;
    }

    try {
        let body;
        try {
            body = await req.json();
        } catch (e) {
            throw new Error("Le corps de la requête est vide ou mal formé.");
        }

        const meals = Array.isArray(body?.meals) ? body.meals : [];
        if (meals.length === 0) {
            return new Response(JSON.stringify({ images: [] }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 200,
            });
        }

        const token = Deno.env.get('POLLINATIONS_TOKEN') ?? null;
        const models = await fetchAvailableModels(token);

        // Génération en parallèle, avec un léger décalage pour rester
        // raisonnable vis-à-vis des limites de débit de Pollinations
        // (surtout sans token, plus limité).
        const images = await Promise.all(
            meals.map((meal: { title?: string; description?: string }, index: number) =>
                new Promise<string | null>((resolve) => {
                    setTimeout(async () => {
                        const title = typeof meal?.title === 'string' ? meal.title : 'Repas';
                        const description = typeof meal?.description === 'string' ? meal.description : '';
                        resolve(await generateMealImage(title, description, token, models));
                    }, index * 400);
                })
            ),
        );

        return new Response(JSON.stringify({ images }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        });
    } catch (error) {
        console.error("Erreur fatale Edge Function (Meal Images):", (error as Error).message);
        return new Response(JSON.stringify({ error: (error as Error).message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        });
    }
})
