import "jsr:@supabase/functions-js/edge-runtime.d.ts"

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

Deno.serve(async (req) => {
    // === GESTION DU PREFLIGHT (CORS) ===
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
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
            count,
        } = body;

        const suggestionCount = Number.isFinite(count) && count > 0 ? Math.min(count, 10) : 6;
        const goalLabel = GOAL_LABELS[goal as string] ?? GOAL_LABELS.maintain;

        // === 2. VÉRIFICATION CLÉ API GEMINI ===
        const apiKey = Deno.env.get('GEMINI_API_KEY');
        if (!apiKey) {
            console.error("ERREUR CRITIQUE: Clé GEMINI_API_KEY introuvable.");
            throw new Error("Configuration serveur manquante (API Key).");
        }

        // === 3. PRÉPARATION DU PROMPT ===
        const promptText = `
Tu es Chef Santé, un coach en nutrition expert et créatif.
Propose ${suggestionCount} idées de repas variées et réalistes, adaptées à un objectif de ${goalLabel}.
L'utilisateur vise environ ${targetKcal ?? 2200} kcal, ${targetProt ?? 160}g de protéines, ${targetGluc ?? 250}g de glucides et ${targetLip ?? 75}g de lipides par jour au total.
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
