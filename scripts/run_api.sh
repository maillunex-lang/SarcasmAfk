#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/server"
exec go run ./cmd/api -addr "${ADDR:-:8080}" -content "$ROOT/client/data" -persist "${PERSIST:-$ROOT/server/.data/accounts.json}"
