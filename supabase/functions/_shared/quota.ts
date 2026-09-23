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
 * True si l'appelant doit passer la limite quotidienne PAR UTILISATEUR
 * (admin de confiance, voir migration 0007, ou abonné PRO actif côté
 * RevenueCat). Le disjoncteur GLOBAL (voir `globalDailyLimit`) protège lui
 * quand même le budget API partagé, même pour ces comptes.
 *
 * Repli sur `false` (donc quota normal appliqué) si `REVENUECAT_SECRET_KEY`
 * n'est pas configuré ou si l'appel à RevenueCat échoue — une panne du
 * fournisseur d'abonnement ne doit jamais accorder un accès illimité.
 */
async function hasUnlimitedQuota(
    // deno-lint-ignore no-explicit-any
    serviceClient: any,
    userId: string,
): Promise<boolean> {
    const { data: profile } = await serviceClient
        .from("profiles")
        .select("is_admin")
        .eq("user_id", userId)
        .maybeSingle();
    if (profile?.is_admin) {
        return true;
    }

    const revenueCatSecretKey = Deno.env.get("REVENUECAT_SECRET_KEY");
    if (!revenueCatSecretKey) {
        return false;
    }

    try {
        const res = await fetch(`https://api.revenuecat.com/v1/subscribers/${userId}`, {
            headers: { Authorization: `Bearer ${revenueCatSecretKey}` },
        });
        if (!res.ok) {
            return false;
        }
        const body = await res.json();
        const expiresDate = body?.subscriber?.entitlements?.pro?.expires_date;
        return expiresDate === null ||
            (typeof expiresDate === "string" && new Date(expiresDate) > new Date());
    } catch (_) {
        return false;
    }
}

/**
 * Identifie l'utilisateur appelant à partir du JWT transmis par l'app
 * (transféré automatiquement par supabase_flutter dans l'en-tête
 * Authorization), puis incrémente son compteur d'appels quotidien pour
 * cette fonction. Bloque l'appel (429) s'il dépasse la limite du jour, ou
 * si l'appelant n'est pas authentifié (401).
 *
 * Si `globalDailyLimit` est fourni, vérifie aussi et incrémente un compteur
 * GLOBAL (tous utilisateurs confondus) pour cette fonction — un disjoncteur
 * qui protège le budget/débit partagé de la clé API commune à toute l'app
 * (voir migration 0009) contre un épuisement agrégé, même quand chaque
 * utilisateur individuellement reste sous sa propre limite.
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
    globalDailyLimit?: number,
    lang?: string,
): Promise<QuotaCheckResult> {
    const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json" };
    const isEn = lang === "en";

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
        return {
            ok: false,
            response: new Response(
                JSON.stringify({ error: isEn ? "Authentication required." : "Authentification requise." }),
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
                JSON.stringify({ error: isEn ? "Invalid authentication." : "Authentification invalide." }),
                { status: 401, headers: jsonHeaders },
            ),
        };
    }
    const userId = userData.user.id;
    const serviceClient = createClient(supabaseUrl, serviceRoleKey);

    if (!(await hasUnlimitedQuota(serviceClient, userId))) {
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
                        error: isEn
                            ? `Daily limit reached (${dailyLimit}/day) for this feature. Try again tomorrow.`
                            : `Limite quotidienne atteinte (${dailyLimit}/jour) pour cette fonctionnalité. Réessaie demain.`,
                    }),
                    { status: 429, headers: jsonHeaders },
                ),
            };
        }
    }

    if (globalDailyLimit !== undefined) {
        const { data: globalAllowed, error: globalQuotaError } = await serviceClient.rpc(
            "increment_global_api_usage",
            { p_function_name: functionName, p_daily_limit: globalDailyLimit },
        );

        if (globalQuotaError) {
            console.error(`Erreur quota global (${functionName}) :`, globalQuotaError.message);
        } else if (!globalAllowed) {
            return {
                ok: false,
                response: new Response(
                    JSON.stringify({
                        error: isEn
                            ? "This AI feature is in high demand today and has reached its shared limit. Try again tomorrow."
                            : "Cette fonctionnalité IA est très sollicitée aujourd'hui et a atteint sa limite partagée. Réessaie demain.",
                    }),
                    { status: 429, headers: jsonHeaders },
                ),
            };
        }
    }

    return { ok: true, userId };
}
