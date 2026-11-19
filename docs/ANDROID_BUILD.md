# ANDROID_BUILD.md — Debug APK toolchain (T-110)

> Release signing keys are **never** created or committed here. Use an existing release keystore only when the owner provides it via secure env (not git).

## Check

```bash
bash scripts/check_android_toolchain.sh
```

## Build debug APK

```bash
# Optional overrides:
# export ANDROID_SDK_ROOT=/path/to/sdk
# export GODOT_BIN=/path/to/Godot_v4.3-stable_linux.x86_64
# export ANDROID_DEBUG_KEYSTORE=$HOME/.android/debug.keystore
bash scripts/build_debug_apk.sh
# → build/BashLegends-debug.apk
```

## Local toolchain layout (not in git)

| Component | Expected path |
|---|---|
| Android SDK | `tools/android/sdk` or `$ANDROID_SDK_ROOT` |
| Godot 4.3 | `/tmp/godot-install/...` or `$GODOT_BIN` |
| Export templates | `~/.local/share/godot/export_templates/4.3.stable/` |
| Debug keystore | `~/.android/debug.keystore` (standard Android debug identity) |

`tools/android/` and `build/*.apk` are gitignored.

## Release keystore probe

```bash
bash scripts/check_release_keystore.sh
# exit 2 = unavailable (current cloud/VPS state: only debug keystores found;
# GitHub Actions secrets not readable with agent token)
```

## Release (blocked until owner keystore)

Requires existing keystore via env (never create/overwrite):

- `ANDROID_RELEASE_KEYSTORE` (path)
- `ANDROID_RELEASE_KEYSTORE_USER` / `ANDROID_RELEASE_KEYSTORE_PASS` (via secret store, not git/logs)

Preset stub: `AndroidRelease` in `client/export_presets.cfg` (`custom_features=bash_release` → live-only client).

## Install debug APK on phone

```bash
adb install -r build/BashLegends-debug.apk
```

Debug defaults to **mock** (offline play). Live: More → «Включить Live API» (needs reachable server URL in `client/data/net/client_config.json`).
