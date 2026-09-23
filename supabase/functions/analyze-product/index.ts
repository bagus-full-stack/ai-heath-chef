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
                        error: `Limite quotidienne atteinte (${dailyLimit}/jour) pour cette fonctionnalité. Réessaie demain.`,
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
                        error: "Cette fonctionnalité IA est très sollicitée aujourd'hui et a atteint sa limite partagée. Réessaie demain.",
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
    "gemma-3-1b-it",
    "gemma-3-4b-it",
    "gemma-3-12b-it",
    "gemma-3-27b-it",
    "gemini-flash-latest",
    "gemini-flash-lite-latest",
    "gemini-pro-latest",
    "gemini-2.5-flash-lite",
    "gemini-3-pro-preview",
    "gemini-3-flash-preview",
    "gemini-1.5-flash" // Sécurité ultime
];

Deno.serve(async (req) => {
    // === GESTION DU PREFLIGHT (CORS) ===
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    // === QUOTA QUOTIDIEN PAR UTILISATEUR ===
    const quota = await checkAndIncrementQuota(req, 'analyze-product', 20, corsHeaders, 500);
    if (!quota.ok) {
        return quota.response!;
    }

    try {
        // === 1. RECUPERATION DU BODY (L'image de Flutter) ===
        let body;
        try {
            body = await req.json();
        } catch (e) {
            throw new Error("Le corps de la requête est vide ou mal formé.");
        }

        const { image, lang } = body;
        if (!image) {
            throw new Error("Aucune image n'a été fournie dans la requête.");
        }
        const langInstruction = lang === 'en'
            ? "Respond with English text values (product name) in the JSON."
            : "Réponds avec des valeurs textuelles en français (nom du produit) dans le JSON.";

        // === 2. VÉRIFICATION CLÉ API GEMINI ===
        const apiKey = Deno.env.get('GEMINI_API_KEY');
        if (!apiKey) {
            console.error("ERREUR CRITIQUE: Clé GEMINI_API_KEY introuvable.");
            throw new Error("Configuration serveur manquante (API Key).");
        }

        // === 3. PRÉPARATION DU PROMPT NUTRITION ===
        // Contrairement à analyze-meal (une assiette avec plusieurs aliments),
        // ici la photo montre un produit emballé : soit son étiquette
        // nutritionnelle (tableau au dos), soit son emballage (face avant).
        const promptText = `
Tu es un nutritionniste expert. Cette photo montre un produit alimentaire emballé — le plus souvent son étiquette nutritionnelle (tableau des valeurs nutritionnelles au dos du produit), parfois juste la face avant de l'emballage.
Lis attentivement le tableau nutritionnel s'il est visible (valeurs "pour 100g" ou "pour 100ml"). S'il n'y a pas de tableau visible, estime au mieux à partir du nom/type de produit visible sur l'emballage.
Retourne UN SEUL ingrédient représentant ce produit dans son ensemble : son nom (marque + nom du produit si visible), sa portion habituelle en grammes (weight — utilise la portion indiquée sur l'étiquette si présente, sinon 100), et ses macronutriments (kcal, protéines, glucides, lipides, fibres, sucres, acides gras saturés) POUR 100 GRAMMES.
Tu DOIS répondre UNIQUEMENT au format JSON strict, sans aucun autre texte autour ni balises markdown.
Le JSON doit avoir cette structure exacte :
{
  "ingredients": [
    {
      "id": "1",
      "name": "Nom du produit",
      "weight": 100,
      "kcalPer100g": 250,
      "protPer100g": 8.0,
      "glucPer100g": 30.0,
      "lipPer100g": 10.0,
      "fiberPer100g": 2.5,
      "sugarPer100g": 12.0,
      "satFatPer100g": 3.0
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
                                    { inlineData: { mimeType: "image/jpeg", data: image } }
                                ]
                            }],
                            generationConfig: {
                                temperature: 0.2
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
                    throw new Error("Réponse vide ou sans texte généré.");
                }

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
            throw new Error(`Tous les modèles ont échoué. Dernière erreur : ${lastError}`);
        }

        console.log(`SUCCÈS : Analyse produit générée avec ${usedModel}`);

        let jsonString = successData.replace(/```json/gi, '').replace(/```/g, '').trim();

        let parsedJson;
        try {
            parsedJson = JSON.parse(jsonString);
        } catch (e) {
            throw new Error(`Le modèle a répondu avec un JSON invalide : ${jsonString}`);
        }

        return new Response(JSON.stringify(parsedJson), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        })

    } catch (error) {
        console.error("Erreur fatale Edge Function (Analyze Product):", error.message);

        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        })
    }
})
