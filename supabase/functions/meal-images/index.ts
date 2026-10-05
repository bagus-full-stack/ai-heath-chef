import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { checkAndIncrementQuota } from "../_shared/quota.ts"
import { corsHeaders } from "../_shared/cors.ts"

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

// Usage réel côté app (voir meal_suggestions_provider.dart: count=6,
// pantry_recipes_provider.dart: count=3, ai_service.dart#getDishImage: 1) :
// jamais plus de 6 images demandées en un seul appel. Au-delà, on tronque
// plutôt que de rejeter l'appel (ces entrées supplémentaires ne peuvent
// venir que d'un usage anormal, pas d'un cas légitime de l'app).
const MAX_MEALS_PER_CALL = 6;
const MAX_TITLE_LENGTH = 200;
// Au lieu d'un Promise.all illimité (autant d'appels Cloudflare/Pollinations
// simultanés que d'entrées), on traite par lots pour bornir la charge
// instantanée sur ces fournisseurs gratuits.
const MAX_CONCURRENT = 3;
// Cloudflare Workers AI (FLUX.1 schnell) est gratuit jusqu'à ~10 000
// Neurons/jour, soit ~100 images à 8 steps (voir generateWithCloudflare
// ci-dessus) — budget partagé par TOUS les utilisateurs de l'app. Le
// quota global ci-dessous compte désormais le nombre d'images réellement
// demandées (après troncature à MAX_MEALS_PER_CALL), pas le nombre
// d'appels HTTP, pour rester cohérent avec ce budget.
const GLOBAL_DAILY_IMAGE_LIMIT = 100;

function chunk<T>(items: T[], size: number): T[][] {
    const out: T[][] = [];
    for (let i = 0; i < items.length; i += size) {
        out.push(items.slice(i, i + size));
    }
    return out;
}

Deno.serve(async (req) => {
    // === GESTION DU PREFLIGHT (CORS) ===
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    const jsonHeaders = { ...corsHeaders, 'Content-Type': 'application/json' };

    // === 1. RECUPERATION DU BODY, avant le quota pour connaître la langue et
    // le nombre d'images réellement demandées (voir GLOBAL_DAILY_IMAGE_LIMIT) ===
    let body: Record<string, unknown> = {};
    let bodyParseError = false;
    try {
        body = await req.json();
    } catch (_e) {
        bodyParseError = true;
    }
    const lang = body?.lang === 'en' ? 'en' : 'fr';
    const isEn = lang === 'en';

    if (bodyParseError) {
        return new Response(
            JSON.stringify({ error: isEn ? "The request body is empty or malformed." : "Le corps de la requête est vide ou mal formé." }),
            { status: 400, headers: jsonHeaders },
        );
    }

    // === 2. VALIDATION ET PLAFONNEMENT DU TABLEAU `meals` ===
    // On ignore silencieusement les entrées invalides (titre manquant/trop
    // long) et on tronque à MAX_MEALS_PER_CALL plutôt que de rejeter tout
    // l'appel : un seul titre malformé ou un tableau trop long ne doit pas
    // casser la génération des images par ailleurs valides.
    const rawMeals = Array.isArray(body?.meals) ? body.meals : [];
    const meals = rawMeals
        .filter((meal: unknown): meal is { title: string; description?: string } => {
            if (meal === null || typeof meal !== 'object') return false;
            const title = (meal as Record<string, unknown>).title;
            const description = (meal as Record<string, unknown>).description;
            if (typeof title !== 'string' || title.length === 0 || title.length > MAX_TITLE_LENGTH) {
                return false;
            }
            if (description !== undefined && (typeof description !== 'string' || description.length > MAX_TITLE_LENGTH)) {
                return false;
            }
            return true;
        })
        .slice(0, MAX_MEALS_PER_CALL);

    if (meals.length === 0) {
        return new Response(JSON.stringify({ images: [] }), {
            headers: jsonHeaders,
            status: 200,
        });
    }

    // === QUOTA : PAR UTILISATEUR (1/appel) + GLOBAL (1/image, budget Cloudflare) ===
    const quota = await checkAndIncrementQuota(
        req,
        'meal-images',
        10,
        corsHeaders,
        GLOBAL_DAILY_IMAGE_LIMIT,
        lang,
        meals.length,
    );
    if (!quota.ok) {
        return quota.response!;
    }

    try {
        const cfAccountId = Deno.env.get('CLOUDFLARE_ACCOUNT_ID') ?? null;
        const cfApiToken = Deno.env.get('CLOUDFLARE_API_TOKEN') ?? null;
        const pollinationsToken = Deno.env.get('POLLINATIONS_TOKEN') ?? null;
        const models = await fetchAvailableModels(pollinationsToken);

        // Génération par lots de MAX_CONCURRENT, avec un décalage entre
        // chaque requête d'un même lot. Cloudflare Workers AI n'a pas la
        // limite de débit serrée de Pollinations, donc un décalage minime
        // suffit quand il est configuré ; sinon on reste prudent pour
        // l'offre anonyme Pollinations (~1 req/15s, voir APIDOCS.md).
        const staggerMs = cfAccountId && cfApiToken ? 300 : pollinationsToken ? 1200 : 3000;
        const images: (string | null)[] = [];
        for (const batch of chunk(meals, MAX_CONCURRENT)) {
            const batchImages = await Promise.all(
                batch.map((meal, indexInBatch) =>
                    new Promise<string | null>((resolve) => {
                        setTimeout(async () => {
                            resolve(await generateMealImage(
                                meal.title,
                                meal.description ?? '',
                                cfAccountId,
                                cfApiToken,
                                pollinationsToken,
                                models,
                            ));
                        }, indexInBatch * staggerMs);
                    })
                ),
            );
            images.push(...batchImages);
        }

        return new Response(JSON.stringify({ images }), {
            headers: jsonHeaders,
            status: 200,
        });
    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        console.error("Erreur fatale Edge Function (Meal Images):", message);
        return new Response(JSON.stringify({ error: isEn ? "Image generation temporarily failed. Please try again later." : "La génération d'images a temporairement échoué. Réessaie plus tard." }), {
            headers: jsonHeaders,
            status: 400,
        });
    }
})
