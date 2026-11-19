#!/usr/bin/env bash
# Live API E2E for CH01 RPG expansion (T-157 Slice E).
# Starts Go API, exercises SQ01–SQ05 + POI-09 + journal + skill-up, tears down.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADDR="${ADDR:-127.0.0.1:8097}"
PERSIST="${PERSIST:-$ROOT/server/.data/smoke_ch01_expansion.json}"
rm -f "$PERSIST"
mkdir -p "$(dirname "$PERSIST")"

cd "$ROOT/server"
go build -o /tmp/bashlegends-api-exp ./cmd/api
/tmp/bashlegends-api-exp -addr ":${ADDR##*:}" -content "$ROOT/client/data" -persist "$PERSIST" &
PID=$!
cleanup() { kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true; }
trap cleanup EXIT

for i in $(seq 1 50); do
  if curl -fsS "http://${ADDR}/healthz" >/dev/null 2>&1; then break; fi
  sleep 0.1
done
curl -fsS "http://${ADDR}/healthz" | grep -q '"ok":true'

AUTH=$(curl -fsS -X POST "http://${ADDR}/v1/auth/anonymous")
TOKEN=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])' <<<"$AUTH")
test -n "$TOKEN"
AUTHZ=(-H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json")

# Touch progress so persist file is written, then seed main-quest gates.
curl -fsS "${AUTHZ[@]}" "http://${ADDR}/v1/me/progress" >/dev/null
kill "$PID"
wait "$PID" 2>/dev/null || true

python3 - <<PY
import json
from pathlib import Path
path = Path("$PERSIST")
data = json.loads(path.read_text())
sessions = data.get("sessions", {})
accounts = data.get("accounts", {})
sess = sessions.get("$TOKEN")
if not sess:
    raise SystemExit("session missing for token")
acc = accounts.get(sess["account_id"])
if not acc:
    raise SystemExit("account missing")
qf = acc.setdefault("quest_flags", {})
for q in ["CH01-Q01", "CH01-Q02", "CH01-Q03", "CH01-Q04", "CH01-Q05", "CH01-Q07", "CH01-Q09", "CH01-Q10"]:
    qf[q] = True
path.write_text(json.dumps(data, indent=2))
print("OK seeded quest flags")
PY

/tmp/bashlegends-api-exp -addr ":${ADDR##*:}" -content "$ROOT/client/data" -persist "$PERSIST" &
PID=$!
for i in $(seq 1 50); do
  if curl -fsS "http://${ADDR}/healthz" >/dev/null 2>&1; then break; fi
  sleep 0.1
done

api() {
  local method="$1" path="$2" data="${3:-}"
  if [[ -n "$data" ]]; then
    curl -fsS -X "$method" "${AUTHZ[@]}" -d "$data" "http://${ADDR}${path}"
  else
    curl -fsS -X "$method" "${AUTHZ[@]}" "http://${ADDR}${path}"
  fi
}

echo "=== SQ01 any-order ==="
api POST "/v1/campaign/ch01/sidequests/CH01-SQ01/start" | grep -q '"ok":true'
for step in sq01_doc_2 sq01_doc_1 sq01_doc_3; do
  api POST "/v1/campaign/ch01/poi/POI-02/interact" "{\"action_id\":\"$step\"}" | grep -q '"ok":true'
done
CLAIM1=$(api POST "/v1/campaign/ch01/sidequests/CH01-SQ01/claim")
echo "$CLAIM1" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("ok") and d.get("already") is not True'
CLAIM1B=$(api POST "/v1/campaign/ch01/sidequests/CH01-SQ01/claim")
echo "$CLAIM1B" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("already") is True'
echo "OK SQ01"

echo "=== SQ02 sequence ==="
api POST "/v1/campaign/ch01/sidequests/CH01-SQ02/start" | grep -q '"ok":true'
BAD=$(api POST "/v1/campaign/ch01/poi/POI-04/interact" '{"action_id":"sq02_seal_gold"}')
echo "$BAD" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("puzzle_reset") is True'
for step in sq02_seal_blue sq02_seal_gold sq02_seal_empty; do
  api POST "/v1/campaign/ch01/poi/POI-04/interact" "{\"action_id\":\"$step\"}" | grep -q '"ok":true'
done
api POST "/v1/campaign/ch01/sidequests/CH01-SQ02/claim" | grep -q '"ok":true'
echo "OK SQ02"

echo "=== SQ03–SQ05 ==="
api POST "/v1/campaign/ch01/sidequests/CH01-SQ03/start" >/dev/null
for step in sq03_record_1 sq03_record_2 sq03_record_3; do
  api POST "/v1/campaign/ch01/poi/POI-05/interact" "{\"action_id\":\"$step\"}" >/dev/null
done
api POST "/v1/campaign/ch01/sidequests/CH01-SQ03/claim" | grep -q '"ok":true'

api POST "/v1/campaign/ch01/sidequests/CH01-SQ04/start" >/dev/null
for step in sq04_gen_1 sq04_gen_2 sq04_gen_3; do
  api POST "/v1/campaign/ch01/poi/POI-07/interact" "{\"action_id\":\"$step\"}" >/dev/null
done
api POST "/v1/campaign/ch01/sidequests/CH01-SQ04/claim" | grep -q '"ok":true'

api POST "/v1/campaign/ch01/sidequests/CH01-SQ05/start" >/dev/null
for step in sq05_review_hero_1 sq05_review_hero_2 sq05_upgrade_or_train; do
  api POST "/v1/campaign/ch01/poi/POI-10/interact" "{\"action_id\":\"$step\"}" >/dev/null
done
api POST "/v1/campaign/ch01/sidequests/CH01-SQ05/claim" | grep -q '"ok":true'
echo "OK SQ03-SQ05"

echo "=== POI-09 reward ==="
POI9=$(api POST "/v1/campaign/ch01/poi/POI-09/interact" '{"action_id":"stop_erase"}')
echo "$POI9" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("ok"); g=d.get("granted") or {}; assert g.get("soft")==50'
POI9B=$(api POST "/v1/campaign/ch01/poi/POI-09/interact" '{"action_id":"stop_erase"}')
echo "$POI9B" | python3 -c 'import json,sys; d=json.load(sys.stdin); g=d.get("granted") or {}; assert not g.get("soft")'
echo "OK POI-09"

echo "=== journal + skill-up ==="
api GET "/v1/campaign/ch01/journal" | grep -q '"ok":true'
api GET "/v1/campaign/ch01/sidequests" | grep -q sidequests
api POST "/v1/heroes/H01/skill-up" '{"skill_id":"ultimate"}' | grep -q '"ok":true'
echo "OK journal/skill-up"

echo "smoke_ch01_expansion_live_ok"
