import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { checkAndIncrementQuota } from "../_shared/quota.ts"
import { corsHeaders } from "../_shared/cors.ts"
import { HttpError } from "../_shared/errors.ts"
import { callGeminiWithFallback } from "../_shared/gemini.ts"
import { detectHealthRisk, safetyReplyFor } from "../_shared/health_risk_filter.ts"
import { buildCoachSystemInstruction } from "../_shared/coach_prompt.ts"

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
    "gemini-3-pro-preview",
    "gemini-3-flash-preview",
    "nano-banana-pro-preview",
    "gemini-1.5-flash" // Sécurité ultime (le plus stable)
];

const MAX_MESSAGE_LENGTH = 4000;
const MAX_HISTORY_ENTRIES = 50;
// Généreux par rapport aux ~500 caractères attendus d'un vrai bloc (voir
// coach_context_builder.dart) : borne défensive contre un appelant
// malveillant/bugué, pas un budget normal.
const MAX_DAILY_CONTEXT_LENGTH = 2000;
const MAX_HISTORY_PARTS = 4;

/** Extrait pour être appelable directement depuis `index_test.ts` (Deno.serve ne peut pas être importé). */
export async function handleCoachChat(req: Request): Promise<Response> {
    // === GESTION DU PREFLIGHT (CORS) ===
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    // === 1. RECUPERATION DU BODY (Le message et l'historique), avant le quota pour connaître la langue ===
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
    const quota = await checkAndIncrementQuota(req, 'coach-chat', 50, corsHeaders, 1000, lang);
    if (!quota.ok) {
        return quota.response!;
    }

    try {
        if (bodyParseError) {
            throw new HttpError(400, isEn ? "The request body is empty or malformed." : "Le corps de la requête est vide ou mal formé.");
        }

        const { message, history, coachTone, dietType, allergies, dailyContext } = body;
        if (!message || typeof message !== 'string') {
            throw new HttpError(400, isEn ? "No message was provided in the request." : "Aucun message n'a été fourni dans la requête.");
        }
        if (message.length > MAX_MESSAGE_LENGTH) {
            throw new HttpError(400, isEn ? `The message is too long (max ${MAX_MESSAGE_LENGTH} characters).` : `Le message est trop long (max ${MAX_MESSAGE_LENGTH} caractères).`);
        }

        // === FILET DE SÉCURITÉ DÉTERMINISTE (avant tout appel modèle) ===
        // Complémentaire au safetyInstruction du prompt : un modèle peut
        // ignorer une instruction, pas ce filtre. Voir health_risk_filter.ts.
        const riskCategory = detectHealthRisk(message);
        if (riskCategory) {
            return new Response(JSON.stringify({ reply: safetyReplyFor(riskCategory, isEn), suggestedDish: null }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 200,
            })
        }

        // === 2. VÉRIFICATION CLÉ API GEMINI ===
        const apiKey = Deno.env.get('GEMINI_API_KEY');
        if (!apiKey) {
            console.error("ERREUR CRITIQUE: Clé GEMINI_API_KEY introuvable.");
            throw new Error(isEn ? "Missing server configuration (API Key)." : "Configuration serveur manquante (API Key).");
        }

        // === 3. PRÉPARATION DES INSTRUCTIONS SYSTÈME (voir _shared/coach_prompt.ts) ===
        const allergyList: string[] = Array.isArray(allergies)
            ? allergies.filter((a) => typeof a === 'string' && a.trim().length > 0)
            : [];
        const safeDailyContext = typeof dailyContext === 'string'
            ? dailyContext.slice(0, MAX_DAILY_CONTEXT_LENGTH)
            : undefined;
        const systemInstruction = buildCoachSystemInstruction({
            lang,
            coachTone: coachTone as string,
            dietType: dietType as string,
            allergies: allergyList,
            dailyContext: safeDailyContext,
        });

        // On prépare le payload exact attendu par l'API REST de Google
        // On combine l'historique (s'il y en a) avec le nouveau message
        // L'historique vient du client : on ne garde que des tours texte
        // user/model (pas d'images ni d'autres types de parties, nombre de
        // parties borné), pour qu'il ne serve ni à gonfler le coût d'un appel
        // ni à forger de fausses réponses du modèle avec des champs inattendus.
        const contents = [];
        if (history && Array.isArray(history)) {
            for (const entry of history.slice(-MAX_HISTORY_ENTRIES) as Record<string, unknown>[]) {
                if ((entry?.role !== 'user' && entry?.role !== 'model') || !Array.isArray(entry.parts)) continue;
                const parts = (entry.parts as Record<string, unknown>[])
                    .filter((part) => typeof part?.text === 'string')
                    .slice(0, MAX_HISTORY_PARTS)
                    .map((part) => ({ text: (part.text as string).slice(0, MAX_MESSAGE_LENGTH) }));
                if (parts.length > 0) contents.push({ role: entry.role, parts });
            }
        }
        contents.push({ role: "user", parts: [{ text: message }] });


        // === 4. BOUCLE DE TENTATIVES (FALLBACK) ===
        let successData: string;
        let usedModel: string;
        try {
            const result = await callGeminiWithFallback(apiKey, MODELS, {
                systemInstruction: { parts: [{ text: systemInstruction }] },
                contents: contents,
                generationConfig: {
                    temperature: 0.7 // Une température moyenne pour avoir des réponses naturelles et variées
                }
            });
            successData = result.text;
            usedModel = result.usedModel;
        } catch (err) {
            console.error(`Tous les modèles de chat ont échoué (coach-chat). Dernière erreur : ${(err as Error).message}`);
            throw new HttpError(502, isEn ? "The coach temporarily failed. Please try again later." : "Le coach a temporairement échoué. Réessaie plus tard.");
        }

        console.log(`SUCCÈS : Réponse générée avec ${usedModel}`);

        // Extrait la balise "[DISH: ...]" ajoutée par le modèle en fin de
        // réponse quand il recommande un plat précis (voir dishTagInstruction
        // ci-dessus), pour que Flutter puisse générer une illustration via
        // meal-images sans avoir à parser le texte affiché à l'utilisateur.
        let replyText = successData.trim();
        let suggestedDish: string | null = null;
        const dishMatch = replyText.match(/\[DISH:\s*([^\]]+)\]\s*$/i);
        if (dishMatch) {
            suggestedDish = dishMatch[1].trim();
            replyText = replyText.slice(0, dishMatch.index).trim();
        }

        // On renvoie la réponse de l'IA à l'application Flutter
        return new Response(JSON.stringify({ reply: replyText, suggestedDish }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        })

    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        console.error("Erreur fatale Edge Function (Coach):", message);

        // Seules les HttpError portent un message prévu pour l'utilisateur ;
        // toute autre erreur (config manquante, bug) reste dans les logs.
        const userMessage = error instanceof HttpError
            ? message
            : (isEn ? "Something went wrong. Please try again later." : "Une erreur est survenue. Réessaie plus tard.");
        return new Response(JSON.stringify({ error: userMessage }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: error instanceof HttpError ? error.status : 500,
        })
    }
}

