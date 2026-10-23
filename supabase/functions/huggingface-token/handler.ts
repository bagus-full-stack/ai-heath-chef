import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { corsHeaders } from "../_shared/cors.ts"
import { checkAndIncrementQuota } from "../_shared/quota.ts"

// Le téléchargement du modèle (~3 Go) peut être relancé après un échec réseau : quelques essais par jour suffisent.
const DAILY_LIMIT = 5;

/**
 * À déployer avec la CLI (`supabase functions deploy`, comme la CI le fait) :
 * l'éditeur du Dashboard ne bundle pas les imports vers `_shared/`.
 *
 * Donne le token Hugging Face (secret HUGGINGFACE_TOKEN) à un utilisateur
 * authentifié, pour qu'il puisse télécharger le modèle Gemma3n "gated"
 * directement depuis l'appareil vers Hugging Face — sans jamais embarquer ce
 * token dans le binaire de l'app (extractible par décompilation).
 *
 * Quota par utilisateur uniquement (DAILY_LIMIT/jour, pas de quota global :
 * aucune API payante n'est appelée ici). L'inscription étant ouverte,
 * « authentifié » ne suffit pas : sans limite, un script pourrait créer des
 * comptes en série et collecter le token. Le token doit aussi être un token
 * Hugging Face en LECTURE SEULE, limité au modèle Gemma (à vérifier dans les
 * réglages Hugging Face).
 *
 * Limite de sécurité assumée : un utilisateur authentifié qui inspecte son
 * propre trafic réseau peut voir son propre token — ce mécanisme protège
 * contre l'extraction en masse depuis le binaire décompilé, pas contre un
 * utilisateur inspectant sa propre session.
 */
export async function handleHuggingFaceToken(req: Request): Promise<Response> {
    // === GESTION DU PREFLIGHT (CORS) ===
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    const jsonHeaders = { ...corsHeaders, 'Content-Type': 'application/json' };

    try {
        // === AUTHENTIFICATION (JWT) + QUOTA PAR UTILISATEUR ===
        const quota = await checkAndIncrementQuota(req, 'huggingface-token', DAILY_LIMIT, corsHeaders);
        if (!quota.ok) {
            return quota.response!;
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
}
