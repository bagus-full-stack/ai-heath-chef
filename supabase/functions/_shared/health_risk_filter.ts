/**
 * Filet de sécurité déterministe côté cloud, complémentaire au
 * `safetyInstruction` du prompt système (voir coach_prompt.ts) : un prompt
 * peut être ignoré ou contourné par le modèle, pas ce filtre. Miroir
 * volontaire de lib/utils/health_risk_filter.dart côté Flutter (pas de code
 * partagé possible entre Dart et Deno) — toute évolution des phrases
 * détectées doit être répercutée des deux côtés
 * étape 1.
 */

export type HealthRiskCategory = "self_harm" | "eating_disorder" | "dangerous_goal";

export function detectHealthRisk(message: string): HealthRiskCategory | null {
    const normalized = normalize(message);
    if (containsAny(normalized, SELF_HARM_PHRASES)) return "self_harm";
    if (containsAny(normalized, EATING_DISORDER_PHRASES)) return "eating_disorder";
    if (containsAny(normalized, DANGEROUS_GOAL_PHRASES) || hasDangerousWeightLossRate(normalized)) {
        return "dangerous_goal";
    }
    return null;
}

function normalize(input: string): string {
    let s = input.toLowerCase();
    const accents: Record<string, string> = {
        "à": "a", "â": "a", "ä": "a",
        "é": "e", "è": "e", "ê": "e", "ë": "e",
        "î": "i", "ï": "i",
        "ô": "o", "ö": "o",
        "ù": "u", "û": "u", "ü": "u",
        "ç": "c",
        "œ": "oe",
    };
    for (const [accented, plain] of Object.entries(accents)) {
        s = s.replaceAll(accented, plain);
    }
    s = s.replace(/[^a-z0-9\s]/g, " ");
    s = s.replace(/\s+/g, " ").trim();
    return s;
}

function containsAny(normalized: string, phrases: string[]): boolean {
    return phrases.some((phrase) => normalized.includes(phrase));
}

const SELF_HARM_PHRASES = [
    "je veux me suicider",
    "j ai envie de me suicider",
    "je veux mourir",
    "j ai envie de mourir",
    "je veux en finir",
    "j ai envie d en finir",
    "je veux me tuer",
    "je pense au suicide",
    "idees suicidaires",
    "je veux me faire du mal",
    "je me scarifie",
    "je m automutile",
    "je veux disparaitre a jamais",
    "i want to kill myself",
    "i want to die",
    "i want to end it all",
    "i m suicidal",
    "i am suicidal",
    "suicidal thoughts",
    "i want to hurt myself",
    "i self harm",
    "i m cutting myself",
    "i don t want to live anymore",
    "ending my life",
];

const EATING_DISORDER_PHRASES = [
    "je me fais vomir",
    "je me fais vomir apres manger",
    "je vomis apres chaque repas",
    "je ne mange plus rien depuis des jours",
    "je ne mange presque plus rien",
    "je culpabilise a chaque fois que je mange",
    "obsession du poids",
    "je prends des laxatifs pour maigrir",
    "je saute tous mes repas pour maigrir",
    "je me prive de manger",
    "i make myself throw up",
    "i purge after eating",
    "i throw up after every meal",
    "i haven t eaten in days",
    "i feel guilty every time i eat",
    "i take laxatives to lose weight",
    "i starve myself",
    "i m obsessed with my weight",
];

const DANGEROUS_GOAL_PHRASES = [
    "jeune prolonge",
    "jeune extreme",
    "jeune de 7 jours",
    "jeune de plusieurs jours",
    "regime a 500 kcal",
    "regime a 400 kcal",
    "je ne mange que 300 kcal par jour",
    "maigrir tres vite",
    "extended fast",
    "prolonged fast",
    "water fast for 7 days",
    "500 calorie diet",
    "eating only 300 calories a day",
    "lose weight super fast",
];

const FR_WEIGHT_LOSS_RATE = /perdre\s+(\d{1,3})\s*kg\s+en\s+(\d{1,2})\s*(jour|jours|semaine|semaines)/;
const EN_WEIGHT_LOSS_RATE = /lose\s+(\d{1,3})\s*kg\s+in\s+(\d{1,2})\s*(day|days|week|weeks)/;

/** Voir lib/utils/health_risk_filter.dart pour la justification du seuil. */
const MAX_SAFE_KG_PER_WEEK = 1.5;

function hasDangerousWeightLossRate(normalized: string): boolean {
    const prepped = normalized
        .replaceAll("en une semaine", "en 1 semaine")
        .replaceAll("en un jour", "en 1 jour")
        .replaceAll("in a week", "in 1 week")
        .replaceAll("in a day", "in 1 day");

    const match = FR_WEIGHT_LOSS_RATE.exec(prepped) ?? EN_WEIGHT_LOSS_RATE.exec(prepped);
    if (!match) return false;

    const kg = parseInt(match[1], 10);
    const amount = parseInt(match[2], 10);
    const unit = match[3];
    const weeks = unit.startsWith("semaine") || unit.startsWith("week") ? amount : amount / 7;
    if (weeks <= 0) return false;

    return kg / weeks > MAX_SAFE_KG_PER_WEEK;
}

/**
 * Réponse fixe FR/EN : jamais de chiffre ni de plan, uniquement une
 * orientation vers un professionnel. Doit rester alignée avec les clés ARB
 * `coachSafetyReply*` côté Flutter (lib/l10n/app_fr.arb, app_en.arb) et avec
 * lib/config/emergency_contacts.dart pour la ligne d'urgence — numéros à
 * vérifier manuellement.
 */
export function safetyReplyFor(category: HealthRiskCategory, isEn: boolean): string {
    switch (category) {
        case "self_harm":
            return isEn
                ? "What you're feeling matters, and you shouldn't have to face it alone. I'm not able to help with this, but a professional can. Please reach out, as soon as you can, to someone you trust or a health professional. In the EU, call 112 for emergencies. Please also reach out to your local crisis line or a health professional as soon as you can."
                : "Ce que tu ressens compte, et tu ne devrais pas rester seul·e avec ça. Je ne suis pas en mesure de t'aider sur ce sujet, mais un professionnel peut. Parle-en, dès que possible, à quelqu'un de confiance ou à un professionnel de santé. En France : 3114 (numéro national de prévention du suicide, gratuit, 24/7) ou 15 (SAMU). Partout en Europe, en urgence vitale : 112.";
        case "eating_disorder":
            return isEn
                ? "Thank you for trusting me with this. I won't give you numbers or a plan on this topic, but what you're describing deserves to be heard by a doctor, dietitian, or mental health professional. You don't have to go through this alone."
                : "Merci de me faire confiance pour en parler. Je ne vais pas te donner de chiffres ni de plan sur ce sujet, mais ce que tu décris mérite d'être entendu par un médecin, un·e diététicien·ne ou un·e psychologue. Tu n'as pas à traverser ça seul·e.";
        case "dangerous_goal":
            return isEn
                ? "I can't guide you toward a goal that fast or restrictive, since it could be dangerous for your health. A doctor or dietitian can help you move toward your goal safely."
                : "Je ne peux pas t'accompagner vers un objectif aussi rapide ou restrictif, car cela peut être dangereux pour ta santé. Un·e médecin ou un·e diététicien·ne pourra t'aider à avancer vers ton objectif en toute sécurité.";
    }
}
