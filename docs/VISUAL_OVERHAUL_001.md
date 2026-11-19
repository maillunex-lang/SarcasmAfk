# VISUAL OVERHAUL 001 — BashLegends

> Started: 2026-11-19 · Stage F branch: `cursor/visual-overhaul-stage-f-4106` · Base: `main` @ `747a6f5`

## Goal

Bring all screens to a coherent **Premium Clean Stylized Anime Fantasy 2.5D + Premium Fantasy Mobile UI** look without violating D-ART / D-SCOPE locks.

## Stage status

| Stage | Status | Notes |
|-------|--------|-------|
| A Audit | DONE | 23 scenes inventoried; registry JSON+MD |
| B Design system | DONE | OFL fonts + DesignTokens + Theme.tres |
| C Core path | DONE | Splash/Home/Dialog/Battle + Gacha/Inventory |
| D RPG screens | DONE | Heroes/party/bestiary + map_ufa art |
| E Online systems | DONE | Guild crest/vault/board; shop/VIP TEMP |
| F Polish | DONE_VERIFIED (T-158) | Animations, Theme.tres, H13–H36 busts, gallery, debug APK |

## Constraints honored

- No CH02 / Stage E Kaeron atlases / real payments / package ID change.
- TEMP art remains labeled TEMP.
- Arena/events stay locked stubs (D-SCOPE-01).

## Stage F deliverables

- `client/themes/bashlegends_theme.tres` + `project.godot` gui/theme/custom
- TEMP dialog busts `dialog_portrait_H13.jpg` … `H36.jpg` (+ generator)
- Screen enter fades (ScreenBase), dialog portrait slide, gacha portal pulse, shop banner fade
- Gallery pack `docs/reports/visual_gallery/` + `smoke_visual_gallery.gd`
- Debug APK rebuild evidence in STATUS / QA report

## Evidence

```bash
python3 scripts/generate_dialog_busts_h13_h36.py
python3 scripts/generate_visual_gallery.py
# Godot
godot4 --headless --path client -s res://scripts/tools/smoke_visual_screens.gd
godot4 --headless --path client -s res://scripts/tools/smoke_visual_gallery.gd
bash scripts/build_debug_apk.sh
```
