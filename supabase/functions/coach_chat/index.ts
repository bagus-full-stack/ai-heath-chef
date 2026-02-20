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

    try {
        // === 1. RECUPERATION DU BODY (Le message et l'historique) ===
        let body;
        try {
            body = await req.json();
        } catch (e) {
            throw new Error("Le corps de la requête est vide ou mal formé.");
        }

        const { message, history } = body;
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
        const systemInstruction = "Tu es Chef Santé, un coach en nutrition expert, empathique et motivant. Tu réponds de manière concise (maximum 3 phrases) et claire. Tu tutoies l'utilisateur et tu l'encourages. Tu ne dois jamais utiliser de balises Markdown complexes, reste en texte simple.";

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