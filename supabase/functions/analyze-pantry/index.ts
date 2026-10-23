import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { handleImageAnalysis } from "../_shared/analyze_image.ts"

const PROMPT = `
Tu es un nutritionniste expert et un chef cuisinier.
Cette photo montre l'intérieur d'un réfrigérateur ou d'un placard — CE N'EST PAS une photo d'assiette ni de menu.
Identifie chaque aliment ou ingrédient distinct visible (légumes, fruits, produits laitiers, viandes, condiments, boîtes, etc.). Regroupe les doublons du même aliment en une seule entrée. Ignore les contenants/emballages/marques qui ne sont pas des aliments identifiables.
Pour CHACUN, donne un nom court et générique (ex. "Tomates", "Oeufs", "Riz"), une estimation grossière de la quantité visible en grammes (weight) et des macronutriments approximatifs (kcal, protéines, glucides, lipides, fibres, sucres, acides gras saturés) POUR 100 GRAMMES — ces valeurs servent juste à respecter le format, la précision n'est pas critique ici.
Tu DOIS répondre UNIQUEMENT au format JSON strict, sans aucun autre texte autour ni balises markdown.
Le JSON doit avoir cette structure exacte :
{
  "ingredients": [
    {
      "id": "1",
      "name": "Nom de l'ingrédient",
      "weight": 200,
      "kcalPer100g": 80,
      "protPer100g": 5.0,
      "glucPer100g": 10.0,
      "lipPer100g": 2.0,
      "fiberPer100g": 2.0,
      "sugarPer100g": 3.0,
      "satFatPer100g": 0.5
    }
  ]
}`;

Deno.serve((req) => handleImageAnalysis(req, { functionName: "analyze-pantry", prompt: PROMPT }));
