#!/usr/bin/env bash
# Inventory Android/Godot export toolchain (T-110). Exit 0 if debug-ready.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MISS=0
ok() { echo "OK  $1"; }
bad() { echo "MISS $1"; MISS=$((MISS+1)); }

GODOT_BIN="${GODOT_BIN:-}"
for c in \
  /tmp/godot-install/Godot_v4.3-stable_linux.x86_64 \
  /tmp/godot-ci/Godot_v4.3-stable_linux.x86_64; do
  [[ -z "$GODOT_BIN" && -x "$c" ]] && GODOT_BIN="$c"
done
command -v godot4 >/dev/null 2>&1 && GODOT_BIN="${GODOT_BIN:-$(command -v godot4)}"
[[ -n "$GODOT_BIN" && -x "$GODOT_BIN" ]] && ok "Godot: $GODOT_BIN ($("$GODOT_BIN" --version 2>/dev/null | head -1))" || bad "Godot 4.3 binary"

TEMPL="${GODOT_TEMPLATES:-$HOME/.local/share/godot/export_templates/4.3.stable}"
[[ -f "$TEMPL/android_debug.apk" ]] && ok "Export templates: $TEMPL" || bad "Godot 4.3 android_debug.apk templates"

SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$ROOT/tools/android/sdk}}"
[[ -d "$SDK/platform-tools" && -d "$SDK/build-tools" ]] && ok "Android SDK: $SDK" || bad "Android SDK (platform-tools/build-tools)"

JAVA_BIN="${JAVA_HOME:+$JAVA_HOME/bin/java}"
JAVA_BIN="${JAVA_BIN:-$(command -v java || true)}"
if [[ -n "$JAVA_BIN" ]]; then ok "Java: $($JAVA_BIN -version 2>&1 | head -1)"; else bad "Java JDK"; fi

KS="${ANDROID_DEBUG_KEYSTORE:-$HOME/.android/debug.keystore}"
[[ -f "$KS" ]] && ok "Debug keystore: $KS (release key not required for debug)" || bad "Android debug.keystore"

[[ -f "$ROOT/client/export_presets.cfg" ]] && ok "export_presets.cfg" || bad "client/export_presets.cfg"

if [[ "$MISS" -gt 0 ]]; then
  echo "toolchain_incomplete missing=$MISS"
  exit 1
fi
echo "toolchain_debug_ready"
exit 0
