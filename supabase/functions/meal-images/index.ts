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

function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

function buildFoodPrompt(title: string, description: string): string {
    return (
        `Professional food photography of ${title}, ${description}. ` +
        `Michelin-star restaurant plating on a clean plate, soft natural window light, ` +
        `shallow depth of field, macro detail, vibrant fresh ingredients, shot on DSLR, ` +
        `4K, appetizing, food magazine cover quality.`
    );
}

/**
 * Génère l'illustration via Cloudflare Workers AI (FLUX.1 [schnell]) : la
 * meilleure qualité disponible ici, et gratuite jusqu'à ~10 000 Neurons/jour
 * (~100 images à 8 steps, partagés entre tous les utilisateurs de l'app) —
 * aucun risque de facturation tant que le compte Cloudflare reste sur le
 * plan gratuit. Retourne `null` si les secrets ne sont pas configurés, si le
 * quota gratuit du jour est épuisé, ou en cas d'erreur — l'appelant retombe
 * alors sur Pollinations.
 */
async function generateWithCloudflare(
    prompt: string,
    accountId: string,
    apiToken: string,
): Promise<string | null> {
    const url = `https://api.cloudflare.com/client/v4/accounts/${accountId}/ai/run/@cf/black-forest-labs/flux-1-schnell`;

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiToken}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ prompt, steps: 8 }),
        });

        if (!response.ok) {
            console.warn(`Cloudflare Workers AI : HTTP ${response.status} pour le prompt "${prompt.slice(0, 40)}..."`);
            return null;
        }

        const data = await response.json();
        // L'API Cloudflare v4 enveloppe généralement la réponse dans
        // `result`, mais on accepte aussi un champ `image` à la racine par
        // robustesse face à d'éventuelles variations de format.
        const base64 = data?.result?.image ?? data?.image;
        if (typeof base64 !== 'string' || base64.length === 0) {
            console.warn('Cloudflare Workers AI : réponse sans image exploitable.', JSON.stringify(data).slice(0, 200));
            return null;
        }
        return `data:image/jpeg;base64,${base64}`;
    } catch (err) {
        console.warn('Cloudflare Workers AI : erreur réseau —', (err as Error).message);
        return null;
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
async function generateWithPollinations(
    prompt: string,
    token: string | null,
    models: string[],
    seed: number,
): Promise<string | null> {
    const headers: Record<string, string> = {};
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }

    let lastError = '';
    for (const modelName of models) {
        const url =
            `https://image.pollinations.ai/prompt/${encodeURIComponent(prompt)}` +
            `?width=768&height=512&nologo=true&enhance=true&seed=${seed}` +
            `&model=${modelName}&referrer=aihealthchef.app`;

        // Une seule nouvelle tentative sur un 429 (quota Pollinations atteint) :
        // au-delà, on préfère passer au modèle suivant plutôt que de faire
        // attendre l'utilisateur indéfiniment.
        for (let attempt = 0; attempt < 2; attempt++) {
            try {
                const response = await fetch(url, { headers });
                if (response.status === 429 && attempt === 0) {
                    lastError = 'HTTP 429 (limite de débit), nouvelle tentative...';
                    console.warn(`Modèle "${modelName}" : ${lastError}`);
                    await sleep(4000);
                    continue;
                }
                if (!response.ok) {
                    lastError = `HTTP ${response.status}`;
                    console.warn(`Échec modèle "${modelName}" : ${lastError}`);
                    break;
                }
                const contentType = response.headers.get('content-type') ?? '';
                if (!contentType.startsWith('image/')) {
                    lastError = `Réponse non-image (${contentType || 'type inconnu'})`;
                    console.warn(`Échec modèle "${modelName}" : ${lastError}`);
                    break;
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
                console.warn(`Erreur réseau modèle "${modelName}" :`, lastError);
                break;
            }
        }
    }

    console.warn(`Tous les modèles Pollinations ont échoué. Dernière erreur : ${lastError}`);
    return null;
}

/**
 * Génère l'illustration d'un repas en cascade : Cloudflare Workers AI
 * (FLUX.1 [schnell], meilleure qualité, gratuit dans la limite du quota
 * quotidien Cloudflare) en premier si les secrets CLOUDFLARE_ACCOUNT_ID et
 * CLOUDFLARE_API_TOKEN sont configurés, sinon/en cas d'échec Pollinations
 * (toujours gratuit, qualité inférieure mais sans limite de quota mensuel).
 */
async function generateMealImage(
    title: string,
    description: string,
    cfAccountId: string | null,
    cfApiToken: string | null,
    pollinationsToken: string | null,
    pollinationsModels: string[],
): Promise<string | null> {
    const prompt = buildFoodPrompt(title, description);

    if (cfAccountId && cfApiToken) {
        const cfImage = await generateWithCloudflare(prompt, cfAccountId, cfApiToken);
        if (cfImage) return cfImage;
        console.warn(`Cloudflare a échoué pour "${title}", repli sur Pollinations.`);
    }

    const seed = seedFromTitle(title);
    return generateWithPollinations(prompt, pollinationsToken, pollinationsModels, seed);
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

        const cfAccountId = Deno.env.get('CLOUDFLARE_ACCOUNT_ID') ?? null;
        const cfApiToken = Deno.env.get('CLOUDFLARE_API_TOKEN') ?? null;
        const pollinationsToken = Deno.env.get('POLLINATIONS_TOKEN') ?? null;
        const models = await fetchAvailableModels(pollinationsToken);

        // Génération en parallèle, avec un décalage entre chaque requête.
        // Cloudflare Workers AI n'a pas la limite de débit serrée de
        // Pollinations, donc un décalage minime suffit quand il est
        // configuré ; sinon on reste prudent pour l'offre anonyme
        // Pollinations (~1 req/15s, voir APIDOCS.md).
        const staggerMs = cfAccountId && cfApiToken ? 300 : pollinationsToken ? 1200 : 3000;
        const images = await Promise.all(
            meals.map((meal: { title?: string; description?: string }, index: number) =>
                new Promise<string | null>((resolve) => {
                    setTimeout(async () => {
                        const title = typeof meal?.title === 'string' ? meal.title : 'Repas';
                        const description = typeof meal?.description === 'string' ? meal.description : '';
                        resolve(await generateMealImage(
                            title,
                            description,
                            cfAccountId,
                            cfApiToken,
                            pollinationsToken,
                            models,
                        ));
                    }, index * staggerMs);
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
