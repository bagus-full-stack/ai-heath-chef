import { assertEquals } from "jsr:@std/assert@1";
import { handleMealImages } from "./handler.ts";

function json(body: unknown) {
    return new Response(JSON.stringify(body), { status: 200, headers: { "Content-Type": "application/json" } });
}

/** Simule Auth/quota Supabase ; tout fournisseur d'images échoue (images nulles), seul le quota nous intéresse. */
function stubFetch() {
    const original = globalThis.fetch;
    const seen = { userIncrement: 0, globalIncrement: 0 };
    globalThis.fetch = ((input: Request | string | URL, init?: RequestInit) => {
        const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : (input as Request).url;
        if (url.includes("/auth/v1/user")) return Promise.resolve(json({ user: { id: "user-1" } }));
        if (url.includes("/rest/v1/profiles")) return Promise.resolve(json({ is_admin: false }));
        if (url.includes("/rpc/increment_api_usage")) {
            seen.userIncrement++;
            return Promise.resolve(json(true));
        }
        if (url.includes("/rpc/increment_global_api_usage")) {
            seen.globalIncrement = JSON.parse(init!.body as string).p_increment;
            return Promise.resolve(json(true));
        }
        return Promise.reject(new Error("fournisseur d'images indisponible (test)"));
    }) as typeof fetch;
    return { seen, restore: () => (globalThis.fetch = original) };
}

function request(meals: unknown[]) {
    return new Request("https://edge-fn.test/", {
        method: "POST",
        headers: { Authorization: "Bearer token", "Content-Type": "application/json" },
        body: JSON.stringify({ meals, lang: "fr" }),
    });
}

function setEnv() {
    Deno.env.set("SUPABASE_URL", "https://example.test");
    Deno.env.set("SUPABASE_ANON_KEY", "anon-key");
    Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "service-key");
    Deno.env.delete("REVENUECAT_SECRET_KEY");
    // Cloudflare configuré : décalage minimal entre les requêtes d'un lot (300 ms).
    Deno.env.set("CLOUDFLARE_ACCOUNT_ID", "acc");
    Deno.env.set("CLOUDFLARE_API_TOKEN", "tok");
}

Deno.test("handleMealImages - 8 repas envoyés : tronqué à 6, et le quota global compte 6 images (pas 1 appel)", async () => {
    setEnv();
    const stub = stubFetch();
    try {
        const meals = Array.from({ length: 8 }, (_, i) => ({ title: `Repas ${i}` }));
        const res = await handleMealImages(request(meals));
        assertEquals(res.status, 200);
        assertEquals((await res.json()).images.length, 6);
        assertEquals(stub.seen.globalIncrement, 6);
        assertEquals(stub.seen.userIncrement, 1);
    } finally {
        stub.restore();
    }
});

Deno.test("handleMealImages - titres invalides ignorés ; aucun repas valide -> aucune image et aucun crédit consommé", async () => {
    setEnv();
    const stub = stubFetch();
    try {
        const res = await handleMealImages(request([{ title: "" }, { title: "x".repeat(201) }, { nope: 1 }]));
        assertEquals(res.status, 200);
        assertEquals((await res.json()).images, []);
        assertEquals(stub.seen.userIncrement, 0);
    } finally {
        stub.restore();
    }
});
