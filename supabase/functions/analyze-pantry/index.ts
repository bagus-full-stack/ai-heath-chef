import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { checkAndIncrementQuota } from "../_shared/quota.ts"
import { corsHeaders } from "../_shared/cors.ts"
import { HttpError } from "../_shared/errors.ts"
import { callGeminiWithFallback } from "../_shared/gemini.ts"

// Cette fonction est par ailleurs une quasi-copie de analyze-meal/index.ts :
// même contrat JSON de sortie ({ ingredients: [...] }) pour rester
// compatible avec le parsing existant de AIService._analyzeImage côté
// Flutter, seul le prompt change (photo de frigo/placard : on identifie un
// inventaire d'ingrédients disponibles, pas un plat à consommer). Les
// champs macros/poids sont demandés pour respecter le contrat JSON commun
// mais ne sont pas utilisés côté client — seul `name` sert (voir
// pantry_scan_screen.dart), qui alimente ensuite meal-suggestions via
// `availableIngredients`.

// Liste de priorité des modèles (voir README : diverge volontairement/par
// drift historique des autres fonctions IA du projet, non harmonisée).
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

const MAX_IMAGE_BYTES = 8 * 1024 * 1024; // 8 Mo, cohérent avec le budget Cloudflare/Gemini existant
const BASE64_IMAGE_RE = /^[A-Za-z0-9+/]+={0,2}$/;

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
    const quota = await checkAndIncrementQuota(req, 'analyze-pantry', 20, corsHeaders, 500, lang);
    if (!quota.ok) {
        return quota.response!;
    }

    try {
        if (bodyParseError) {
            throw new Error(isEn ? "The request body is empty or malformed." : "Le corps de la requête est vide ou mal formé.");
        }

        const { image } = body;
        if (!image || typeof image !== 'string') {
            throw new HttpError(400, isEn ? "No image was provided in the request." : "Aucune image n'a été fournie dans la requête.");
        }
        if (!BASE64_IMAGE_RE.test(image)) {
            throw new HttpError(400, isEn ? "The image is not valid base64 data." : "L'image n'est pas une donnée base64 valide.");
        }
        if ((image.length * 3) / 4 > MAX_IMAGE_BYTES) {
            throw new HttpError(413, isEn ? "The image is too large (8 MB max)." : "L'image est trop volumineuse (8 Mo max).");
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
Cette photo montre l'intérieur d'un réfrigérateur ou d'un placard — CE N'EST PAS une photo d'assiette ni de menu.
Identifie chaque aliment ou ingrédient distinct visible (légumes, fruits, produits laitiers, viandes, condiments, boîtes, etc.). Regroupe les doublons du même aliment en une seule entrée. Ignore les contenants/emballages/marques qui ne sont pas des aliments identifiables.
Pour CHACUN, donne un nom court et générique (ex. "Tomates", "Oeufs", "Riz"), une estimation grossière de la quantité visible en grammes (weight) et des macronutriments approximatifs (kcal, protéines, glucides, lipides, fibres, sucres, acides gras saturés) POUR 100 GRAMMES — ces valeurs servent juste à respecter le format, la précision n'est pas critique ici.
Tu DOIS répondre UNIQUEMENT au format JSON strict, sans aucun autre texte autour ni balises markdown.
Le JSON doit avoir cette structure exacte :
{
  "ingredients": [
    {
      "id": "1",
      "name": "Nom de l'ingrédient",
      "weight": 200,
      "kcalPer100g": 80,
      "protPer100g": 5.0,
      "glucPer100g": 10.0,
      "lipPer100g": 2.0,
      "fiberPer100g": 2.0,
      "sugarPer100g": 3.0,
      "satFatPer100g": 0.5
    }
  ]
}
${langInstruction}`;

        // === 4. BOUCLE DE TENTATIVES (FALLBACK) ===
        let successData: string;
        let usedModel: string;
        try {
            const result = await callGeminiWithFallback(apiKey, MODELS, {
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
            });
            successData = result.text;
            usedModel = result.usedModel;
        } catch (err) {
            console.error(`Tous les modèles ont échoué (analyze-pantry). Dernière erreur : ${(err as Error).message}`);
            throw new Error(isEn ? "Analysis temporarily failed. Please try again later." : "L'analyse a temporairement échoué. Réessaie plus tard.");
        }

        console.log(`SUCCÈS : Analyse générée avec ${usedModel}`);

        // Nettoyage : On retire les éventuelles balises ```json que l'IA pourrait ajouter
        const jsonString = successData.replace(/```json/gi, '').replace(/```/g, '').trim();

        let parsedJson;
        try {
            parsedJson = JSON.parse(jsonString);
        } catch {
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
        const message = error instanceof Error ? error.message : String(error);
        console.error("Erreur fatale Edge Function:", message);

        // On renvoie l'erreur au format JSON pour que Flutter puisse l'afficher dans le SnackBar
        return new Response(JSON.stringify({ error: message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: error instanceof HttpError ? error.status : 400,
        })
    }
})