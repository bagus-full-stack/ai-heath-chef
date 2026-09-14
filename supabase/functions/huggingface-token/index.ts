import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

// 1. Headers CORS complets
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

/**
 * Fonction autonome (pas d'import vers _shared/) : déployée depuis l'éditeur
 * du Dashboard Supabase, qui ne bundle pas les fichiers hors de la fonction
 * elle-même (voir les 5 autres Edge Functions du projet, même contrainte).
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
        const authHeader = req.headers.get('Authorization');
        if (!authHeader) {
            return new Response(
                JSON.stringify({ error: 'Authentification requise.' }),
                { status: 401, headers: jsonHeaders },
            );
        }

        const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
        const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;

        const userClient = createClient(supabaseUrl, anonKey, {
            global: { headers: { Authorization: authHeader } },
        });
        const { data: userData, error: userError } = await userClient.auth.getUser();
        if (userError || !userData?.user) {
            return new Response(
                JSON.stringify({ error: 'Authentification invalide.' }),
                { status: 401, headers: jsonHeaders },
            );
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
        console.error("Erreur fatale Edge Function (Hugging Face Token):", (error as Error).message);
        return new Response(JSON.stringify({ error: (error as Error).message }), {
            status: 400,
            headers: jsonHeaders,
        });
    }
})
