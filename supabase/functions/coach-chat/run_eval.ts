/**
 * Script d'évaluation sur `eval_cases.json`.
 *
 * Deux modes, choisis automatiquement selon les variables d'environnement :
 *
 * - MOCK (par défaut, utilisable en CI sans clé) : aucun appel réseau réel.
 *   Gemini est stubbé (même approche que index_test.ts). Ne score PAS
 *   `mustContain`/`mustNotContain` (nécessiterait une vraie réponse modèle) ;
 *   vérifie à la place deux invariants structurels pour chaque cas, quel que
 *   soit son contenu : (1) aucune donnée de contexte (allergies/dailyContext)
 *   ne fuite dans `contents[]` envoyé à Gemini — seul le message utilisateur
 *   tel quel y figure ; (2) le nombre d'occurrences du délimiteur
 *   `<<<FIN_DONNEE_UTILISATEUR>>>` dans `systemInstruction` reste à sa valeur
 *   de référence (1 pour l'instruction anti-injection, +1 par bloc
 *   allergies/dailyContext réellement wrappé) — un délimiteur forgé par
 *   l'utilisateur qui aurait survécu ferait grimper ce compte.
 *
 * - RÉEL (si GEMINI_API_KEY et EVAL_AUTH_TOKEN sont tous deux définis) :
 *   appelle réellement `handleCoachChat` (donc Supabase Auth/quota + Gemini
 *   en vrai). Nécessite aussi SUPABASE_URL/SUPABASE_ANON_KEY/
 *   SUPABASE_SERVICE_ROLE_KEY et un jeton utilisateur valide dans
 *   EVAL_AUTH_TOKEN. Score chaque cas non désactivé contre ses
 *   `mustContain`/`mustNotContain` et quitte avec le code 1 si un cas échoue
 *   (utilisable comme gate CI quand une clé est fournie).
 *
 * Usage :
 *   deno run --allow-env --allow-net --allow-read supabase/functions/coach-chat/run_eval.ts
 *   GEMINI_API_KEY=... EVAL_AUTH_TOKEN=... SUPABASE_URL=... SUPABASE_ANON_KEY=... \
 *     SUPABASE_SERVICE_ROLE_KEY=... deno run --allow-env --allow-net --allow-read \
 *     supabase/functions/coach-chat/run_eval.ts
 */

import { handleCoachChat } from "./handler.ts";

interface EvalCase {
    id: string;
    message?: string;
    lang?: string;
    dietType?: string;
    allergies?: string[];
    dailyContext?: string;
    disabled?: boolean;
    comment?: string;
    mustContain?: string[];
    mustNotContain?: string[];
}

const DATA_END = "<<<FIN_DONNEE_UTILISATEUR>>>";

const casesUrl = new URL("./eval_cases.json", import.meta.url);
const cases: EvalCase[] = JSON.parse(await Deno.readTextFile(casesUrl));

function request(body: Record<string, unknown>, token: string) {
    return new Request("https://edge-fn.test/", {
        method: "POST",
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
        body: JSON.stringify(body),
    });
}

function caseBody(c: EvalCase) {
    return {
        message: c.message,
        lang: c.lang ?? "fr",
        dietType: c.dietType,
        allergies: c.allergies,
        dailyContext: c.dailyContext,
    };
}

function jsonResponse(body: unknown, status = 200) {
    return new Response(JSON.stringify(body), {
        status,
        headers: { "Content-Type": "application/json" },
    });
}

/** Stub réseau pour le mode mock : même principe que index_test.ts (pas de
 * client injectable dans checkAndIncrementQuota/callGeminiWithFallback). */
function stubFetchForMock() {
    let lastGeminiRequestBody: Record<string, unknown> | null = null;
    const original = globalThis.fetch;

    globalThis.fetch = ((input: Request | string | URL, init?: RequestInit) => {
        const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : (input as Request).url;

        if (url.includes("/auth/v1/user")) {
            return Promise.resolve(jsonResponse({ user: { id: "eval-user", email: "eval@test.local" } }));
        }
        if (url.includes("/rest/v1/profiles")) {
            return Promise.resolve(jsonResponse({ is_admin: false }));
        }
        if (url.includes("/rpc/increment_api_usage") || url.includes("/rpc/increment_global_api_usage")) {
            return Promise.resolve(jsonResponse(true));
        }
        if (url.includes("generativelanguage.googleapis.com")) {
            lastGeminiRequestBody = JSON.parse(init!.body as string);
            return Promise.resolve(jsonResponse({
                candidates: [{ content: { parts: [{ text: "Réponse factice (mode mock)." }] } }],
            }));
        }
        throw new Error(`Appel fetch non mocké en mode eval mock : ${url}`);
    }) as typeof fetch;

    return {
        restore: () => {
            globalThis.fetch = original;
        },
        lastGeminiRequestBody: () => lastGeminiRequestBody,
    };
}

function setMockEnv() {
    Deno.env.set("SUPABASE_URL", Deno.env.get("SUPABASE_URL") ?? "https://example.test");
    Deno.env.set("SUPABASE_ANON_KEY", Deno.env.get("SUPABASE_ANON_KEY") ?? "anon-key");
    Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "service-key");
    Deno.env.set("GEMINI_API_KEY", "mock-gemini-key");
}

async function runMock(): Promise<boolean> {
    console.log("Mode MOCK (GEMINI_API_KEY/EVAL_AUTH_TOKEN absents) : aucun appel réseau réel.");
    console.log("mustContain/mustNotContain non scorés ici (nécessitent une vraie réponse modèle) — seuls des invariants structurels sont vérifiés.\n");
    setMockEnv();

    let allOk = true;
    for (const c of cases) {
        if (c.disabled) {
            console.log(`SKIP ${c.id} — ${c.comment ?? "désactivé"}`);
            continue;
        }

        const stub = stubFetchForMock();
        try {
            const res = await handleCoachChat(request(caseBody(c), "mock-token"));
            const reasons: string[] = [];
            if (res.status !== 200) {
                reasons.push(`status ${res.status} (handler en erreur)`);
            }

            const sentBody = stub.lastGeminiRequestBody();
            if (sentBody) {
                const contents = sentBody.contents as { parts: { text: string }[] }[];
                if (!(contents.length === 1 && contents[0].parts[0].text === c.message)) {
                    reasons.push("contents[] envoyé à Gemini diffère du seul message utilisateur (fuite possible)");
                }

                const systemText = (sentBody.systemInstruction as { parts: { text: string }[] }).parts[0].text;
                const expectedBaseline = 1 // ANTI_INJECTION_INSTRUCTION, voir coach_prompt.ts
                    + ((c.allergies?.length ?? 0) > 0 ? 1 : 0)
                    + (c.dailyContext && c.dailyContext.trim().length > 0 ? 1 : 0);
                const occurrences = systemText.split(DATA_END).length - 1;
                if (occurrences !== expectedBaseline) {
                    reasons.push(`délimiteur présent ${occurrences} fois (attendu ${expectedBaseline}) — possible injection non neutralisée`);
                }
            }
            // sentBody === null : cas intercepté avant Gemini (filet de sécurité santé), rien à vérifier côté prompt.

            console.log(`${reasons.length === 0 ? "PASS" : "FAIL"} ${c.id}${reasons.length ? "\n       " + reasons.join("\n       ") : ""}`);
            if (reasons.length > 0) allOk = false;
        } finally {
            stub.restore();
        }
    }
    return allOk;
}

async function runReal(): Promise<boolean> {
    console.log("Mode RÉEL : appels Supabase/Gemini réels, scoring mustContain/mustNotContain.\n");
    const token = Deno.env.get("EVAL_AUTH_TOKEN")!;

    let allOk = true;
    for (const c of cases) {
        if (c.disabled) {
            console.log(`SKIP ${c.id} — ${c.comment ?? "désactivé"}`);
            continue;
        }

        const res = await handleCoachChat(request(caseBody(c), token));
        const body = await res.json();
        const reply = (body.reply ?? "") as string;
        const reasons: string[] = [];

        if (res.status !== 200) {
            reasons.push(`status ${res.status} : ${body.error ?? "erreur inconnue"}`);
        }
        for (const must of c.mustContain ?? []) {
            if (!reply.toLowerCase().includes(must.toLowerCase())) {
                reasons.push(`mustContain manquant : "${must}"`);
            }
        }
        for (const mustNot of c.mustNotContain ?? []) {
            if (reply.toLowerCase().includes(mustNot.toLowerCase())) {
                reasons.push(`mustNotContain présent : "${mustNot}"`);
            }
        }

        console.log(`${reasons.length === 0 ? "PASS" : "FAIL"} ${c.id}${reasons.length ? "\n       " + reasons.join("\n       ") : ""}`);
        if (reply) console.log(`       réponse : ${reply.slice(0, 200)}`);
        if (reasons.length > 0) allOk = false;
    }
    return allOk;
}

const useReal = !!Deno.env.get("GEMINI_API_KEY") && !!Deno.env.get("EVAL_AUTH_TOKEN");
const ok = useReal ? await runReal() : await runMock();
console.log(`\n${ok ? "Tous les cas sont passés." : "Au moins un cas a échoué."}`);
Deno.exit(ok ? 0 : 1);
