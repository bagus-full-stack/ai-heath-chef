import { createClient } from "jsr:@supabase/supabase-js@2";
import { authenticate } from "./auth.ts";

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
 * Minuit UTC suivant, en ISO 8601 — moment où `day` (colonne `current_date`,
 * calculée en UTC par Postgres sur Supabase) bascule et où le compteur de
 * quota repart donc à zéro. Renvoyé au format UTC pour que l'app convertisse
 * elle-même vers l'heure locale de l'utilisateur (`quota.ts` n'a aucune idée
 * du fuseau horaire de l'appelant).
 */
function nextUtcMidnightIso(): string {
    const d = new Date();
    d.setUTCHours(24, 0, 0, 0);
    return d.toISOString();
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
// Cache court de l'état PRO par utilisateur : évite un appel RevenueCat à chaque requête IA.
// shortcut: cache par instance de fonction, un abonnement résilié reste illimité jusqu'à 60 s de plus.
const PRO_CACHE_TTL_MS = 60_000;
const PRO_CACHE_MAX_ENTRIES = 1000; // purge des entrées expirées au-delà, pour ne pas grossir sans fin
const UNLIMITED_FACTOR = 10;
const proCache = new Map<string, { value: boolean; expires: number }>();

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
    const cached = proCache.get(userId);
    if (cached && cached.expires > Date.now()) {
        return cached.value;
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
        const isPro = expiresDate === null ||
            (typeof expiresDate === "string" && new Date(expiresDate) > new Date());
        if (proCache.size >= PRO_CACHE_MAX_ENTRIES) {
            const now = Date.now();
            for (const [id, entry] of proCache) if (entry.expires <= now) proCache.delete(id);
        }
        proCache.set(userId, { value: isPro, expires: Date.now() + PRO_CACHE_TTL_MS });
        return isPro;
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
 *
 * `globalIncrement` (par défaut 1) permet d'incrémenter le compteur global
 * de plus d'1 par appel — utilisé par `meal-images` pour décompter le
 * nombre d'images réellement demandées (après plafonnement) plutôt qu'1
 * crédit par requête HTTP, qui pouvait masquer un tableau `meals` de
 * n'importe quelle taille derrière un seul appel et un seul crédit de quota.
 */
export async function checkAndIncrementQuota(
    req: Request,
    functionName: string,
    dailyLimit: number,
    corsHeaders: Record<string, string>,
    globalDailyLimit?: number,
    lang?: string,
    globalIncrement = 1,
): Promise<QuotaCheckResult> {
    const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json" };
    const isEn = lang === "en";

    const auth = await authenticate(req, jsonHeaders, isEn);
    if (!auth.ok) {
        return { ok: false, response: auth.response };
    }
    const userId = auth.userId;

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const serviceClient = createClient(supabaseUrl, serviceRoleKey);

    // Admin/PRO : plafond élargi plutôt que supprimé, sinon un seul compte peut vider le plafond global.
    const userLimit = (await hasUnlimitedQuota(serviceClient, userId)) ? dailyLimit * UNLIMITED_FACTOR : dailyLimit;
    const { data: allowed, error: quotaError } = await serviceClient.rpc(
        "increment_api_usage",
        { p_user_id: userId, p_function_name: functionName, p_daily_limit: userLimit },
    );

    if (quotaError) {
        // Une panne sur le mécanisme de quota lui-même ne doit pas bloquer
        // l'utilisateur — seul un quota effectivement dépassé bloque.
        console.error(`[QUOTA_FAIL_OPEN] Erreur quota (${functionName}) :`, quotaError.message);
        return { ok: true, userId };
    }

    if (!allowed) {
        return {
            ok: false,
            response: new Response(
                JSON.stringify({
                    error: isEn
                        ? `Daily limit reached (${userLimit}/day) for this feature. Try again tomorrow.`
                        : `Limite quotidienne atteinte (${userLimit}/jour) pour cette fonctionnalité. Réessaie demain.`,
                    resetAt: nextUtcMidnightIso(),
                }),
                { status: 429, headers: jsonHeaders },
            ),
        };
    }

    if (globalDailyLimit !== undefined) {
        const { data: globalAllowed, error: globalQuotaError } = await serviceClient.rpc(
            "increment_global_api_usage",
            { p_function_name: functionName, p_daily_limit: globalDailyLimit, p_increment: globalIncrement },
        );

        if (globalQuotaError) {
            console.error(`[QUOTA_FAIL_OPEN] Erreur quota global (${functionName}) :`, globalQuotaError.message);
        } else if (!globalAllowed) {
            return {
                ok: false,
                response: new Response(
                    JSON.stringify({
                        error: isEn
                            ? "This AI feature is in high demand today and has reached its shared limit. Try again tomorrow."
                            : "Cette fonctionnalité IA est très sollicitée aujourd'hui et a atteint sa limite partagée. Réessaie demain.",
                        resetAt: nextUtcMidnightIso(),
                    }),
                    { status: 429, headers: jsonHeaders },
                ),
            };
        }
    }

    return { ok: true, userId };
}
