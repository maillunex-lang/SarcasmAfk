# VISUAL_QA_REPORT.md — VO-001

## Automated

| Check | Result |
|-------|--------|
| `python3 scripts/audit_visual_assets.py` | Pass (broken=0) |
| `python3 scripts/validate_monsters_ch01.py` | Pass (unchanged) |
| Godot `smoke_v0a.gd` | Pass |
| Godot `smoke_visual_screens.gd` | Pass (9 screens + key VO assets) |
| AssetPaths broken constants | 0 |

## Manual / visual (this PR)

| Screen | Check | Result |
|--------|-------|--------|
| Splash | Brand/fonts/fade | Code done; Godot screenshot pending |
| Home | Display title + hero fade | Code done |
| Dialog | Dedicated BG + display title | Code done |
| Battle | Victory display chrome + fade-in | Code done |
| Gacha | Portal integrated | Code done |
| Inventory | Dedicated BG | Code done |
| Party | Dedicated BG + display title | Code done |
| Bestiary | Dedicated BG + display title | Code done |
| Heroes | Rarity-colored card borders | Code done |
| Guild | Crest/vault/board icons | Code done |
| Map | Ufa campaign art | Code done |
| Gacha | Rarity reveal frames | Code done |

## Remaining defects (honest)

1. VIP/chat still light polish only.
2. No Godot Theme `.tres` yet.
3. Dialog portraits H13–H36 missing.
4. Combat/enemy art still TEMP (Stage E Kaeron blocked).
5. Real Godot before/after screenshot gallery incomplete.
6. Android debug APK not rebuilt in this PR.

## Classification counts (Stage A heuristic)

See `docs/VISUAL_AUDIT.md` — 23 screens; majority `TEMP` / `POLISHED_TEMP`; arena/events `LOCKED_STUB`.
