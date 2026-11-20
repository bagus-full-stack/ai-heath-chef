#!/usr/bin/env bash
# Runs ON the VPS. Usage: apply-supabase.sh <dir containing migrations/ and functions/>
# Two modes: docker exec (default, on the VPS host) or direct psql when PGHOST is set
# (inside the Coolify deployer container; then also set PGPASSWORD, FUNCTIONS_DIR, SUDO="").
# Env overrides: DB_CONTAINER, FUNCTIONS_DIR, DB_NAME
set -euo pipefail

SRC="${1:?usage: apply-supabase.sh <dir>}"
DB_NAME="${DB_NAME:-postgres}"
SCHEMA="${APP_SCHEMA:-health_chef}"

# APP_SCHEMA is interpolated into SQL: accept plain identifiers only
[[ "$SCHEMA" =~ ^[a-z_][a-z0-9_]*$ ]] || { echo "ERROR: invalid APP_SCHEMA '$SCHEMA'" >&2; exit 1; }
[ -d "$SRC/migrations" ] || { echo "ERROR: $SRC/migrations not found" >&2; exit 1; }

SUDO="${SUDO-sudo -n}"
if [ -n "${PGHOST:-}" ]; then
  : "${PGPASSWORD:?PGPASSWORD missing: set POSTGRES_PASSWORD in Coolify}"
  psql -h "$PGHOST" -U supabase_admin -d "$DB_NAME" -qtAc 'SELECT 1' >/dev/null     || { echo "ERROR: cannot connect to $PGHOST (wrong password or network)" >&2; exit 1; }
else
  DB_CONTAINER="${DB_CONTAINER:-$(docker ps --filter name=supabase-db- --format '{{.Names}}' | head -1)}"
  [ -n "$DB_CONTAINER" ] || { echo "supabase-db container not found" >&2; exit 1; }
fi

# New objects land in the app schema, not public (migration 09 isolates the old ones)
psql_run() {
  if [ -n "${PGHOST:-}" ]; then
    PGOPTIONS="-c search_path=$SCHEMA,extensions,public"       psql -h "$PGHOST" -U supabase_admin -d "$DB_NAME" -v ON_ERROR_STOP=1 -q "$@"
  else
    docker exec -i -e PGOPTIONS="-c search_path=$SCHEMA,extensions,public"       "$DB_CONTAINER" psql -U supabase_admin -d "$DB_NAME" -v ON_ERROR_STOP=1 -q "$@"
  fi
}

echo "== schema + tracking table"
psql_run <<SQL
CREATE SCHEMA IF NOT EXISTS $SCHEMA;
GRANT USAGE ON SCHEMA $SCHEMA TO authenticated, service_role;
CREATE TABLE IF NOT EXISTS $SCHEMA._migrations (
  filename text PRIMARY KEY, checksum text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now());
SQL

echo "== migrations"
for f in $(ls "$SRC"/migrations/*.sql 2>/dev/null | sort); do
  name=$(basename "$f"); sum=$(sha256sum "$f" | cut -d' ' -f1)
  prev=$(psql_run -tA -c "SELECT checksum FROM $SCHEMA._migrations WHERE filename='$name'")
  if [ -n "$prev" ]; then
    # shortcut: applied files are immutable; add a new migration instead of editing one
    [ "$prev" = "$sum" ] || { echo "ERROR: $name changed after being applied" >&2; exit 1; }
    echo "skip   $name"; continue
  fi
  echo "apply  $name"
  { cat "$f"; echo; echo "INSERT INTO $SCHEMA._migrations(filename, checksum) VALUES ('$name','$sum');"; } | psql_run -1
done

psql_run -c "NOTIFY pgrst, 'reload schema'" >/dev/null

echo "== functions"
# This script cannot see the edge-functions container env: list what the functions read so it can be checked in Coolify
if [ -d "$SRC/functions" ]; then
  echo "functions read env (must be in the edge-functions compose 'environment'):"
  grep -rhoE "Deno\.env\.get\(['\"][A-Z0-9_]+" "$SRC/functions" | sed -E "s/.*['\"]//" | grep -v '^SUPABASE_' | sort -u | sed 's/^/  - /'
fi
if [ -d "$SRC/functions" ]; then
  [ -n "${PGHOST:-}" ] || FUNCTIONS_DIR="${FUNCTIONS_DIR:-$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/home/deno/functions"}}{{.Source}}{{end}}{{end}}' \
    "$(docker ps --filter name=supabase-edge-functions- --format '{{.Names}}' | head -1)")}"
  [ -n "$FUNCTIONS_DIR" ] || { echo "functions dir not found" >&2; exit 1; }
  # shortcut: no --delete (functions dir is shared by all apps); remove stale functions by hand, upgrade by prefixing function names per app
  # main/ and hello/ belong to Supabase self-host: never touched
  $SUDO rsync -a --exclude=/main --exclude=/hello --exclude=deno.json "$SRC/functions/" "$FUNCTIONS_DIR/"
  echo "synced -> $FUNCTIONS_DIR"
fi
echo "done"
