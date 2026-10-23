import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { handleImageAnalysis } from "../_shared/analyze_image.ts"

const PROMPT = `
Tu es un nutritionniste expert et un chef cuisinier. 
Ton but est d'analyser la nourriture présente sur cette photo.
Identifie les ingrédients principaux, estime une portion réaliste en grammes (weight), et fournis les macronutriments (kcal, protéines, glucides, lipides, fibres, sucres, acides gras saturés) POUR 100 GRAMMES de cet ingrédient.
Tu DOIS répondre UNIQUEMENT au format JSON strict, sans aucun autre texte autour ni balises markdown.
Le JSON doit avoir cette structure exacte :
{
  "ingredients": [
    {
      "id": "1",
      "name": "Nom de l'ingrédient",
      "weight": 150,
      "kcalPer100g": 120,
      "protPer100g": 10.5,
      "glucPer100g": 2.0,
      "lipPer100g": 5.0,
      "fiberPer100g": 1.2,
      "sugarPer100g": 1.5,
      "satFatPer100g": 2.0
    }
  ]
}`;

Deno.serve((req) => handleImageAnalysis(req, { functionName: "analyze-meal", prompt: PROMPT }));
