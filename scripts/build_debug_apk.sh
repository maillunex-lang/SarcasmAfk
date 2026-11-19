#!/usr/bin/env bash
# Reproducible Godot 4.3 Android **debug** APK (T-110). Never creates/commits release keys.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -z "${JAVA_HOME:-}" ]]; then
  for j in /usr/lib/jvm/java-17-openjdk-amd64 /usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/default-java; do
    [[ -x "$j/bin/java" ]] && JAVA_HOME="$j" && break
  done
fi
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export PATH="${JAVA_HOME}/bin:${PATH}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$ROOT/tools/android/sdk}}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"

bash "$ROOT/scripts/check_android_toolchain.sh"

GODOT_BIN="${GODOT_BIN:-}"
for c in \
  /tmp/godot-install/Godot_v4.3-stable_linux.x86_64 \
  /tmp/godot-ci/Godot_v4.3-stable_linux.x86_64; do
  [[ -z "$GODOT_BIN" && -x "$c" ]] && GODOT_BIN="$c"
done
command -v godot4 >/dev/null 2>&1 && GODOT_BIN="${GODOT_BIN:-$(command -v godot4)}"

KS_SRC="${ANDROID_DEBUG_KEYSTORE:-$HOME/.android/debug.keystore}"
KS_GODOT="$HOME/.local/share/godot/keystores/debug.keystore"
mkdir -p "$(dirname "$KS_GODOT")"
if [[ -f "$KS_SRC" ]]; then
  cp -f "$KS_SRC" "$KS_GODOT"
elif [[ ! -f "$KS_GODOT" ]]; then
  keytool -genkeypair -keystore "$KS_GODOT" -storepass android -alias androiddebugkey \
    -keypass android -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
fi

# Patch editor settings (Godot may reset empties on first launch).
SETTINGS="$HOME/.config/godot/editor_settings-4.3.tres"
mkdir -p "$(dirname "$SETTINGS")"
if [[ ! -f "$SETTINGS" ]]; then
  cat > "$SETTINGS" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
EOF
fi
python3 - <<PY
from pathlib import Path
import re
p = Path("$SETTINGS")
text = p.read_text()
def set_kv(text, key, value):
    line = f'{key} = "{value}"'
    pat = re.compile(re.escape(key) + r'\s*=\s*".*"')
    if pat.search(text):
        return pat.sub(line, text)
    return text.rstrip() + "\n" + line + "\n"
text = set_kv(text, "export/android/java_sdk_path", "$JAVA_HOME")
text = set_kv(text, "export/android/android_sdk_path", "$ANDROID_SDK_ROOT")
text = set_kv(text, "export/android/debug_keystore", "$KS_GODOT")
text = set_kv(text, "export/android/debug_keystore_user", "androiddebugkey")
text = set_kv(text, "export/android/debug_keystore_pass", "android")
p.write_text(text)
PY

# Patch local export_presets keystore path for this machine (file may be dirty; OK locally)
PRESET="$ROOT/client/export_presets.cfg"
python3 - <<PY
from pathlib import Path
import re
p = Path("$PRESET")
t = p.read_text()
t = re.sub(r'keystore/debug="[^"]*"', 'keystore/debug="$KS_GODOT"', t)
t = re.sub(r'keystore/debug_user="[^"]*"', 'keystore/debug_user="androiddebugkey"', t)
t = re.sub(r'keystore/debug_password="[^"]*"', 'keystore/debug_password="android"', t)
p.write_text(t)
PY

OUT_DIR="$ROOT/build"
mkdir -p "$OUT_DIR"
OUT_APK="$OUT_DIR/BashLegends-debug.apk"
rm -f "$OUT_APK"

cd "$ROOT/client"
"$GODOT_BIN" --headless --path . --import >/tmp/godot-import-apk.log 2>&1 || true
"$GODOT_BIN" --headless --path . --export-debug "AndroidDebug" "$OUT_APK" 2>&1 | tee /tmp/godot-export-debug.log

# Restore portable preset (empty debug keystore path) so we don't commit machine paths
python3 - <<'PY'
from pathlib import Path
import re
p = Path("/workspace/client/export_presets.cfg")
t = p.read_text()
t = re.sub(r'keystore/debug="[^"]*"', 'keystore/debug=""', t)
p.write_text(t)
PY

if [[ ! -f "$OUT_APK" ]]; then
  echo "FAIL: APK not produced. See /tmp/godot-export-debug.log" >&2
  exit 1
fi
ls -lh "$OUT_APK"
echo "debug_apk_ok path=$OUT_APK"
