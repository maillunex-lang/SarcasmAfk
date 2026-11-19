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

## Release (later)

Separate step after debug verification. Requires owner-supplied keystore path + passwords via env (`ANDROID_RELEASE_KEYSTORE`, …). Do not invent a new release key if one already exists.
