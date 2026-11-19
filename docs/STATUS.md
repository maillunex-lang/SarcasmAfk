# STATUS.md — Единый снимок состояния проекта

> Дата снимка: **2026-11-19** · Ветка: `main`  
> Debug APK toolchain готов (T-110). Release key — только от владельца.

## NOW

**Закрыто:** T-110 — проверка SDK/templates/debug keystore; `scripts/build_debug_apk.sh` собрал `build/BashLegends-debug.apk` (~131MB).  
**Дальше:** T-031 Blender pipeline scripts · T-124 CH01 polish.

## Работает / частично / заглушки

| | |
|---|---|
| **Работает** | P0 server/live/resume; debug APK build на этой машине |
| **Частично** | Live-default в APK (probe есть; нужен URL сервера на устройстве) |
| **Заглушки** | Release APK; Blender pipeline; guild live; CH02+ |

Секреты не коммитятся. `tools/android/` и `build/*.apk` в `.gitignore`.
