import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { handleImageAnalysis } from "../_shared/analyze_image.ts"

const PROMPT = `
Tu es un nutritionniste expert et un chef cuisinier.
Cette photo montre le menu (carte) d'un restaurant : une liste de plats, chacun avec un nom, parfois une description et un prix — CE N'EST PAS une photo d'assiette.
Identifie chaque plat proposé au menu. Pour CHACUN, estime une portion typique servie au restaurant en grammes (weight), et fournis les macronutriments (kcal, protéines, glucides, lipides, fibres, sucres, acides gras saturés) POUR 100 GRAMMES de ce plat, en te basant sur des plats similaires courants.
Ignore les lignes qui ne sont pas des plats (titres de section, prix seuls, allergènes, coordonnées du restaurant).
Tu DOIS répondre UNIQUEMENT au format JSON strict, sans aucun autre texte autour ni balises markdown.
Le JSON doit avoir cette structure exacte :
{
  "ingredients": [
    {
      "id": "1",
      "name": "Nom du plat",
      "weight": 350,
      "kcalPer100g": 180,
      "protPer100g": 12.0,
      "glucPer100g": 15.0,
      "lipPer100g": 8.0,
      "fiberPer100g": 2.0,
      "sugarPer100g": 3.0,
      "satFatPer100g": 3.0
    }
  ]
}`;

Deno.serve((req) => handleImageAnalysis(req, { functionName: "analyze-menu", prompt: PROMPT }));
