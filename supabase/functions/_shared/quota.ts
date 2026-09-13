import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * Résultat de la vérification de quota : soit l'appel est autorisé (`ok:
 * true`), soit une Response prête à être renvoyée telle quelle (401/429)
 * explique pourquoi il ne l'est pas.
 */
export interface QuotaCheckResult {
    ok: boolean;
    userId?: string;
    response?: Response;
}

/**
 * Identifie l'utilisateur appelant à partir du JWT transmis par l'app
 * (transféré automatiquement par supabase_flutter dans l'en-tête
 * Authorization), puis incrémente son compteur d'appels quotidien pour
 * cette fonction. Bloque l'appel (429) s'il dépasse la limite du jour, ou
 * si l'appelant n'est pas authentifié (401).
 *
 * Nécessite les secrets SUPABASE_URL / SUPABASE_ANON_KEY /
 * SUPABASE_SERVICE_ROLE_KEY, injectés automatiquement par Supabase dans
 * toutes les Edge Functions — rien à configurer manuellement.
 */
export async function checkAndIncrementQuota(
    req: Request,
    functionName: string,
    dailyLimit: number,
    corsHeaders: Record<string, string>,
): Promise<QuotaCheckResult> {
    const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json" };

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
        return {
            ok: false,
            response: new Response(
                JSON.stringify({ error: "Authentification requise." }),
                { status: 401, headers: jsonHeaders },
            ),
        };
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const userClient = createClient(supabaseUrl, anonKey, {
        global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData?.user) {
        return {
            ok: false,
            response: new Response(
                JSON.stringify({ error: "Authentification invalide." }),
                { status: 401, headers: jsonHeaders },
            ),
        };
    }
    const userId = userData.user.id;

    const serviceClient = createClient(supabaseUrl, serviceRoleKey);
    const { data: allowed, error: quotaError } = await serviceClient.rpc(
        "increment_api_usage",
        { p_user_id: userId, p_function_name: functionName, p_daily_limit: dailyLimit },
    );

    if (quotaError) {
        // Une panne sur le mécanisme de quota lui-même ne doit pas bloquer
        // l'utilisateur — seul un quota effectivement dépassé bloque.
        console.error(`Erreur quota (${functionName}) :`, quotaError.message);
        return { ok: true, userId };
    }

    if (!allowed) {
        return {
            ok: false,
            response: new Response(
                JSON.stringify({
                    error: `Limite quotidienne atteinte (${dailyLimit}/jour) pour cette fonctionnalité. Réessaie demain.`,
                }),
                { status: 429, headers: jsonHeaders },
            ),
        };
    }

    return { ok: true, userId };
}
