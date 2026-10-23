import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { corsHeaders } from "../_shared/cors.ts"
import { authenticate } from "../_shared/auth.ts"

/**
 * À déployer avec la CLI (`supabase functions deploy`, comme la CI le fait) :
 * l'éditeur du Dashboard ne bundle pas les imports vers `_shared/`.
 *
 * Donne le token Hugging Face (secret HUGGINGFACE_TOKEN) à un utilisateur
 * authentifié, pour qu'il puisse télécharger le modèle Gemma3n "gated"
 * directement depuis l'appareil vers Hugging Face — sans jamais embarquer ce
 * token dans le binaire de l'app (extractible par décompilation).
 *
 * Volontairement SANS quota (ni par utilisateur, ni global) : contrairement
 * aux autres fonctions, celle-ci n'appelle aucune API payante — le
 * téléchargement du modèle se fait directement appareil -> Hugging Face, pas
 * via cette fonction. Le seul risque à couvrir est qu'un appelant non
 * authentifié récupère le token, ce que la vérification JWT ci-dessous suffit
 * à bloquer.
 *
 * Limite de sécurité assumée : un utilisateur authentifié qui inspecte son
 * propre trafic réseau peut voir son propre token — ce mécanisme protège
 * contre l'extraction en masse depuis le binaire décompilé, pas contre un
 * utilisateur inspectant sa propre session.
 */
Deno.serve(async (req) => {
    // === GESTION DU PREFLIGHT (CORS) ===
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    const jsonHeaders = { ...corsHeaders, 'Content-Type': 'application/json' };

    try {
        // === VÉRIFICATION JWT (authentification requise, pas de quota) ===
        const auth = await authenticate(req, jsonHeaders, false);
        if (!auth.ok) {
            return auth.response;
        }

        // === RÉCUPÉRATION DU TOKEN ===
        const token = Deno.env.get('HUGGINGFACE_TOKEN');
        if (!token) {
            console.error("ERREUR CRITIQUE: Secret HUGGINGFACE_TOKEN introuvable.");
            return new Response(
                JSON.stringify({ error: 'Configuration serveur manquante (token Hugging Face).' }),
                { status: 500, headers: jsonHeaders },
            );
        }

        return new Response(JSON.stringify({ token }), {
            status: 200,
            headers: jsonHeaders,
        });
    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        console.error("Erreur fatale Edge Function (Hugging Face Token):", message);
        return new Response(JSON.stringify({ error: 'Erreur serveur. Réessaie plus tard.' }), {
            status: 500,
            headers: jsonHeaders,
        });
    }
})
