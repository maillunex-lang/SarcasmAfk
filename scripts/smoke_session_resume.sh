#!/usr/bin/env bash
# T-123: auth → claim → restart API with same persist → reuse token.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADDR="${ADDR:-127.0.0.1:8091}"
PERSIST="${PERSIST:-$ROOT/server/.data/resume_smoke.json}"
rm -f "$PERSIST"
mkdir -p "$(dirname "$PERSIST")"

cd "$ROOT/server"
go build -o /tmp/bashlegends-api-resume ./cmd/api
/tmp/bashlegends-api-resume -addr ":${ADDR##*:}" -content "$ROOT/client/data" -persist "$PERSIST" &
PID=$!
cleanup() { kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true; }
trap cleanup EXIT

for i in $(seq 1 40); do curl -fsS "http://${ADDR}/healthz" >/dev/null 2>&1 && break; sleep 0.1; done
AUTH=$(curl -fsS -X POST "http://${ADDR}/v1/auth/anonymous")
TOKEN=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])' <<<"$AUTH")
ACC=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["progress"]["account_id"])' <<<"$AUTH")
curl -fsS -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"bundle_id":"RESUME-BUNDLE","soft":17,"commander_xp":2}' \
  "http://${ADDR}/v1/rewards/claim" | grep -q '"ok":true'
echo "OK claim before restart account=$ACC"

kill "$PID"; wait "$PID" 2>/dev/null || true
/tmp/bashlegends-api-resume -addr ":${ADDR##*:}" -content "$ROOT/client/data" -persist "$PERSIST" &
PID=$!
for i in $(seq 1 40); do curl -fsS "http://${ADDR}/healthz" >/dev/null 2>&1 && break; sleep 0.1; done

PROG=$(curl -fsS -H "Authorization: Bearer $TOKEN" "http://${ADDR}/v1/me/progress")
export PROG ACC
python3 - <<'PY'
import json, os
p = json.loads(os.environ["PROG"])
assert p.get("ok"), p
prog = p["progress"]
assert prog["account_id"] == os.environ["ACC"], prog
assert prog["soft_currency"] >= 17, prog
assert prog["claimed_rewards"].get("RESUME-BUNDLE") is True, prog
print("OK resume token soft=", prog["soft_currency"])
PY
echo "smoke_session_resume_ok"
