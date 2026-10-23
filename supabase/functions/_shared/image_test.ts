import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { HttpError } from "./errors.ts";
import { MAX_IMAGE_BYTES, validateBase64Image } from "./image.ts";

Deno.test("accepte une petite image base64 valide", () => {
    validateBase64Image("aGVsbG8=", false);
});

Deno.test("rejette du texte non base64 avec un 400", () => {
    const err = assertThrows(() => validateBase64Image("pas du base64 !", true), HttpError);
    assertEquals(err.status, 400);
});

Deno.test("rejette une image trop grosse avec un 413", () => {
    const tooBig = "A".repeat(Math.ceil((MAX_IMAGE_BYTES * 4) / 3) + 4);
    const err = assertThrows(() => validateBase64Image(tooBig, false), HttpError);
    assertEquals(err.status, 413);
});
