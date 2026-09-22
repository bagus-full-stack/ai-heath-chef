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
    "gemini-3-pro-preview",
    "gemini-3-flash-preview",
    "nano-banana-pro-preview",
    "gemini-1.5-flash" // Sécurité ultime (le plus stable)
];

Deno.serve(async (req) => {
    // === GESTION DU PREFLIGHT (CORS) ===
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    // === QUOTA QUOTIDIEN PAR UTILISATEUR ===
    const quota = await checkAndIncrementQuota(req, 'coach-chat', 50, corsHeaders, 1000);
    if (!quota.ok) {
        return quota.response!;
    }

    try {
        // === 1. RECUPERATION DU BODY (Le message et l'historique) ===
        let body;
        try {
            body = await req.json();
        } catch (e) {
            throw new Error("Le corps de la requête est vide ou mal formé.");
        }

        const { message, history, coachTone, dietType, allergies } = body;
        if (!message) {
            throw new Error("Aucun message n'a été fourni dans la requête.");
        }

        // === 2. VÉRIFICATION CLÉ API GEMINI ===
        const apiKey = Deno.env.get('GEMINI_API_KEY');
        if (!apiKey) {
            console.error("ERREUR CRITIQUE: Clé GEMINI_API_KEY introuvable.");
            throw new Error("Configuration serveur manquante (API Key).");
        }

        // === 3. PRÉPARATION DES INSTRUCTIONS SYSTÈME ===
        const TONE_INSTRUCTIONS: Record<string, string> = {
            motivant: "Tu es empathique et motivant : tu encourages l'utilisateur et le pousses gentiment à avancer.",
            bienveillant: "Tu es calme, doux et bienveillant : tu rassures l'utilisateur, sans jamais le juger sur ses écarts.",
            direct: "Tu es direct et concis : tu vas droit au but avec des conseils actionnables, sans détour ni fioriture.",
            humoristique: "Tu es léger et plein d'humour, tout en restant utile et sérieux sur le fond nutritionnel.",
        };
        const toneInstruction = TONE_INSTRUCTIONS[coachTone as string] ?? TONE_INSTRUCTIONS.motivant;

        const DIET_LABELS: Record<string, string> = {
            vegetarian: "végétarien (sans viande ni poisson)",
            vegan: "végétalien (sans aucun produit d'origine animale)",
            pescetarian: "pescétarien (sans viande, poisson autorisé)",
            halal: "halal",
            kosher: "kasher",
        };
        const dietLabel = DIET_LABELS[dietType as string];
        const allergyList: string[] = Array.isArray(allergies)
            ? allergies.filter((a) => typeof a === 'string' && a.trim().length > 0)
            : [];

        let dietaryNote = "";
        if (dietLabel) {
            dietaryNote += ` L'utilisateur suit un régime ${dietLabel} : ne recommande jamais un aliment qui l'enfreint.`;
        }
        if (allergyList.length > 0) {
            dietaryNote += ` L'utilisateur est allergique/intolérant à : ${allergyList.join(', ')}. Ne recommande jamais ces aliments.`;
        }

        const systemInstruction = `Tu es AI Health Chef, un coach en nutrition expert. ${toneInstruction} Tu réponds de manière concise (maximum 3 phrases) et claire. Tu tutoies l'utilisateur.${dietaryNote} Tu ne dois jamais utiliser de balises Markdown complexes, reste en texte simple.`;

        // On prépare le payload exact attendu par l'API REST de Google
        // On combine l'historique (s'il y en a) avec le nouveau message
        const contents = [];
        if (history && Array.isArray(history)) {
            contents.push(...history);
        }
        contents.push({ role: "user", parts: [{ text: message }] });


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
                            systemInstruction: { parts: [{ text: systemInstruction }] },
                            contents: contents,
                            generationConfig: {
                                temperature: 0.7 // Une température moyenne pour avoir des réponses naturelles et variées
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
            throw new Error(`Tous les modèles de chat ont échoué. Dernière erreur : ${lastError}`);
        }

        console.log(`SUCCÈS : Réponse générée avec ${usedModel}`);

        // On renvoie la réponse de l'IA à l'application Flutter
        return new Response(JSON.stringify({ reply: successData }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        })

    } catch (error) {
        console.error("Erreur fatale Edge Function (Coach):", error.message);

        // On renvoie l'erreur au format JSON
        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        })
    }
})