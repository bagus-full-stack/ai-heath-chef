import { checkAndIncrementQuota } from "./quota.ts"
import { corsHeaders } from "./cors.ts"
import { HttpError } from "./errors.ts"
import { validateBase64Image } from "./image.ts"
import { callGeminiWithFallback } from "./gemini.ts"

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
];


/**
 * Corps commun d'analyze-meal / analyze-menu / analyze-pantry : même contrat
 * (`{ image, lang }` -> `{ ingredients: [...] }`), seul le prompt et le nom de
 * fonction (clé de quota) changent.
 */
export async function handleImageAnalysis(
    req: Request,
    config: { functionName: string; prompt: string },
): Promise<Response> {
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
    const quota = await checkAndIncrementQuota(req, config.functionName, 20, corsHeaders, 500, lang);
    if (!quota.ok) {
        return quota.response!;
    }

    try {
        if (bodyParseError) {
            throw new HttpError(400, isEn ? "The request body is empty or malformed." : "Le corps de la requête est vide ou mal formé.");
        }

        const { image } = body;
        if (!image || typeof image !== 'string') {
            throw new HttpError(400, isEn ? "No image was provided in the request." : "Aucune image n'a été fournie dans la requête.");
        }
        validateBase64Image(image, isEn);
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
        const promptText = `${config.prompt}
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
            console.error(`Tous les modèles ont échoué (${config.functionName}). Dernière erreur : ${(err as Error).message}`);
            throw new HttpError(502, isEn ? "Analysis temporarily failed. Please try again later." : "L'analyse a temporairement échoué. Réessaie plus tard.");
        }

        console.log(`SUCCÈS : Analyse générée avec ${usedModel}`);

        // Nettoyage : On retire les éventuelles balises ```json que l'IA pourrait ajouter
        const jsonString = successData.replace(/```json/gi, '').replace(/```/g, '').trim();

        let parsedJson;
        try {
            parsedJson = JSON.parse(jsonString);
        } catch {
            console.error("JSON invalide du modèle :", jsonString.slice(0, 500));
            throw new HttpError(502, isEn ? "The model returned an unreadable answer. Please try again." : "Le modèle a renvoyé une réponse illisible. Réessaie.");
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
        return new Response(JSON.stringify({ error: error instanceof HttpError ? message : (isEn ? "Something went wrong. Please try again later." : "Une erreur est survenue. Réessaie plus tard.") }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: error instanceof HttpError ? error.status : 500,
        })
    }
}
