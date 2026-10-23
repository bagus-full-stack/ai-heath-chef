import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { HttpError } from "../_shared/errors.ts"
import { checkAndIncrementQuota } from "../_shared/quota.ts"
import { corsHeaders } from "../_shared/cors.ts"
import { callGeminiWithFallback } from "../_shared/gemini.ts"

// Liste de priorité des modèles (voir README : diverge volontairement/par
// drift historique des autres fonctions IA du projet, non harmonisée).
// Seuls les GEMINI_MAX_MODELS_TRIED premiers sont essayés (voir gemini.ts) : inutile d'en lister plus.
const MODELS = [
    "gemini-2.5-flash",
    "gemini-2.5-pro",
    "gemini-2.0-flash-exp",
    "gemini-2.0-flash",
];

const GOAL_LABELS: Record<string, string> = {
    loseWeight: "perte de poids (repas riches en protéines, rassasiants, modérés en calories)",
    gainMuscle: "prise de muscle (repas riches en protéines et en calories)",
    maintain: "maintien du poids (repas équilibrés)",
};

const DIET_LABELS: Record<string, string> = {
    vegetarian: "végétarien (sans viande ni poisson)",
    vegan: "végétalien (sans aucun produit d'origine animale)",
    pescetarian: "pescétarien (sans viande, poisson autorisé)",
    halal: "halal",
    kosher: "kasher",
};

const CUISINE_LABELS: Record<string, string> = {
    mediterranean: "méditerranéenne (Italie, Grèce, Espagne, Provence...)",
    maghrebine: "maghrébine (Maroc, Algérie, Tunisie)",
    asian: "asiatique (Chine, Japon, Vietnam, Thaïlande...)",
    indian: "indienne",
    middleEastern: "moyen-orientale (Liban, Turquie, Iran...)",
    african: "africaine subsaharienne",
    latinAmerican: "latino-américaine (Mexique, Pérou, Brésil...)",
    european: "européenne (France, Allemagne, Europe de l'Est...)",
};

Deno.serve(async (req) => {
    // === GESTION DU PREFLIGHT (CORS) ===
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    // === 1. RECUPERATION DU BODY, avant le quota pour connaître la langue ===
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
    const quota = await checkAndIncrementQuota(req, 'meal-suggestions', 10, corsHeaders, 300, lang);
    if (!quota.ok) {
        return quota.response!;
    }

    try {
        if (bodyParseError) {
            throw new HttpError(400, isEn ? "The request body is empty or malformed." : "Le corps de la requête est vide ou mal formé.");
        }

        const {
            goal,
            targetKcal,
            targetProt,
            targetGluc,
            targetLip,
            dietType,
            allergies,
            cuisinePreference,
            count,
            days,
            mealsPerDay,
            availableIngredients,
        } = body;

        // Plan hebdomadaire (weekly_meal_plan_provider.dart) : `days` remplace
        // `count`, plafonné pour rester dans une seule réponse IA raisonnable.
        const isWeeklyPlan = Number.isFinite(days) && (days as number) > 1;
        const weeklyMealsPerDay = Number.isFinite(mealsPerDay) && (mealsPerDay as number) > 0
            ? Math.min(mealsPerDay as number, 5)
            : 3;
        const suggestionCount = isWeeklyPlan
            ? Math.min((days as number) * weeklyMealsPerDay, 35)
            : (Number.isFinite(count) && (count as number) > 0 ? Math.min(count as number, 10) : 6);
        // Cibles fournies par le client : converties en nombres bornés avant d'entrer
        // dans le prompt (pas de texte libre, pas de cible sous le plancher de 1200 kcal).
        const clampNum = (v: unknown, fallback: number, min: number, max: number) => {
            const n = Number(v);
            return Number.isFinite(n) ? Math.round(Math.min(Math.max(n, min), max)) : fallback;
        };
        const kcal = clampNum(targetKcal, 2200, 1200, 6000);
        const prot = clampNum(targetProt, 160, 0, 500);
        const gluc = clampNum(targetGluc, 250, 0, 800);
        const lip = clampNum(targetLip, 75, 0, 300);
        const goalLabel = GOAL_LABELS[goal as string] ?? GOAL_LABELS.maintain;
        const dietLabel = DIET_LABELS[dietType as string];
        const cuisineLabel = CUISINE_LABELS[cuisinePreference as string];
        const allergyList: string[] = Array.isArray(allergies)
            ? allergies.filter((a) => typeof a === 'string' && a.trim().length > 0).slice(0, 20).map((a) => a.slice(0, 60))
            : [];
        // Photo frigo/placard (voir analyze-pantry/index.ts) : priorise ces
        // ingrédients déjà disponibles plutôt que d'en proposer de nouveaux.
        const availableIngredientsList: string[] = Array.isArray(availableIngredients)
            ? availableIngredients.filter((a) => typeof a === 'string' && a.trim().length > 0).slice(0, 50).map((a) => a.slice(0, 60))
            : [];

        // === 2. VÉRIFICATION CLÉ API GEMINI ===
        const apiKey = Deno.env.get('GEMINI_API_KEY');
        if (!apiKey) {
            console.error("ERREUR CRITIQUE: Clé GEMINI_API_KEY introuvable.");
            throw new Error(isEn ? "Missing server configuration (API Key)." : "Configuration serveur manquante (API Key).");
        }

        // === 3. PRÉPARATION DU PROMPT ===
        const constraintLines = [];
        if (dietLabel) {
            constraintLines.push(`Régime à respecter STRICTEMENT : ${dietLabel}.`);
        }
        if (cuisineLabel) {
            constraintLines.push(
                `Privilégie des plats typiques de la cuisine ${cuisineLabel} tant que cela reste compatible avec le régime et les allergies ci-dessus.`,
            );
        }
        if (allergyList.length > 0) {
            constraintLines.push(
                `Allergies/intolérances à éviter ABSOLUMENT, dans aucun ingrédient : ${allergyList.join(', ')}.`,
            );
        }
        if (availableIngredientsList.length > 0) {
            constraintLines.push(
                `Utilise EN PRIORITÉ ces ingrédients déjà disponibles dans le frigo/placard de l'utilisateur : ${availableIngredientsList.join(', ')}. Chaque recette proposée doit utiliser un maximum de ces ingrédients ; tu peux compléter avec quelques ingrédients de base courants (sel, huile, épices, eau...) si nécessaire.`,
            );
        }
        const constraintsText = constraintLines.length > 0 ? `\n${constraintLines.join('\n')}` : '';
        const langInstruction = lang === 'en'
            ? "Respond with English text values (title, description, timeSlot, ingredients, steps) in the JSON."
            : "Réponds avec des valeurs textuelles en français (title, description, timeSlot, ingredients, steps) dans le JSON.";
        // Garde-fou santé, même si targetKcal est déjà plancherné côté app
        // (voir lib/utils/nutrition_targets.dart) : défense en profondeur si
        // ce total venait à être anormalement bas.
        const safetyInstruction = lang === 'en'
            ? "Never suggest a plan whose total daily calories fall below 1200 kcal, nor any meal built around an extreme/prolonged fast or a dangerously restrictive diet."
            : "Ne propose jamais un plan dont le total calorique quotidien descend sous 1200 kcal, ni aucun repas construit autour d'un jeûne extrême/prolongé ou d'un régime dangereusement restrictif.";

        const weeklyPlanInstruction = isWeeklyPlan
            ? `\nRépartis ces ${suggestionCount} repas sur ${days} jours (${weeklyMealsPerDay} repas/jour), en indiquant pour chacun le numéro du jour dans le champ "day" (1 = premier jour, ${days} = dernier). Varie les plats d'un jour à l'autre, ne répète jamais le même plat sur deux jours différents.`
            : '';
        const dayFieldExample = isWeeklyPlan ? '\n      "day": 1,' : '';

        const promptText = `
Tu es AI Health Chef, un coach en nutrition expert et créatif.
Propose ${suggestionCount} idées de repas variées et réalistes, adaptées à un objectif de ${goalLabel}.
L'utilisateur vise environ ${kcal} kcal, ${prot}g de protéines, ${gluc}g de glucides et ${lip}g de lipides par jour au total.${constraintsText}${weeklyPlanInstruction}
${safetyInstruction}
Varie les moments de la journée (Petit-déjeuner, Déjeuner, Dîner, Collation) et les types de plats — ne propose jamais deux fois le même plat.
Pour chaque plat, donne aussi la liste des ingrédients (avec quantités approximatives) et les étapes de préparation, courtes et actionnables.
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
      "description": "Une phrase courte expliquant pourquoi ce repas convient à l'objectif.",
      "ingredients": ["150g de blanc de poulet", "100g de riz basmati", "..."],
      "steps": ["Faire cuire le riz...", "Assaisonner le poulet...", "..."]${dayFieldExample}
    }
  ]
}
${langInstruction}`;

        // === 4. BOUCLE DE TENTATIVES (FALLBACK) ===
        let successData: string;
        let usedModel: string;
        try {
            const result = await callGeminiWithFallback(apiKey, MODELS, {
                contents: [{ parts: [{ text: promptText }] }],
                generationConfig: {
                    temperature: 0.8 // Un peu de créativité pour varier les suggestions
                }
            });
            successData = result.text;
            usedModel = result.usedModel;
        } catch (err) {
            console.error(`Tous les modèles ont échoué (meal-suggestions). Dernière erreur : ${(err as Error).message}`);
            throw new HttpError(502, isEn ? "Suggestions temporarily failed. Please try again later." : "La génération de suggestions a temporairement échoué. Réessaie plus tard.");
        }

        console.log(`SUCCÈS : Suggestions générées avec ${usedModel}`);

        // Nettoyage : on retire les éventuelles balises ```json que l'IA pourrait ajouter
        const jsonString = successData.replace(/```json/gi, '').replace(/```/g, '').trim();

        let parsedJson;
        try {
            parsedJson = JSON.parse(jsonString);
        } catch {
            console.error("JSON invalide du modèle :", jsonString.slice(0, 500));
            throw new HttpError(502, isEn ? "The model returned an unreadable answer. Please try again." : "Le modèle a renvoyé une réponse illisible. Réessaie.");
        }

        return new Response(JSON.stringify(parsedJson), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        })

    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        console.error("Erreur fatale Edge Function (Meal Suggestions):", message);

        return new Response(JSON.stringify({ error: error instanceof HttpError ? message : (isEn ? "Something went wrong. Please try again later." : "Une erreur est survenue. Réessaie plus tard.") }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: error instanceof HttpError ? error.status : 500,
        })
    }
})
