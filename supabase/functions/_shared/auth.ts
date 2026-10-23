import { createClient } from "jsr:@supabase/supabase-js@2";

export type AuthResult =
    | { ok: true; userId: string }
    | { ok: false; response: Response };

/**
 * Identifie l'appelant à partir du JWT transmis par l'app (en-tête
 * Authorization, ajouté automatiquement par supabase_flutter). Renvoie une
 * Response 401 prête à l'emploi si le JWT est absent ou invalide.
 *
 * Nécessite SUPABASE_URL / SUPABASE_ANON_KEY, injectés automatiquement par
 * Supabase dans toutes les Edge Functions.
 */
export async function authenticate(
    req: Request,
    headers: Record<string, string>,
    isEn: boolean,
): Promise<AuthResult> {
    const unauthorized = (error: string): AuthResult => ({
        ok: false,
        response: new Response(JSON.stringify({ error }), { status: 401, headers }),
    });

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
        return unauthorized(isEn ? "Authentication required." : "Authentification requise.");
    }

    const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
        global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData?.user) {
        return unauthorized(isEn ? "Invalid authentication." : "Authentification invalide.");
    }
    return { ok: true, userId: userData.user.id };
}
