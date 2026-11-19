# VISUAL_QA_REPORT.md — VO-001

## Automated

| Check | Result |
|-------|--------|
| `python3 scripts/audit_visual_assets.py` | Pass (broken=0) when run |
| Godot `smoke_visual_screens.gd` | **PASS** (Theme + H13/H36 busts + 12 screens) |
| Godot `smoke_visual_gallery.gd` | **PASS** (gallery pack on disk) |
| `python3 scripts/generate_visual_gallery.py` | **PASS** → `docs/reports/visual_gallery/` |
| `build_debug_apk.sh` | **PASS** (Stage F cycle) → `build/BashLegends-debug.apk` |

## Manual / visual

| Screen | Check | Result |
|--------|-------|--------|
| Splash | Brand/fonts/fade | Theme + ScreenBase enter fade |
| Home | Display title + hero fade | Hero stage tween |
| Dialog | BG + H13–H36 busts | Busts wired; portrait slide |
| Battle | Victory chrome | Unchanged this PR |
| Gacha | Portal pulse | Looping alpha pulse |
| Shop | Banner enter | Fade-in |
| Party / Bestiary / Map / Guild | Dedicated BGs | Prior stages |

## Gallery

See [`reports/visual_gallery/MANIFEST.md`](reports/visual_gallery/MANIFEST.md) — compare/after PNGs (TEMP composites; headless GPU capture unavailable).

## Remaining (honest)

1. Combat/enemy art still TEMP (Stage E Kaeron blocked — T-131).
2. VIP/chat light polish only.
3. Device visual accept still owner (T-128).
4. Gallery shots are asset composites, not runtime Godot framebuffer captures.
