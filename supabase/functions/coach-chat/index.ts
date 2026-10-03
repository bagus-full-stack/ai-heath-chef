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

Deno.serve(async (req) => {
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
            throw new Error(isEn ? "The request body is empty or malformed." : "Le corps de la requête est vide ou mal formé.");
        }

        const { message, history, coachTone, dietType, allergies } = body;
        if (!message || typeof message !== 'string') {
            throw new HttpError(400, isEn ? "No message was provided in the request." : "Aucun message n'a été fourni dans la requête.");
        }
        if (message.length > MAX_MESSAGE_LENGTH) {
            throw new HttpError(400, isEn ? `The message is too long (max ${MAX_MESSAGE_LENGTH} characters).` : `Le message est trop long (max ${MAX_MESSAGE_LENGTH} caractères).`);
        }

        // === 2. VÉRIFICATION CLÉ API GEMINI ===
        const apiKey = Deno.env.get('GEMINI_API_KEY');
        if (!apiKey) {
            console.error("ERREUR CRITIQUE: Clé GEMINI_API_KEY introuvable.");
            throw new Error(isEn ? "Missing server configuration (API Key)." : "Configuration serveur manquante (API Key).");
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

        const langInstruction = lang === 'en' ? " Always respond in English." : " Réponds toujours en français.";
        const dishTagInstruction = isEn
            ? " If, and only if, you recommend one specific dish or recipe the user could cook or order, end your reply with a separate line in the exact format \"[DISH: Dish name]\" (short name, no description). Never add this tag for general advice, questions, or encouragement."
            : " Si, et seulement si, tu recommandes un plat ou une recette précise que l'utilisateur pourrait cuisiner ou commander, termine ta réponse par une ligne séparée au format exact \"[DISH: Nom du plat]\" (nom court, sans description). N'ajoute JAMAIS cette balise pour un conseil général, une question ou un encouragement.";
        // Garde-fou santé : voir lib/utils/nutrition_targets.dart pour le
        // plancher calorique appliqué côté app (1200/1500 kcal). Le coach ne
        // doit jamais recommander moins, ni un jeûne extrême ou un régime
        // dangereux, et doit orienter vers un professionnel en cas de signal
        // de trouble du comportement alimentaire.
        const safetyInstruction = isEn
            ? " Never recommend a daily calorie target below 1200 kcal for a woman or 1500 kcal for a man, an extreme/prolonged fast, or any other dangerous or extremely restrictive diet. If the user mentions signs of disordered eating (extreme restriction, purging, obsession with weight), respond with warmth and without judgment, and gently encourage them to talk to a doctor, dietitian, or mental health professional."
            : " Ne recommande jamais une cible calorique quotidienne inférieure à 1200 kcal pour une femme ou 1500 kcal pour un homme, un jeûne extrême/prolongé, ni aucun autre régime dangereux ou extrêmement restrictif. Si l'utilisateur évoque des signes de trouble du comportement alimentaire (restriction extrême, purge, obsession du poids), réponds avec bienveillance et sans jugement, et encourage-le doucement à en parler à un médecin, un·e diététicien·ne ou un·e psychologue.";
        const systemInstruction = `Tu es AI Health Chef, un coach en nutrition expert. ${toneInstruction} Tu réponds de manière concise (maximum 3 phrases) et claire. Tu tutoies l'utilisateur.${dietaryNote} Tu ne dois jamais utiliser de balises Markdown complexes, reste en texte simple.${langInstruction}${dishTagInstruction}${safetyInstruction}`;

        // On prépare le payload exact attendu par l'API REST de Google
        // On combine l'historique (s'il y en a) avec le nouveau message
        const contents = [];
        if (history && Array.isArray(history)) {
            const truncatedHistory = history.slice(-MAX_HISTORY_ENTRIES).map((entry: Record<string, unknown>) => {
                if (!entry || !Array.isArray(entry.parts)) return entry;
                return {
                    ...entry,
                    parts: entry.parts.map((part: Record<string, unknown>) =>
                        part && typeof part.text === 'string' && part.text.length > MAX_MESSAGE_LENGTH
                            ? { ...part, text: part.text.slice(0, MAX_MESSAGE_LENGTH) }
                            : part
                    ),
                };
            });
            contents.push(...truncatedHistory);
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
            throw new Error(isEn ? "The coach temporarily failed. Please try again later." : "Le coach a temporairement échoué. Réessaie plus tard.");
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
        console.error("Erreur fatale Edge Function (Coach):", error.message);

        // On renvoie l'erreur au format JSON
        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: error instanceof HttpError ? error.status : 400,
        })
    }
})