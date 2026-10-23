import { assertEquals } from "jsr:@std/assert@1";
import { handleHuggingFaceToken } from "./handler.ts";

function json(body: unknown) {
    return new Response(JSON.stringify(body), { status: 200, headers: { "Content-Type": "application/json" } });
}

function setEnv() {
    Deno.env.set("SUPABASE_URL", "https://example.test");
    Deno.env.set("SUPABASE_ANON_KEY", "anon-key");
    Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "service-key");
    Deno.env.set("HUGGINGFACE_TOKEN", "hf_secret_token");
    Deno.env.delete("REVENUECAT_SECRET_KEY");
}

/** `quotaAllowed` : valeur renvoyée par le RPC `increment_api_usage` ; `functionName` capture la clé de quota utilisée. */
function stubFetch(quotaAllowed: boolean) {
    const original = globalThis.fetch;
    const seen = { functionName: "", limit: 0 };
    globalThis.fetch = ((input: Request | string | URL, init?: RequestInit) => {
        const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : (input as Request).url;
        if (url.includes("/auth/v1/user")) return Promise.resolve(json({ user: { id: "user-1" } }));
        if (url.includes("/rest/v1/profiles")) return Promise.resolve(json({ is_admin: false }));
        if (url.includes("/rpc/increment_api_usage")) {
            const body = JSON.parse(init!.body as string);
            seen.functionName = body.p_function_name;
            seen.limit = body.p_daily_limit;
            return Promise.resolve(json(quotaAllowed));
        }
        return Promise.reject(new Error(`fetch inattendu : ${url}`));
    }) as typeof fetch;
    return { seen, restore: () => (globalThis.fetch = original) };
}

const authed = () => new Request("https://edge-fn.test/", { method: "POST", headers: { Authorization: "Bearer token" } });

Deno.test("handleHuggingFaceToken - sans JWT -> 401, jamais de token", async () => {
    setEnv();
    const res = await handleHuggingFaceToken(new Request("https://edge-fn.test/", { method: "POST" }));
    assertEquals(res.status, 401);
    assertEquals((await res.text()).includes("hf_secret_token"), false);
});

Deno.test("handleHuggingFaceToken - utilisateur sous le quota : reçoit le token, quota 5/jour compté", async () => {
    setEnv();
    const stub = stubFetch(true);
    try {
        const res = await handleHuggingFaceToken(authed());
        assertEquals(res.status, 200);
        assertEquals((await res.json()).token, "hf_secret_token");
        assertEquals(stub.seen.functionName, "huggingface-token");
        assertEquals(stub.seen.limit, 5);
    } finally {
        stub.restore();
    }
});

Deno.test("handleHuggingFaceToken - quota dépassé -> 429 et le token n'est jamais renvoyé", async () => {
    setEnv();
    const stub = stubFetch(false);
    try {
        const res = await handleHuggingFaceToken(authed());
        assertEquals(res.status, 429);
        assertEquals((await res.text()).includes("hf_secret_token"), false);
    } finally {
        stub.restore();
    }
});
