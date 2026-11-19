# ONLINE SYSTEMS AUDIT — P1 kickoff

Date: 2026-11-19  
Scope: chat, DMs, guilds, gacha, 36 heroes, progression, shop, VIP  
Owner authorization: full parallel development unlocked (no CH01-accept gate). CH02 and Stage E Kaeron atlases remain blocked. TEMP art only.

## Status table

| System | Status | Existing assets | Gap |
|---|---|---|---|
| Auth / sessions | READY | `httpapi` auth, sessions table, mock+live | — |
| Economy currencies | PARTIAL | soft/hard/tickets on `AccountProgress` | No ledger, no shop SKUs, no VIP points |
| Heroes catalog H01–H12 | READY | `HEROES.md`, `roster_mvp.json`, combat load | — |
| Heroes catalog H13–H36 | PARTIAL → DRAFT added | IDs reserved in this PR (`roster_release36.json`) | Owner must approve draft names/balance |
| Hero ownership | PARTIAL | `owned_heroes` map | No per-hero level/stars/equip instances |
| Hero progression | MISSING → P2 slice | GDD principles only | Level/stars/awaken/skills/equip/power API |
| Gacha | PARTIAL | `banners_mvp.json`, mock summon | Server RNG/pity/history incomplete; rates DRAFT |
| Guilds | PARTIAL | Stub list/create/join | Roles, vault, quests, chat channel missing |
| Global chat / DM | MISSING | — | WS + persistence + moderation |
| Shop | MISSING | — | Catalog + free/test purchase flow |
| VIP | MISSING | — | Levels config + rewards |
| Admin config UI | PARTIAL | Live toggle, balance | No gacha/shop/VIP/chat admin |
| Lunex Visual Studio | MISSING | — | Compatible IDs (`lunex://…`) only |
| CH01 campaign | READY (polish PR) | Quests/battles/locations | Accept gate no longer blocks online systems |
| CH02 | BLOCKED | Outline only | Needs separate owner permission |
| Kaeron Stage E atlases | BLOCKED | Pipeline drafts H01–H03 | Owner Blender; TEMP elsewhere |

## Approved invariants (do not reinvent)

- Classes: tank, warrior, mage, support  
- Rarities: N, R, SR, SSR, UR, Mythic  
- Factions: 6 normal + 2 mythic (mythic names TBD)  
- Party size 5; story ≠ automatic grant  
- Server-authoritative currency, summons, progression, membership  
- Vertical 9:16 Premium Clean Stylized Fantasy  

## Draft parameters needing owner approval

See `docs/ONLINE_SYSTEMS_SPEC.md` §Draft knobs and `client/data/progression/progression_draft.json`.

## Compatibility

- Preserve hero IDs H01–H12, quest IDs, battle IDs, account JSON fields.  
- New fields are additive. Migration `003_online_foundation.sql` creates new tables without rewriting `accounts` core columns (JSONB extensions via optional columns).
