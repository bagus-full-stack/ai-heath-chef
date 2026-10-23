import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { handleImageAnalysis } from "../_shared/analyze_image.ts"

// Contrairement à analyze-meal (une assiette avec plusieurs aliments), ici la photo
// montre un produit emballé : son étiquette nutritionnelle ou sa face avant.
const PROMPT = `
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
}`;

Deno.serve((req) =>
    handleImageAnalysis(req, {
        functionName: "analyze-product",
        prompt: PROMPT,
        names: { en: "product name", fr: "nom du produit" },
    })
);
