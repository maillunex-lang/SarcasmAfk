# MONSTERS-CH01-001

29 CH01 enemies with server-authoritative skills (Draft), TEMP concepts + multi-frame atlases, Bestiary.

## Status

| Layer | State |
|-------|-------|
| Catalog `enemy_catalog_ch01.json` | DONE — 29 IDs, no E18/E19 |
| Server statuses + specials + E20/E30 phases | DONE — `battleverify` `2026.11.19-monsters1` |
| Unique TEMP concepts (all 29) | DONE — `assets/enemies/E*/concept.jpg` |
| Combat idle (single-frame TEMP) | DONE — `idle.jpg` + `combat/E*/E*_idle.png` |
| Multi-frame atlases (idle/attack/hit/death/special/telegraph) | DONE — TEMP procedural 8×256 JPEG strips + JSON (`atlases/*.jpg`) |
| Battle playback | DONE — `CombatSpriteRect` idle loop + attack/hit/death on action |
| VFX / SFX packs | **AUDIO/VFX_BLOCKED** or MISSING |
| Bestiary UI | DONE (More → Бестиарий) |
| Battle HP/ATK compositions/rewards | Unchanged |

## Generator

```bash
python3 scripts/generate_temp_enemy_atlases.py
python3 scripts/validate_monsters_ch01.py
```

## Not FINAL

Per D-ART-06 these are **TEMP** procedural atlases from concepts, not Stage E / accepted final Blender atlases.
