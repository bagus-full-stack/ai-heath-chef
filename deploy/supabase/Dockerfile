FROM postgres:15-alpine
RUN apk add --no-cache bash rsync
WORKDIR /src
COPY supabase/migrations ./migrations
COPY supabase/functions ./functions
COPY scripts/apply-supabase.sh /usr/local/bin/apply-supabase.sh
RUN chmod +x /usr/local/bin/apply-supabase.sh
# Applique puis reste actif : Coolify attend un conteneur qui tourne (résultat dans Runtime Logs).
# root volontaire : écrit dans le bind mount des fonctions, qui appartient à root.
CMD ["bash", "-c", "apply-supabase.sh /src && echo 'DEPLOY OK' && exec sleep infinity"]
