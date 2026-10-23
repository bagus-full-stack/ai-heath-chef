import { assert, assertEquals } from "jsr:@std/assert@1";
import { handleImageAnalysis } from "./analyze_image.ts";

const CONFIG = { functionName: "analyze-test", prompt: "PROMPT-DE-TEST" };

function jsonResponse(body: unknown, status = 200) {
    return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

/** Simule Supabase Auth/RPC et Gemini ; `geminiText` est le texte renvoyé par le modèle. */
function stubFetch(geminiText: string) {
    const original = globalThis.fetch;
    const seen = { quotaFunction: "", geminiBody: "", geminiKeyHeader: "" };
    globalThis.fetch = ((input: Request | string | URL, init?: RequestInit) => {
        const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : input.url;
        if (url.includes("/auth/v1/user")) return Promise.resolve(jsonResponse({ user: { id: "user-1" } }));
        if (url.includes("/rest/v1/profiles")) return Promise.resolve(jsonResponse({ is_admin: false }));
        if (url.includes("/rpc/increment_api_usage")) {
            seen.quotaFunction = JSON.parse(init!.body as string).p_function_name;
            return Promise.resolve(jsonResponse(true));
        }
        if (url.includes("/rpc/increment_global_api_usage")) return Promise.resolve(jsonResponse(true));
        if (url.includes("generativelanguage.googleapis.com")) {
            seen.geminiBody = init!.body as string;
            seen.geminiKeyHeader = (init!.headers as Record<string, string>)["x-goog-api-key"];
            return Promise.resolve(jsonResponse({ candidates: [{ content: { parts: [{ text: geminiText }] } }] }));
        }
        return Promise.reject(new Error(`fetch inattendu : ${url}`));
    }) as typeof fetch;
    return { seen, restore: () => (globalThis.fetch = original) };
}

function setEnv() {
    Deno.env.set("SUPABASE_URL", "https://example.test");
    Deno.env.set("SUPABASE_ANON_KEY", "anon-key");
    Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "service-key");
    Deno.env.set("GEMINI_API_KEY", "test-gemini-key");
    Deno.env.delete("REVENUECAT_SECRET_KEY");
}

function request(body: unknown) {
    return new Request("https://example.test/fn", {
        method: "POST",
        headers: { Authorization: "Bearer token", "Content-Type": "application/json" },
        body: typeof body === "string" ? body : JSON.stringify(body),
    });
}

Deno.test("handleImageAnalysis - image absente -> 400", async () => {
    setEnv();
    const stub = stubFetch("{}");
    try {
        const res = await handleImageAnalysis(request({ lang: "fr" }), CONFIG);
        assertEquals(res.status, 400);
    } finally {
        stub.restore();
    }
});

Deno.test("handleImageAnalysis - succès : clé de quota, prompt et clé Gemini en en-tête", async () => {
    setEnv();
    const stub = stubFetch('```json\n{"ingredients":[]}\n```');
    try {
        const res = await handleImageAnalysis(request({ image: "aGVsbG8=", lang: "fr" }), CONFIG);
        assertEquals(res.status, 200);
        assertEquals(await res.json(), { ingredients: [] });
        assertEquals(stub.seen.quotaFunction, "analyze-test");
        assert(stub.seen.geminiBody.includes("PROMPT-DE-TEST"));
        assertEquals(stub.seen.geminiKeyHeader, "test-gemini-key");
    } finally {
        stub.restore();
    }
});

Deno.test("handleImageAnalysis - JSON invalide du modèle : message générique, texte brut non exposé", async () => {
    setEnv();
    const stub = stubFetch("SECRET-TEXTE-DU-MODELE pas du json");
    try {
        const res = await handleImageAnalysis(request({ image: "aGVsbG8=", lang: "fr" }), CONFIG);
        const raw = await res.text();
        assert(res.status >= 400);
        assert(!raw.includes("SECRET-TEXTE-DU-MODELE"));
    } finally {
        stub.restore();
    }
});

Deno.test("handleImageAnalysis - `names` personnalise la consigne de langue", async () => {
    setEnv();
    const stub = stubFetch('{"ingredients":[]}');
    try {
        const config = { ...CONFIG, names: { en: "product name", fr: "nom du produit" } };
        const res = await handleImageAnalysis(request({ image: "aGVsbG8=", lang: "en" }), config);
        assertEquals(res.status, 200);
        assert(stub.seen.geminiBody.includes("(product name)"));
    } finally {
        stub.restore();
    }
});
