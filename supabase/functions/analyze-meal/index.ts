import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

/**
 * Copie volontaire de la logique de `_shared/quota.ts` plutôt qu'un import
 * relatif : cette fonction est déployée depuis l'éditeur du Dashboard
 * Supabase, qui ne bundle que les fichiers ajoutés explicitement à CETTE
 * fonction et ne voit pas le dossier `_shared` partagé par les autres. La
 * dupliquer ici évite l'erreur "Module not found .../_shared/quota.ts" au
 * déploiement (voir aussi meal-images/index.ts, même pattern).
 */
interface QuotaCheckResult {
    ok: boolean;
    userId?: string;
    response?: Response;
}

/**
 * True si l'appelant doit passer la limite quotidienne PAR UTILISATEUR
 * (admin de confiance, voir migration 0007, ou abonné PRO actif côté
 * RevenueCat). Le disjoncteur GLOBAL protège lui quand même le budget API
 * partagé, même pour ces comptes.
 *
 * Repli sur `false` (donc quota normal appliqué) si `REVENUECAT_SECRET_KEY`
 * n'est pas configuré ou si l'appel à RevenueCat échoue.
 */
async function hasUnlimitedQuota(
    // deno-lint-ignore no-explicit-any
    serviceClient: any,
    userId: string,
): Promise<boolean> {
    const { data: profile } = await serviceClient
        .from("profiles")
        .select("is_admin")
        .eq("user_id", userId)
        .maybeSingle();
    if (profile?.is_admin) {
        return true;
    }

    const revenueCatSecretKey = Deno.env.get("REVENUECAT_SECRET_KEY");
    if (!revenueCatSecretKey) {
        return false;
    }

    try {
        const res = await fetch(`https://api.revenuecat.com/v1/subscribers/${userId}`, {
            headers: { Authorization: `Bearer ${revenueCatSecretKey}` },
        });
        if (!res.ok) {
            return false;
        }
        const body = await res.json();
        const expiresDate = body?.subscriber?.entitlements?.pro?.expires_date;
        return expiresDate === null ||
            (typeof expiresDate === "string" && new Date(expiresDate) > new Date());
    } catch (_) {
        return false;
    }
}

async function checkAndIncrementQuota(
    req: Request,
    functionName: string,
    dailyLimit: number,
    corsHeaders: Record<string, string>,
    globalDailyLimit?: number,
    lang?: string,
): Promise<QuotaCheckResult> {
    const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json" };
    const isEn = lang === "en";

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
        return {
            ok: false,
            response: new Response(
                JSON.stringify({ error: isEn ? "Authentication required." : "Authentification requise." }),
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
                JSON.stringify({ error: isEn ? "Invalid authentication." : "Authentification invalide." }),
                { status: 401, headers: jsonHeaders },
            ),
        };
    }
    const userId = userData.user.id;
    const serviceClient = createClient(supabaseUrl, serviceRoleKey);

    if (!(await hasUnlimitedQuota(serviceClient, userId))) {
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
                        error: isEn
                            ? `Daily limit reached (${dailyLimit}/day) for this feature. Try again tomorrow.`
                            : `Limite quotidienne atteinte (${dailyLimit}/jour) pour cette fonctionnalité. Réessaie demain.`,
                    }),
                    { status: 429, headers: jsonHeaders },
                ),
            };
        }
    }

    if (globalDailyLimit !== undefined) {
        const { data: globalAllowed, error: globalQuotaError } = await serviceClient.rpc(
            "increment_global_api_usage",
            { p_function_name: functionName, p_daily_limit: globalDailyLimit },
        );

        if (globalQuotaError) {
            console.error(`Erreur quota global (${functionName}) :`, globalQuotaError.message);
        } else if (!globalAllowed) {
            return {
                ok: false,
                response: new Response(
                    JSON.stringify({
                        error: isEn
                            ? "This AI feature is in high demand today and has reached its shared limit. Try again tomorrow."
                            : "Cette fonctionnalité IA est très sollicitée aujourd'hui et a atteint sa limite partagée. Réessaie demain.",
                    }),
                    { status: 429, headers: jsonHeaders },
                ),
            };
        }
    }

    return { ok: true, userId };
}

// 1. Headers CORS complets
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// 2. Liste de priorité des modèles
const MODELS = [
    "gemini-2.5-flash",
    "gemini-2.5-pro",
    "gemini-2.0-flash-exp",
    "gemini-2.0-flash",
    "gemini-2.0-flash-001",
    "gemini-2.0-flash-lite-001",
    "gemini-2.0-flash-lite",
    "gemini-2.0-flash-lite-preview-02-05",
    "gemini-2.0-flash-lite-preview",
    "gemini-exp-1206",
    "gemini-2.5-flash-preview-tts",
    "gemini-2.5-pro-preview-tts",
    "gemma-3-1b-it",
    "gemma-3-4b-it",
    "gemma-3-12b-it",
    "gemma-3-27b-it",
    "gemma-3n-e4b-it",
    "gemma-3n-e2b-it",
    "gemini-flash-latest",
    "gemini-flash-lite-latest",
    "gemini-pro-latest",
    "gemini-2.5-flash-lite",
    "gemini-2.5-flash-image-preview",
    "gemini-2.5-flash-image",
    "gemini-2.5-flash-preview-09-2025",
    "gemini-2.5-flash-lite-preview-09-2025",
    "gemini-3-pro-preview",
    "gemini-3-flash-preview",
    "gemini-3-pro-image-preview",
    "nano-banana-pro-preview",
    "gemini-1.5-flash" // Sécurité ultime
];

Deno.serve(async (req) => {
    // === GESTION DU PREFLIGHT (CORS) ===
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    // === 1. RECUPERATION DU BODY (L'image de Flutter), avant le quota pour connaître la langue ===
    let body: Record<string, unknown> = {};
    let bodyParseError = false;
    try {
        body = await req.json();
    } catch (_e) {
        bodyParseError = true;
    }
    const lang = body?.lang === 'en' ? 'en' : 'fr';
    const isEn = lang === 'en';

    // === QUOTA QUOTIDIEN PAR UTILISATEUR ===
    const quota = await checkAndIncrementQuota(req, 'analyze-meal', 20, corsHeaders, 500, lang);
    if (!quota.ok) {
        return quota.response!;
    }

    try {
        if (bodyParseError) {
            throw new Error(isEn ? "The request body is empty or malformed." : "Le corps de la requête est vide ou mal formé.");
        }

        const { image } = body;
        if (!image) {
            throw new Error(isEn ? "No image was provided in the request." : "Aucune image n'a été fournie dans la requête.");
        }
        const langInstruction = isEn
            ? "Respond with English text values (ingredient names) in the JSON."
            : "Réponds avec des valeurs textuelles en français (noms des ingrédients) dans le JSON.";

        // === 2. VÉRIFICATION CLÉ API GEMINI ===
        const apiKey = Deno.env.get('GEMINI_API_KEY');
        if (!apiKey) {
            console.error("ERREUR CRITIQUE: Clé GEMINI_API_KEY introuvable.");
            throw new Error(isEn ? "Missing server configuration (API Key)." : "Configuration serveur manquante (API Key).");
        }

        // === 3. PRÉPARATION DU PROMPT NUTRITION ===
        const promptText = `
Tu es un nutritionniste expert et un chef cuisinier. 
Ton but est d'analyser la nourriture présente sur cette photo.
Identifie les ingrédients principaux, estime une portion réaliste en grammes (weight), et fournis les macronutriments (kcal, protéines, glucides, lipides, fibres, sucres, acides gras saturés) POUR 100 GRAMMES de cet ingrédient.
Tu DOIS répondre UNIQUEMENT au format JSON strict, sans aucun autre texte autour ni balises markdown.
Le JSON doit avoir cette structure exacte :
{
  "ingredients": [
    {
      "id": "1",
      "name": "Nom de l'ingrédient",
      "weight": 150,
      "kcalPer100g": 120,
      "protPer100g": 10.5,
      "glucPer100g": 2.0,
      "lipPer100g": 5.0,
      "fiberPer100g": 1.2,
      "sugarPer100g": 1.5,
      "satFatPer100g": 2.0
    }
  ]
}
${langInstruction}`;

        // === 4. BOUCLE DE TENTATIVES (FALLBACK) ===
        let lastError = null;
        let successData = null;
        let usedModel = "";

        for (const modelName of MODELS) {
            try {
                console.log(`Tentative avec le modèle : ${modelName}...`);

                const response = await fetch(
                    `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`,
                    {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            contents: [{
                                parts: [
                                    { text: promptText },
                                    // Gemini attend l'image dans ce format spécifique "inlineData"
                                    { inlineData: { mimeType: "image/jpeg", data: image } }
                                ]
                            }],
                            generationConfig: {
                                temperature: 0.2 // Température basse pour avoir un JSON consistant
                            }
                        })
                    }
                );

                const data = await response.json();

                if (data.error) {
                    console.warn(`Échec ${modelName} : ${data.error.message}`);
                    lastError = data.error.message;
                    continue;
                }

                const textResponse = data.candidates?.[0]?.content?.parts?.[0]?.text;
                if (!textResponse) {
                    throw new Error(isEn ? "Empty response or no text generated." : "Réponse vide ou sans texte généré.");
                }

                // Si ça marche, on sauvegarde le texte et on casse la boucle !
                successData = textResponse;
                usedModel = modelName;
                break;

            } catch (err) {
                console.warn(`Erreur réseau avec ${modelName} : ${err.message}`);
                lastError = err.message;
                continue;
            }
        }

        // === 5. PARSING DU RÉSULTAT FINAL ===
        if (!successData) {
            throw new Error(
                isEn
                    ? `All models failed. Last error: ${lastError}`
                    : `Tous les modèles ont échoué. Dernière erreur : ${lastError}`,
            );
        }

        console.log(`SUCCÈS : Analyse générée avec ${usedModel}`);

        // Nettoyage : On retire les éventuelles balises ```json que l'IA pourrait ajouter
        let jsonString = successData.replace(/```json/gi, '').replace(/```/g, '').trim();

        let parsedJson;
        try {
            parsedJson = JSON.parse(jsonString);
        } catch (e) {
            throw new Error(
                isEn
                    ? `The model replied with invalid JSON: ${jsonString}`
                    : `Le modèle a répondu avec un JSON invalide : ${jsonString}`,
            );
        }

        // On renvoie le JSON propre à notre application Flutter
        return new Response(JSON.stringify(parsedJson), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        })

    } catch (error) {
        console.error("Erreur fatale Edge Function:", error.message);

        // On renvoie l'erreur au format JSON pour que Flutter puisse l'afficher dans le SnackBar
        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        })
    }
})