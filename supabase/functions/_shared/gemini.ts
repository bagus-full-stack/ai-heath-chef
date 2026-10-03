/**
 * Essaie chaque modèle de [models] dans l'ordre jusqu'à ce qu'un réponde
 * avec du texte, au lieu de dépendre d'un seul modèle qui pourrait être
 * temporairement indisponible, hors quota ou hors du niveau d'accès.
 *
 * Chaque appelant garde SA PROPRE liste `MODELS` (elles divergent
 * actuellement entre fonctions — voir README) : cette fonction ne fait que
 * mutualiser le mécanisme de cascade (fetch, timeout, retry, logs), pas le
 * contenu des listes.
 *
 * `maxModelsTried` plafonne le nombre de modèles réellement essayés (les
 * suivants dans la liste sont ignorés), et `timeoutMs` borne la durée
 * d'attente par modèle via AbortController — un modèle qui ne répond jamais
 * ne doit pas faire attendre l'utilisateur indéfiniment.
 */
export const GEMINI_MODEL_TIMEOUT_MS = 8000;
export const GEMINI_MAX_MODELS_TRIED = 5;

export interface GeminiCascadeResult {
    text: string;
    usedModel: string;
}

export async function callGeminiWithFallback(
    apiKey: string,
    models: string[],
    requestBody: Record<string, unknown>,
    options?: { timeoutMs?: number; maxModelsTried?: number },
): Promise<GeminiCascadeResult> {
    const timeoutMs = options?.timeoutMs ?? GEMINI_MODEL_TIMEOUT_MS;
    const maxModelsTried = options?.maxModelsTried ?? GEMINI_MAX_MODELS_TRIED;

    let lastError: string | null = null;

    for (const modelName of models.slice(0, maxModelsTried)) {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), timeoutMs);
        try {
            console.log(`Tentative avec le modèle : ${modelName}...`);

            const response = await fetch(
                `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`,
                {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(requestBody),
                    signal: controller.signal,
                },
            );

            const data = await response.json();

            if (data.error) {
                console.warn(`Échec ${modelName} : ${data.error.message}`);
                lastError = data.error.message;
                continue;
            }

            const textResponse = data.candidates?.[0]?.content?.parts?.[0]?.text;
            if (!textResponse) {
                console.warn(`Échec ${modelName} : réponse vide ou sans texte généré.`);
                lastError = 'Réponse vide ou sans texte généré.';
                continue;
            }

            return { text: textResponse, usedModel: modelName };
        } catch (err) {
            const message = (err as Error).name === 'AbortError'
                ? `Timeout dépassé (${timeoutMs}ms)`
                : (err as Error).message;
            console.warn(`Erreur réseau avec ${modelName} : ${message}`);
            lastError = message;
            continue;
        } finally {
            clearTimeout(timeout);
        }
    }

    throw new Error(lastError ?? 'Tous les modèles ont échoué.');
}
