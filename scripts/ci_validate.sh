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
required = [
  "client/assets/branding/bg_map.jpg",
  "client/assets/branding/bg_afk.jpg",
  "client/assets/branding/bg_gacha.jpg",
  "client/assets/ui/icons/ui_icon_map.jpg",
  "client/assets/ui/icons/ui_icon_heroes.jpg",
  "client/assets/characters/H04/H04_portrait.jpg",
  "client/assets/characters/H12/H12_full.jpg",
  "client/assets/enemies/E02/E02_paper_guard.jpg",
  "client/assets/enemies/E28/E28_inspector.jpg",
  "client/assets/locations/L02/loc_L02_mid.jpg",
  "client/assets/locations/L10/loc_L10_mid.jpg",
  "client/assets/arenas/ARENA-L05/arena_L05_floor.jpg",
  "client/assets/arenas/ARENA-L10/arena_L10_floor.jpg",
]
missing = [p for p in required if not pathlib.Path(p).is_file()]
if missing:
    print("MISSING ASSETS", missing, file=sys.stderr)
    sys.exit(1)
print("assets_ok", len(required))
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
  (cd client && "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_api.gd)
  (cd client && "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_mvp.gd)
  echo "godot_smoke_ok"
else
  echo "WARN: Godot not found; skipped smokes"
fi

echo "ci_validate_ok"
