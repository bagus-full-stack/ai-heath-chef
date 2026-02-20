import "jsr:@supabase/functions-js/edge-runtime.d.ts"

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

    try {
        // === 1. RECUPERATION DU BODY (L'image de Flutter) ===
        let body;
        try {
            body = await req.json();
        } catch (e) {
            throw new Error("Le corps de la requête est vide ou mal formé.");
        }

        const { image } = body;
        if (!image) {
            throw new Error("Aucune image n'a été fournie dans la requête.");
        }

        // === 2. VÉRIFICATION CLÉ API GEMINI ===
        const apiKey = Deno.env.get('GEMINI_API_KEY');
        if (!apiKey) {
            console.error("ERREUR CRITIQUE: Clé GEMINI_API_KEY introuvable.");
            throw new Error("Configuration serveur manquante (API Key).");
        }

        // === 3. PRÉPARATION DU PROMPT NUTRITION ===
        const promptText = `
Tu es un nutritionniste expert et un chef cuisinier. 
Ton but est d'analyser la nourriture présente sur cette photo.
Identifie les ingrédients principaux, estime une portion réaliste en grammes (weight), et fournis les macronutriments (kcal, protéines, glucides, lipides) POUR 100 GRAMMES de cet ingrédient.
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
      "lipPer100g": 5.0
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
                    throw new Error("Réponse vide ou sans texte généré.");
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
            throw new Error(`Tous les modèles ont échoué. Dernière erreur : ${lastError}`);
        }

        console.log(`SUCCÈS : Analyse générée avec ${usedModel}`);

        // Nettoyage : On retire les éventuelles balises ```json que l'IA pourrait ajouter
        let jsonString = successData.replace(/```json/gi, '').replace(/```/g, '').trim();

        let parsedJson;
        try {
            parsedJson = JSON.parse(jsonString);
        } catch (e) {
            throw new Error(`Le modèle a répondu avec un JSON invalide : ${jsonString}`);
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