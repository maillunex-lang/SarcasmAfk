#!/usr/bin/env bash
# Local mirror of CI checks (JSON + optional Godot smokes).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
import json, pathlib, sys
files = list(pathlib.Path("client/data").rglob("*.json"))
assert files, "no json"
for path in files:
    json.load(path.open())
    print("OK", path)
print("json_ok", len(files))
PY

for f in AGENTS.md docs/STATUS.md docs/TASK_QUEUE.md docs/DECISIONS.md docs/PHASE0_SPEC.md docs/V0_REVIEW.md client/project.godot; do
  test -f "$f"
  echo "OK $f"
done

GODOT_BIN="${GODOT_BIN:-}"
if [[ -z "$GODOT_BIN" ]]; then
  if [[ -x /tmp/godot-install/Godot_v4.3-stable_linux.x86_64 ]]; then
    GODOT_BIN=/tmp/godot-install/Godot_v4.3-stable_linux.x86_64
  elif command -v godot4 >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot4)"
  fi
fi

if [[ -n "${GODOT_BIN}" ]]; then
  (cd client && "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_v0a.gd)
  (cd client && "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_v0c.gd)
  (cd client && "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_ch01.gd)
  echo "godot_smoke_ok"
else
  echo "WARN: Godot not found; skipped smokes"
fi

echo "ci_validate_ok"
