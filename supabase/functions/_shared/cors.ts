/** Headers CORS communs à toutes les Edge Functions du projet (appel direct depuis Flutter web/mobile). */
// ALLOWED_ORIGIN (secret Supabase, ex. https://app.exemple.com) restreint l'origine du site web ; absent -> '*'.
export const corsHeaders = {
    'Access-Control-Allow-Origin': Deno.env.get('ALLOWED_ORIGIN') ?? '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
