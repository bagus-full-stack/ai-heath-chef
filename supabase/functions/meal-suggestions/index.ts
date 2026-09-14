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

// 2. Liste de priorité des modèles (Les plus récents/performants en premier)
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
    "gemini-1.5-flash" // Sécurité ultime (le plus stable)
];

const GOAL_LABELS: Record<string, string> = {
    loseWeight: "perte de poids (repas riches en protéines, rassasiants, modérés en calories)",
    gainMuscle: "prise de muscle (repas riches en protéines et en calories)",
    maintain: "maintien du poids (repas équilibrés)",
};

const DIET_LABELS: Record<string, string> = {
    vegetarian: "végétarien (sans viande ni poisson)",
    vegan: "végétalien (sans aucun produit d'origine animale)",
    pescetarian: "pescétarien (sans viande, poisson autorisé)",
    halal: "halal",
    kosher: "kasher",
};

Deno.serve(async (req) => {
    // === GESTION DU PREFLIGHT (CORS) ===
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    // === QUOTA QUOTIDIEN PAR UTILISATEUR ===
    const quota = await checkAndIncrementQuota(req, 'meal-suggestions', 10, corsHeaders, 300);
    if (!quota.ok) {
        return quota.response!;
    }

    try {
        // === 1. RECUPERATION DU BODY ===
        let body;
        try {
            body = await req.json();
        } catch (e) {
            throw new Error("Le corps de la requête est vide ou mal formé.");
        }

        const {
            goal,
            targetKcal,
            targetProt,
            targetGluc,
            targetLip,
            dietType,
            allergies,
            count,
        } = body;

        const suggestionCount = Number.isFinite(count) && count > 0 ? Math.min(count, 10) : 6;
        const goalLabel = GOAL_LABELS[goal as string] ?? GOAL_LABELS.maintain;
        const dietLabel = DIET_LABELS[dietType as string];
        const allergyList: string[] = Array.isArray(allergies)
            ? allergies.filter((a) => typeof a === 'string' && a.trim().length > 0)
            : [];

        // === 2. VÉRIFICATION CLÉ API GEMINI ===
        const apiKey = Deno.env.get('GEMINI_API_KEY');
        if (!apiKey) {
            console.error("ERREUR CRITIQUE: Clé GEMINI_API_KEY introuvable.");
            throw new Error("Configuration serveur manquante (API Key).");
        }

        // === 3. PRÉPARATION DU PROMPT ===
        const constraintLines = [];
        if (dietLabel) {
            constraintLines.push(`Régime à respecter STRICTEMENT : ${dietLabel}.`);
        }
        if (allergyList.length > 0) {
            constraintLines.push(
                `Allergies/intolérances à éviter ABSOLUMENT, dans aucun ingrédient : ${allergyList.join(', ')}.`,
            );
        }
        const constraintsText = constraintLines.length > 0 ? `\n${constraintLines.join('\n')}` : '';

        const promptText = `
Tu es Chef Santé, un coach en nutrition expert et créatif.
Propose ${suggestionCount} idées de repas variées et réalistes, adaptées à un objectif de ${goalLabel}.
L'utilisateur vise environ ${targetKcal ?? 2200} kcal, ${targetProt ?? 160}g de protéines, ${targetGluc ?? 250}g de glucides et ${targetLip ?? 75}g de lipides par jour au total.${constraintsText}
Varie les moments de la journée (Petit-déjeuner, Déjeuner, Dîner, Collation) et les types de plats — ne propose jamais deux fois le même plat.
Tu DOIS répondre UNIQUEMENT avec un JSON strict, sans balises markdown ni texte autour, au format exact suivant :
{
  "suggestions": [
    {
      "timeSlot": "Déjeuner",
      "title": "Nom court et appétissant du plat",
      "kcal": 380,
      "prot": 32,
      "gluc": 25,
      "lip": 18,
      "description": "Une phrase courte expliquant pourquoi ce repas convient à l'objectif."
    }
  ]
}`;

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
                            contents: [{ parts: [{ text: promptText }] }],
                            generationConfig: {
                                temperature: 0.8 // Un peu de créativité pour varier les suggestions
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
                    console.warn(`Échec ${modelName} : Réponse vide.`);
                    continue;
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

        console.log(`SUCCÈS : Suggestions générées avec ${usedModel}`);

        // Nettoyage : on retire les éventuelles balises ```json que l'IA pourrait ajouter
        const jsonString = successData.replace(/```json/gi, '').replace(/```/g, '').trim();

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
        console.error("Erreur fatale Edge Function (Meal Suggestions):", error.message);

        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        })
    }
})
