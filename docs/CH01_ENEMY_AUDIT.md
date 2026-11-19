# CH01 Enemy Audit — MONSTERS-CH01-001

**Date:** 2026-11-19 · **Base:** `main` @ merge tip · **Branch:** `cursor/ch01-monsters-beaf`

## Counts

| Check | Result |
|-------|--------|
| Enemy types in battles B01–B30 | **29** (E01–E17, E20–E30, E29A) |
| E18 / E19 | **Absent — do not create** |
| `ch01_enemies.json` defs | 29 matching IDs |
| Unique on-disk sprite folders | **7** only: E01, E02, E03, E04(empty), E05, E08, E28 |

## Visual uniqueness (problem)

Many defs reuse another type’s JPG:

- E04/E07/E09/E12 → E02 sprite
- E06/E10/E13/E15/E16 → E05 sprite
- E11/E14/E17 → E03 sprite
- **E20–E30, E29A** → single `E28_inspector.jpg`
- `AssetPaths.enemy_sprite_for_type` hardcodes E28 family fallback

## Battleverify (server)

`server/internal/battleverify/sim.go`: ATB autofight, basic ATK, hero ultimates.  
**No** GUARD/MARK/SLOW/WEAKEN/SHIELD/DISRUPT/BURN/CLEANSE/HEAL, no enemy specials, no boss phases.

## Art policy

| Decision | Constraint |
|----------|------------|
| **D-ART-06** | No mass final asset generation until CH01 accepted |
| **D-SCOPE-03** | CH02 + Stage E Kaeron still blocked; TEMP art OK if labeled |
| TZ §2 / §10 | Pilot concepts first: E01, E03, E05, E10, E13, E20, E22, E28, E30 → owner approve → then remaining 20 |

## Preserve

- 12 quests, 30 battles, L01–L10, B20/B30 bosses, compositions, HP/ATK/DEF/SPD from `ch01_battles.json`, rewards
- No CH02, no H01 regen, no real payments

## Stage A verdict

Proceed with: catalog + server status/skills + bestiary + **TEMP control concepts (9)**.  
**BLOCKED until owner ACK:** mass final atlases / animation sheets for all 29.
