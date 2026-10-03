/** Headers CORS communs à toutes les Edge Functions du projet (appel direct depuis Flutter web/mobile). */
export const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
