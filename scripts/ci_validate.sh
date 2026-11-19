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
  "client/assets/combat/H01/H01_idle.png",
  "client/assets/combat/H02/H02_idle.png",
  "client/assets/combat/H03/H03_idle.png",
  "client/assets/combat/E01/E01_idle.png",
  "client/assets/branding/bg_inventory.jpg",
  "client/assets/branding/bg_party.jpg",
  "client/assets/branding/bg_bestiary.jpg",
  "client/assets/branding/bg_dialog.jpg",
  "client/assets/maps/map_ufa_campaign.jpg",
  "client/assets/ui/guild/guild_icon_crest.jpg",
  "client/assets/ui/guild/guild_icon_vault.jpg",
  "client/assets/ui/guild/guild_icon_board.jpg",
  "client/assets/ui/gacha/gacha_frame_ssr.png",
  "client/assets/branding/gacha_portal.jpg",
  "client/assets/fonts/Manrope-Regular.ttf",
  "client/assets/fonts/Cinzel-SemiBold.ttf",
]

missing = [p for p in required if not pathlib.Path(p).is_file()]
if missing:
    print("MISSING ASSETS", missing, file=sys.stderr)
    sys.exit(1)
print("assets_ok", len(required))
PY

python3 scripts/validate_ch01_expansion.py
python3 scripts/check_doc_links.py
python3 scripts/check_ai_docs.py
python3 scripts/check_content_refs.py
python3 scripts/audit_repo.py --json-only >/dev/null

for f in AGENTS.md docs/STATUS.md docs/TASK_QUEUE.md docs/DECISIONS.md docs/PHASE0_SPEC.md docs/PHASE2_AUDIT.md docs/V0_REVIEW.md docs/CH01_RPG_EXPANSION.md client/project.godot server/go.mod server/cmd/api/main.go; do
  test -f "$f"
  echo "OK $f"
done

if command -v go >/dev/null 2>&1; then
  (cd server && go test ./... -count=1)
  echo "go_api_ok"
  # memory live smoke (unset PG so script stays offline-capable)
  env -u DATABASE_URL -u REDIS_ADDR bash scripts/smoke_live_api.sh
  echo "live_api_ok"
  env -u DATABASE_URL -u REDIS_ADDR LOAD_N=12 bash scripts/load_smoke.sh
  echo "load_smoke_ok"
  env -u DATABASE_URL -u REDIS_ADDR bash scripts/smoke_session_resume.sh
  echo "session_resume_ok"
  env -u DATABASE_URL -u REDIS_ADDR bash scripts/smoke_ch01_expansion_live.sh
  echo "ch01_expansion_live_ok"
else
  echo "WARN: go not found; skipped API tests"
fi

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
  (cd client && "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_visual_screens.gd)
  python3 scripts/generate_visual_gallery.py
  (cd client && "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_visual_gallery.gd)
  (cd client && "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_v0c.gd)
  (cd client && "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_ch01.gd)
  (cd client && "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_ch01_expansion.gd)
  (cd client && "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_api.gd)
  (cd client && "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_mvp.gd)
  (cd client && "$GODOT_BIN" --headless --path . -s res://scripts/tools/smoke_ch01_vertical.gd)
  echo "godot_smoke_ok"
else
  echo "WARN: Godot not found; skipped smokes"
fi

if command -v go >/dev/null 2>&1; then
  env -u DATABASE_URL -u REDIS_ADDR bash scripts/integration_live_slice.sh
  echo "integration_live_slice_ok"
fi

echo "ci_validate_ok"
