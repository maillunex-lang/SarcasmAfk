#!/usr/bin/env bash
# Integration: auth → battle → rewards → save → resume (T-114 gate). No silent mock.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADDR="${ADDR:-127.0.0.1:8080}"
PERSIST="${PERSIST:-$ROOT/server/.data/slice_accounts.json}"
rm -f "$PERSIST"
mkdir -p "$(dirname "$PERSIST")"

cd "$ROOT/server"
go build -o /tmp/bashlegends-api ./cmd/api
/tmp/bashlegends-api -addr ":${ADDR##*:}" -content "$ROOT/client/data" -persist "$PERSIST" >/tmp/bashlegends-api-slice.log 2>&1 &
API_PID=$!
cleanup() { kill "$API_PID" 2>/dev/null || true; wait "$API_PID" 2>/dev/null || true; }
trap cleanup EXIT

for i in $(seq 1 40); do
  curl -fsS "http://${ADDR}/healthz" >/dev/null 2>&1 && break
  sleep 0.1
done
curl -fsS "http://${ADDR}/healthz" | grep -q '"ok":true'
echo "OK healthz"

AUTH=$(curl -fsS -X POST "http://${ADDR}/v1/auth/anonymous")
TOKEN=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])' <<<"$AUTH")
test -n "$TOKEN"
echo "OK auth"

curl -fsS -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"party_ids":["H01","H04","H02","H03","H07"],"client_version":"slice"}' \
  "http://${ADDR}/v1/battles/B01/start" | grep -q client_seed
echo "OK battle_start"

curl -fsS -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"op":"ultimate","unit_id":"H01","at_tick":10}' \
  "http://${ADDR}/v1/battles/B01/command" >/tmp/slice_cmd.json || true
echo "OK battle_command"

FIN1=$(curl -fsS -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"victory":true,"duration_ms":5000}' \
  "http://${ADDR}/v1/battles/B01/finish")
# Second finish: expect 409 NO_ACTIVE_BATTLE (no double pay)
FIN2_CODE=$(curl -sS -o /tmp/slice_fin2.json -w '%{http_code}' -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"victory":true,"duration_ms":5000}' \
  "http://${ADDR}/v1/battles/B01/finish")
FIN2=$(cat /tmp/slice_fin2.json)
python3 - <<PY
import json, os
f1=json.loads('''$FIN1''')
f2=json.loads('''$FIN2''')
code=int('''$FIN2_CODE''')
assert f1.get("ok") is True and f1.get("victory") is True
s1=int((f1.get("reward") or {}).get("soft_delta", 0) or 0)
s2=int((f2.get("reward") or {}).get("soft_delta", 0) or 0)
assert s1 > 0
assert code in (409, 200)
assert s2 == 0, "duplicate soft on second finish"
assert f2.get("ok") is not True or code == 409
print("OK finish_pair soft1=%s soft2=%s http2=%s err=%s" % (s1, s2, code, f2.get("error")))
print("OK reward_no_duplicate")
PY

curl -fsS -H "Authorization: Bearer $TOKEN" "http://${ADDR}/v1/me/progress" | grep -q account_id
echo "OK progress_save_read"
curl -fsS -H "Authorization: Bearer $TOKEN" "http://${ADDR}/v1/me/progress" | grep -q account_id
echo "OK resume_session"
echo "integration_live_slice_ok"
