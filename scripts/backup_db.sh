#!/usr/bin/env bash
# Dump Postgres (T-096). No-op with tip if DATABASE_URL unset.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${BACKUP_DIR:-$ROOT/server/.data/backups}"
mkdir -p "$OUT_DIR"
if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL not set — nothing to dump (memory backend)."
  echo "Example: DATABASE_URL=postgres://bashlegends:bashlegends@127.0.0.1:5432/bashlegends?sslmode=disable $0"
  exit 0
fi
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUT="$OUT_DIR/bashlegends_$STAMP.sql"
if command -v pg_dump >/dev/null 2>&1; then
  pg_dump "$DATABASE_URL" --no-owner --no-acl > "$OUT"
  echo "OK wrote $OUT"
else
  echo "pg_dump not found; install postgresql-client" >&2
  exit 1
fi
