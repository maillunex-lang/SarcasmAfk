#!/usr/bin/env bash
# Start Go API, run curl checks + optional Godot live smoke, tear down.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADDR="${ADDR:-127.0.0.1:8080}"
PERSIST="${PERSIST:-$ROOT/server/.data/smoke_accounts.json}"
rm -f "$PERSIST"
mkdir -p "$(dirname "$PERSIST")"

cd "$ROOT/server"
go build -o /tmp/bashlegends-api ./cmd/api
/tmp/bashlegends-api -addr ":${ADDR##*:}" -content "$ROOT/client/data" -persist "$PERSIST" &
PID=$!
cleanup() { kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true; }
trap cleanup EXIT

for i in $(seq 1 40); do
  if curl -fsS "http://${ADDR}/healthz" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done
curl -fsS "http://${ADDR}/healthz" | grep -q '"ok":true'
echo "OK healthz"

AUTH=$(curl -fsS -X POST "http://${ADDR}/v1/auth/anonymous")
TOKEN=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])' <<<"$AUTH")
test -n "$TOKEN"
echo "OK auth"

curl -fsS -H "Authorization: Bearer $TOKEN" "http://${ADDR}/v1/me/progress" | grep -q account_id
curl -fsS "http://${ADDR}/v1/content/heroes" | grep -q heroes
curl -fsS "http://${ADDR}/v1/content/battles/B01" | grep -q battle_id

curl -fsS -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"party_ids":["H01","H02","H03","H04","H07"],"client_version":"smoke"}' \
  "http://${ADDR}/v1/battles/B01/start" | grep -q client_seed
curl -fsS -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"victory":true,"duration_ms":900}' \
  "http://${ADDR}/v1/battles/B01/finish" | grep -q '"ok":true'

# persist check: kill and restart, same token
kill "$PID"
wait "$PID" 2>/dev/null || true
/tmp/bashlegends-api -addr ":${ADDR##*:}" -content "$ROOT/client/data" -persist "$PERSIST" &
PID=$!
for i in $(seq 1 40); do
  if curl -fsS "http://${ADDR}/healthz" >/dev/null 2>&1; then break; fi
  sleep 0.1
done
curl -fsS -H "Authorization: Bearer $TOKEN" "http://${ADDR}/v1/me/progress" | grep -q account_id
echo "OK persist reload"

GODOT_BIN="${GODOT_BIN:-}"
if [[ -z "$GODOT_BIN" ]]; then
  if [[ -x /tmp/godot-install/Godot_v4.3-stable_linux.x86_64 ]]; then
    GODOT_BIN=/tmp/godot-install/Godot_v4.3-stable_linux.x86_64
  elif [[ -x /tmp/godot-ci/Godot_v4.3-stable_linux.x86_64 ]]; then
    GODOT_BIN=/tmp/godot-ci/Godot_v4.3-stable_linux.x86_64
  elif command -v godot4 >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot4)"
  fi
fi
if [[ -n "${GODOT_BIN}" ]]; then
  (cd "$ROOT/client" && timeout 60 "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_live_api.gd)
  echo "OK godot live smoke"
else
  echo "WARN: Godot not found; skipped live Godot smoke"
fi

echo "smoke_live_api_ok"
