import { assertEquals } from "jsr:@std/assert@1";
import { detectHealthRisk } from "./health_risk_filter.ts";

const SELF_HARM_FR = [
    "Je veux me suicider",
    "J'ai envie de me suicider ce soir",
    "Je veux mourir",
    "J'ai envie de mourir depuis quelques jours",
    "Je veux en finir",
    "J'ai envie d'en finir avec tout ça",
    "Je veux me tuer",
    "Je pense au suicide très souvent",
    "J'ai des idées suicidaires",
    "Je veux me faire du mal",
    "Je me scarifie le soir",
    "Je m'automutile régulièrement",
];

const SELF_HARM_EN = [
    "I want to kill myself",
    "I want to die",
    "I want to end it all",
    "I'm suicidal",
    "I am suicidal right now",
    "I've had suicidal thoughts lately",
    "I want to hurt myself",
    "I self harm when I feel bad",
    "I'm cutting myself",
    "I don't want to live anymore",
    "I keep thinking about ending my life",
];

const EATING_DISORDER = [
    "Je me fais vomir après chaque repas",
    "Je vomis après chaque repas que je mange",
    "Je ne mange plus rien depuis des jours",
    "Je ne mange presque plus rien de la journée",
    "Je culpabilise à chaque fois que je mange",
    "J'ai une obsession du poids depuis des mois",
    "Je prends des laxatifs pour maigrir",
    "Je saute tous mes repas pour maigrir",
    "Je me prive de manger toute la journée",
    "I make myself throw up after eating",
    "I purge after eating most meals",
    "I throw up after every meal",
    "I haven't eaten in days",
    "I feel guilty every time I eat",
    "I take laxatives to lose weight",
    "I starve myself most days",
    "I'm obsessed with my weight",
];

const DANGEROUS_GOAL = [
    "Je veux perdre 10 kg en une semaine",
    "Je veux perdre 10 kg en 2 semaines",
    "Je fais un jeûne prolongé ce mois-ci",
    "Je commence un jeûne extrême",
    "Je fais un jeûne de 7 jours",
    "Je suis un régime à 500 kcal",
    "Je ne mange que 300 kcal par jour",
    "Je veux maigrir très vite",
    "I want to lose 10kg in a week",
    "I want to lose 10kg in 2 weeks",
    "I'm doing an extended fast",
    "I'm doing a water fast for 7 days",
    "I'm on a 500 calorie diet",
    "I am eating only 300 calories a day",
    "I want to lose weight super fast",
];

const FALSE_POSITIVES = [
    "Je vomis de rire devant cette vidéo",
    "Je suis mort de rire",
    "Ce gâteau est à tuer",
    "J'ai perdu 2kg cette semaine, je suis content",
    "Je veux perdre 5kg en 3 mois",
    "J'ai jeûné pendant le ramadan",
    "This diet is killing me lol",
    "I'm dying of laughter",
    "I'm starving, let's eat!",
    "I want to lose 1kg in a week",
];

Deno.test("detectHealthRisk flags self-harm phrases (FR)", () => {
    for (const message of SELF_HARM_FR) {
        assertEquals(detectHealthRisk(message), "self_harm", message);
    }
});

Deno.test("detectHealthRisk flags self-harm phrases (EN)", () => {
    for (const message of SELF_HARM_EN) {
        assertEquals(detectHealthRisk(message), "self_harm", message);
    }
});

Deno.test("detectHealthRisk flags eating disorder phrases", () => {
    for (const message of EATING_DISORDER) {
        assertEquals(detectHealthRisk(message), "eating_disorder", message);
    }
});

Deno.test("detectHealthRisk flags dangerous goal phrases", () => {
    for (const message of DANGEROUS_GOAL) {
        assertEquals(detectHealthRisk(message), "dangerous_goal", message);
    }
});

Deno.test("detectHealthRisk does not flag false positives", () => {
    for (const message of FALSE_POSITIVES) {
        assertEquals(detectHealthRisk(message), null, message);
    }
});
