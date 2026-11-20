/** Headers CORS communs à toutes les Edge Functions du projet (appel depuis Flutter mobile : l'origine n'est pas restreinte). */
export const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
