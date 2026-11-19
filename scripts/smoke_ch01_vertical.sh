#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-}"
for c in /tmp/godot-install/Godot_v4.3-stable_linux.x86_64 /tmp/godot-ci/Godot_v4.3-stable_linux.x86_64; do
  [[ -z "$GODOT_BIN" && -x "$c" ]] && GODOT_BIN="$c"
done
"$GODOT_BIN" --headless --path "$ROOT/client" --import >/tmp/godot-import-vertical.log 2>&1 || true
"$GODOT_BIN" --headless --path "$ROOT/client" -s res://scripts/tools/smoke_ch01_vertical.gd
echo "smoke_ch01_vertical_shell_ok"
