#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/server"
ARGS=(-addr "${ADDR:-:8080}" -content "$ROOT/client/data")
if [[ -n "${DATABASE_URL:-}" ]]; then
  ARGS+=(-database-url "$DATABASE_URL")
  if [[ -n "${REDIS_ADDR:-}" ]]; then
    ARGS+=(-redis "$REDIS_ADDR")
  fi
  ARGS+=(-migrate "$ROOT/server/migrations")
else
  ARGS+=(-persist "${PERSIST:-$ROOT/server/.data/accounts.json}")
fi
exec go run ./cmd/api "${ARGS[@]}"
