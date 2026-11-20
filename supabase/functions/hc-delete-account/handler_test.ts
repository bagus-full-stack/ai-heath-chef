import { assertEquals } from "jsr:@std/assert@1";
import { handleDeleteAccount } from "./handler.ts";
import { STORAGE_BUCKETS } from "./storage_buckets.ts";

// auth-js exige un UUID pour deleteUser.
const USER_ID = "11111111-1111-4111-8111-111111111111";

function setEnv() {
    Deno.env.set("SUPABASE_URL", "https://example.test");
    Deno.env.set("SUPABASE_ANON_KEY", "anon-key");
    Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "service-key");
}

function json(body: unknown, status = 200) {
    return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

/**
 * Simule Supabase (Auth, RPC, Storage) et enregistre l'ordre des appels
 * destructifs dans `events`. Chaque bucket contient un fichier au premier
 * `list`, puis est vide.
 */
function stubFetch(options: { rateLimitAllowed?: boolean; storageListStatus?: number } = {}) {
    const original = globalThis.fetch;
    const events: string[] = [];
    const listed = new Set<string>();
    globalThis.fetch = ((input: Request | string | URL, init?: RequestInit) => {
        const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : (input as Request).url;
        const method = init?.method ?? (input instanceof Request ? input.method : "GET");

        if (url.includes("/auth/v1/user")) return Promise.resolve(json({ id: USER_ID, email: "a@b.com" }));
        if (url.includes("/rpc/check_delete_account_rate_limit")) {
            return Promise.resolve(json(options.rateLimitAllowed ?? true));
        }
        const list = url.match(/\/storage\/v1\/object\/list\/([^/?]+)/);
        if (list) {
            if (options.storageListStatus) return Promise.resolve(json({ message: "boom" }, options.storageListStatus));
            events.push(`list:${list[1]}`);
            const first = !listed.has(list[1]);
            listed.add(list[1]);
            return Promise.resolve(json(first ? [{ name: "a.jpg" }] : []));
        }
        const remove = url.match(/\/storage\/v1\/object\/([^/?]+)$/);
        if (remove && method === "DELETE") {
            events.push(`remove:${remove[1]}`);
            return Promise.resolve(json([]));
        }
        if (url.includes(`/auth/v1/admin/users/${USER_ID}`) && method === "DELETE") {
            events.push("deleteUser");
            return Promise.resolve(json({}));
        }
        return Promise.reject(new Error(`fetch inattendu : ${method} ${url}`));
    }) as typeof fetch;
    return { events, restore: () => (globalThis.fetch = original) };
}

function request(body: unknown) {
    return new Request("https://edge-fn.test/", {
        method: "POST",
        headers: { Authorization: "Bearer token", "Content-Type": "application/json" },
        body: JSON.stringify(body),
    });
}

Deno.test("handleDeleteAccount - confirm=true : tout le Storage est vidé AVANT la suppression de l'utilisateur", async () => {
    setEnv();
    const stub = stubFetch();
    try {
        const res = await handleDeleteAccount(request({ confirm: true }));
        assertEquals(res.status, 200);
        assertEquals(stub.events.at(-1), "deleteUser");
        assertEquals(stub.events.filter((e) => e === "deleteUser").length, 1);
        for (const bucket of STORAGE_BUCKETS) {
            assertEquals(stub.events.includes(`remove:${bucket}`), true);
        }
    } finally {
        stub.restore();
    }
});

Deno.test("handleDeleteAccount - sans confirm=true -> 400, rien n'est supprimé", async () => {
    setEnv();
    const stub = stubFetch();
    try {
        const res = await handleDeleteAccount(request({}));
        assertEquals(res.status, 400);
        assertEquals(stub.events, []);
    } finally {
        stub.restore();
    }
});

Deno.test("handleDeleteAccount - limite de tentatives atteinte -> 429, rien n'est supprimé", async () => {
    setEnv();
    const stub = stubFetch({ rateLimitAllowed: false });
    try {
        const res = await handleDeleteAccount(request({ confirm: true }));
        assertEquals(res.status, 429);
        assertEquals(stub.events, []);
    } finally {
        stub.restore();
    }
});

Deno.test("handleDeleteAccount - échec du Storage -> 500 et le compte Auth n'est PAS supprimé (nouvel essai possible)", async () => {
    setEnv();
    const stub = stubFetch({ storageListStatus: 500 });
    try {
        const res = await handleDeleteAccount(request({ confirm: true }));
        assertEquals(res.status, 500);
        assertEquals(stub.events.includes("deleteUser"), false);
    } finally {
        stub.restore();
    }
});
