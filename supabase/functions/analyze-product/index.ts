import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { checkAndIncrementQuota } from "../_shared/quota.ts"
import { corsHeaders } from "../_shared/cors.ts"
import { HttpError } from "../_shared/errors.ts"
import { callGeminiWithFallback } from "../_shared/gemini.ts"

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
    const quota = await checkAndIncrementQuota(req, 'analyze-product', 20, corsHeaders, 500, lang);
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
            ? "Respond with English text values (product name) in the JSON."
            : "Réponds avec des valeurs textuelles en français (nom du produit) dans le JSON.";

        // === 2. VÉRIFICATION CLÉ API GEMINI ===
        const apiKey = Deno.env.get('GEMINI_API_KEY');
        if (!apiKey) {
            console.error("ERREUR CRITIQUE: Clé GEMINI_API_KEY introuvable.");
            throw new Error(isEn ? "Missing server configuration (API Key)." : "Configuration serveur manquante (API Key).");
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
        let successData: string;
        let usedModel: string;
        try {
            const result = await callGeminiWithFallback(apiKey, MODELS, {
                contents: [{
                    parts: [
                        { text: promptText },
                        { inlineData: { mimeType: "image/jpeg", data: image } }
                    ]
                }],
                generationConfig: {
                    temperature: 0.2
                }
            });
            successData = result.text;
            usedModel = result.usedModel;
        } catch (err) {
            console.error(`Tous les modèles ont échoué (analyze-product). Dernière erreur : ${(err as Error).message}`);
            throw new Error(isEn ? "Analysis temporarily failed. Please try again later." : "L'analyse a temporairement échoué. Réessaie plus tard.");
        }

        console.log(`SUCCÈS : Analyse produit générée avec ${usedModel}`);

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

        return new Response(JSON.stringify(parsedJson), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        })

    } catch (error) {
        console.error("Erreur fatale Edge Function (Analyze Product):", error.message);

        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: error instanceof HttpError ? error.status : 400,
        })
    }
})
