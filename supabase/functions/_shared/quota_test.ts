import { assertEquals } from "jsr:@std/assert@1";
import { checkAndIncrementQuota } from "./quota.ts";

/**
 * `checkAndIncrementQuota` crée ses propres clients supabase-js en interne
 * (pas d'injection possible sans changer sa signature) : on stub `fetch`
 * pour simuler les réponses REST/Auth de Supabase plutôt que d'appeler un
 * vrai projet. URLs vérifiées via une sonde manuelle (voir conversation) :
 * GET /auth/v1/user, GET /rest/v1/profiles?..., POST /rest/v1/rpc/<nom>.
 */
function setEnv() {
    Deno.env.set("SUPABASE_URL", "https://example.test");
    Deno.env.set("SUPABASE_ANON_KEY", "anon-key");
    Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "service-key");
    Deno.env.delete("REVENUECAT_SECRET_KEY");
}

function jsonResponse(body: unknown) {
    return new Response(JSON.stringify(body), {
        status: 200,
        headers: { "Content-Type": "application/json" },
    });
}

/** `rpcResults` associe un nom de RPC (increment_api_usage, increment_global_api_usage) à la valeur booléenne qu'il doit renvoyer. */
function stubFetch(options: { authOk: boolean; isAdmin?: boolean; rpcResults?: Record<string, boolean> }) {
    const original = globalThis.fetch;
    globalThis.fetch = ((input: Request | string | URL, _init?: RequestInit) => {
        const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : (input as Request).url;

        if (url.includes("/auth/v1/user")) {
            return Promise.resolve(
                options.authOk
                    ? jsonResponse({ user: { id: "user-1", email: "a@b.com" } })
                    : new Response(JSON.stringify({ message: "invalid token" }), { status: 401 }),
            );
        }
        if (url.includes("/rest/v1/profiles")) {
            return Promise.resolve(jsonResponse({ is_admin: options.isAdmin ?? false }));
        }
        for (const [fnName, allowed] of Object.entries(options.rpcResults ?? {})) {
            if (url.includes(`/rpc/${fnName}`)) {
                return Promise.resolve(jsonResponse(allowed));
            }
        }
        throw new Error(`Appel fetch non mocké : ${url}`);
    }) as typeof fetch;

    return () => {
        globalThis.fetch = original;
    };
}

function authRequest(token: string | null = "valid-token") {
    return new Request("https://edge-fn.test/", {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
    });
}

Deno.test("checkAndIncrementQuota - token invalide (header Authorization absent) -> 401", async () => {
    setEnv();
    const result = await checkAndIncrementQuota(authRequest(null), "test-fn", 10, {});
    assertEquals(result.ok, false);
    assertEquals(result.response?.status, 401);
});

Deno.test("checkAndIncrementQuota - premier appel de la journée (quota non atteint) -> autorisé", async () => {
    setEnv();
    const restore = stubFetch({ authOk: true, rpcResults: { increment_api_usage: true } });
    try {
        const result = await checkAndIncrementQuota(authRequest(), "test-fn", 10, {});
        assertEquals(result.ok, true);
        assertEquals(result.userId, "user-1");
    } finally {
        restore();
    }
});

Deno.test("checkAndIncrementQuota - quota quotidien par utilisateur atteint -> 429", async () => {
    setEnv();
    const restore = stubFetch({ authOk: true, rpcResults: { increment_api_usage: false } });
    try {
        const result = await checkAndIncrementQuota(authRequest(), "test-fn", 10, {});
        assertEquals(result.ok, false);
        assertEquals(result.response?.status, 429);
    } finally {
        restore();
    }
});

Deno.test("checkAndIncrementQuota - quota global atteint -> 429", async () => {
    setEnv();
    const restore = stubFetch({
        authOk: true,
        rpcResults: { increment_api_usage: true, increment_global_api_usage: false },
    });
    try {
        const result = await checkAndIncrementQuota(authRequest(), "test-fn", 10, {}, 100);
        assertEquals(result.ok, false);
        assertEquals(result.response?.status, 429);
    } finally {
        restore();
    }
});

/**
 * L'atomicité réelle (et la réinitialisation quotidienne via `day default
 * current_date`) vient d'un seul `INSERT ... ON CONFLICT DO UPDATE ...
 * RETURNING` côté Postgres (migration 0008) — pas testable sans une vraie
 * base depuis cette suite Deno. Ce test vérifie seulement que
 * `checkAndIncrementQuota` lui-même n'introduit pas sa propre race (ex: lire
 * le compteur avant d'incrémenter) et respecte fidèlement, pour N appels
 * concurrents, le compte que l'incrément atomique simulé leur renvoie.
 */
Deno.test("checkAndIncrementQuota - N appels concurrents n'autorisent jamais plus que la limite", async () => {
    setEnv();
    const dailyLimit = 2;
    let atomicCounter = 0;
    const original = globalThis.fetch;
    globalThis.fetch = ((input: Request | string | URL) => {
        const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : (input as Request).url;
        if (url.includes("/auth/v1/user")) {
            return Promise.resolve(jsonResponse({ user: { id: "user-1", email: "a@b.com" } }));
        }
        if (url.includes("/rest/v1/profiles")) {
            return Promise.resolve(jsonResponse({ is_admin: false }));
        }
        if (url.includes("/rpc/increment_api_usage")) {
            // Incrément synchrone (avant tout `await`) : émule le même
            // contrat d'atomicité qu'un seul statement SQL côté Postgres.
            atomicCounter += 1;
            return Promise.resolve(jsonResponse(atomicCounter <= dailyLimit));
        }
        throw new Error(`Appel fetch non mocké : ${url}`);
    }) as typeof fetch;

    try {
        const results = await Promise.all(
            Array.from({ length: 5 }, () => checkAndIncrementQuota(authRequest(), "test-fn", dailyLimit, {})),
        );
        assertEquals(results.filter((r) => r.ok).length, dailyLimit);
        assertEquals(results.filter((r) => !r.ok && r.response?.status === 429).length, 5 - dailyLimit);
    } finally {
        globalThis.fetch = original;
    }
});
