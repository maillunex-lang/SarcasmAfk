#!/usr/bin/env bash
# Concurrent API load smoke (T-099). Starts memory API unless one is already up.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADDR="${ADDR:-127.0.0.1:8090}"
N="${LOAD_N:-20}"
STARTED=0

if ! curl -fsS "http://${ADDR}/healthz" >/dev/null 2>&1; then
  cd "$ROOT/server"
  go build -o /tmp/bashlegends-api-load ./cmd/api
  /tmp/bashlegends-api-load -addr ":${ADDR##*:}" -content "$ROOT/client/data" &
  PID=$!
  STARTED=1
  cleanup() { kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true; }
  trap cleanup EXIT
  for i in $(seq 1 50); do
    curl -fsS "http://${ADDR}/healthz" >/dev/null 2>&1 && break
    sleep 0.1
  done
fi

export LOAD_ADDR="$ADDR"
export LOAD_N="$N"
python3 - <<'PY'
import json, os, concurrent.futures, urllib.request

addr = os.environ["LOAD_ADDR"]
n = int(os.environ.get("LOAD_N", "20"))

def one(i: int):
    def post(path, data=None, token=None):
        req = urllib.request.Request(f"http://{addr}{path}", method="POST")
        req.add_header("Content-Type", "application/json")
        if token:
            req.add_header("Authorization", f"Bearer {token}")
        body = None if data is None else json.dumps(data).encode()
        with urllib.request.urlopen(req, data=body, timeout=10) as r:
            return json.load(r)
    def get(path, token=None):
        req = urllib.request.Request(f"http://{addr}{path}")
        if token:
            req.add_header("Authorization", f"Bearer {token}")
        with urllib.request.urlopen(req, timeout=10) as r:
            return json.load(r)
    auth = post("/v1/auth/anonymous")
    tok = auth["token"]
    get("/v1/me/progress", tok)
    post("/v1/battles/B01/start", {"party_ids": ["H01","H02","H03","H04","H07"]}, tok)
    fin = post("/v1/battles/B01/finish", {"victory": True, "duration_ms": 1500}, tok)
    assert fin.get("ok"), fin
    return fin.get("victory")

ok = 0
with concurrent.futures.ThreadPoolExecutor(max_workers=min(n, 16)) as ex:
    futs = [ex.submit(one, i) for i in range(n)]
    for f in concurrent.futures.as_completed(futs):
        f.result()
        ok += 1
print(f"load_smoke_ok n={ok}")
PY

echo "load_smoke_ok"
