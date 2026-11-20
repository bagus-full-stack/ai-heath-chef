import { HttpError } from "./errors.ts";

export const MAX_IMAGE_BYTES = 8 * 1024 * 1024; // 8 Mo, cohérent avec le budget Cloudflare/Gemini existant
const BASE64_IMAGE_RE = /^[A-Za-z0-9+/]+={0,2}$/;

/** Rejette (400/413) une image qui n'est pas du base64 valide ou dépasse [MAX_IMAGE_BYTES]. */
export function validateBase64Image(image: string, isEn: boolean): void {
    if (!BASE64_IMAGE_RE.test(image)) {
        throw new HttpError(400, isEn ? "The image is not valid base64 data." : "L'image n'est pas une donnée base64 valide.");
    }
    if ((image.length * 3) / 4 > MAX_IMAGE_BYTES) {
        throw new HttpError(413, isEn ? "The image is too large (8 MB max)." : "L'image est trop volumineuse (8 Mo max).");
    }
}
