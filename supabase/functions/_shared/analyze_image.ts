import { checkAndIncrementQuota } from "./quota.ts"
import { corsHeaders } from "./cors.ts"
import { HttpError } from "./errors.ts"
import { validateBase64Image } from "./image.ts"
import { callGeminiWithFallback } from "./gemini.ts"

// Liste de priorité des modèles (voir README : diverge volontairement/par
// drift historique des autres fonctions IA du projet, non harmonisée).
// Seuls les GEMINI_MAX_MODELS_TRIED premiers sont essayés (voir gemini.ts) : inutile d'en lister plus.
const MODELS = [
    "gemini-2.5-flash",
    "gemini-2.5-pro",
    "gemini-2.0-flash-exp",
    "gemini-2.0-flash",
];


/**
 * Corps commun d'analyze-meal / analyze-menu / analyze-pantry / analyze-product : même contrat
 * (`{ image, lang }` -> `{ ingredients: [...] }`), seul le prompt et le nom de
 * fonction (clé de quota) changent.
 */
export async function handleImageAnalysis(
    req: Request,
    // `names` : ce que le modèle doit écrire dans la langue de l'utilisateur (défaut : noms d'ingrédients).
    config: { functionName: string; prompt: string; names?: { en: string; fr: string } },
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

    try {
        if (bodyParseError) {
            throw new HttpError(400, isEn ? "The request body is empty or malformed." : "Le corps de la requête est vide ou mal formé.");
        }

        const { image } = body;
        if (!image || typeof image !== 'string') {
            throw new HttpError(400, isEn ? "No image was provided in the request." : "Aucune image n'a été fournie dans la requête.");
        }
        validateBase64Image(image, isEn);

        // === QUOTA QUOTIDIEN PAR UTILISATEUR === après validation : une requête invalide ne consomme pas de crédit.
        const quota = await checkAndIncrementQuota(req, config.functionName, 20, corsHeaders, 500, lang);
        if (!quota.ok) {
            return quota.response!;
        }

        const langInstruction = isEn
            ? `Respond with English text values (${config.names?.en ?? "ingredient names"}) in the JSON.`
            : `Réponds avec des valeurs textuelles en français (${config.names?.fr ?? "noms des ingrédients"}) dans le JSON.`;

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
