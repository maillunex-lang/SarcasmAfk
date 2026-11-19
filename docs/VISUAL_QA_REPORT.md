# VISUAL_QA_REPORT.md — VO-001

## Automated

| Check | Result |
|-------|--------|
| `python3 scripts/audit_visual_assets.py` | See run output |
| `python3 scripts/validate_monsters_ch01.py` | Pass (unchanged) |
| Godot `smoke_v0a.gd` | Required before merge |
| AssetPaths broken constants | 0 expected |

## Manual / visual (this PR)

| Screen | Check | Result |
|--------|-------|--------|
| Splash | Brand/fonts/fade | Code done; Godot screenshot pending/CI |
| Home | Display title + hero fade | Code done |
| Gacha | Portal integrated | Code done |
| Inventory | Dedicated BG | Code done |

## Remaining defects (honest)

1. Most screen BGs still shared/reused (party/bestiary/events).
2. No Godot Theme `.tres` yet.
3. Dialog portraits H13–H36 missing.
4. `assets/maps/` empty.
5. Combat/enemy art still TEMP (not Stage E).
6. Real Godot before/after screenshot gallery incomplete until headless capture lands.
7. Android debug APK not rebuilt in this PR.

## Classification counts (Stage A heuristic)

See `docs/VISUAL_AUDIT.md` — 23 screens; majority `TEMP` / `POLISHED_TEMP`; arena/events `LOCKED_STUB`.
