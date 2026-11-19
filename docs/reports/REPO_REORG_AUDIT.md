# REPO_REORG_AUDIT.md — REPO-REORG-001

> Snapshot: **2026-11-19T14:54:53.533574+00:00** · SHA `7b820a1692375620a19577b7125c98933d708a35` · branch `cursor/chore-repo-reorg-001-beaf`
> Machine inventory: [`repo_inventory.json`](repo_inventory.json)

## Scope

Read-only inventory of **tracked** files at HEAD. No deletions performed.

## Totals

- Tracked files: **1145**
- Status counts: `{'KEEP': 1143, 'UNKNOWN': 2}`
- Subsystem counts: `{'ci': 1, 'root': 3, 'client': 864, 'godot-import': 143, 'other': 1, 'docs': 36, 'docs-reports': 7, 'scripts': 18, 'secrets': 1, 'server': 59, 'tools': 12}`
- Duplicate content groups (non-media sample ≤8MB): **0**
- Secret-name hits (paths only): **1**
- Local untracked (not in git): **416**

## Large files (≥512 KiB)

| Size | Path |
|------|------|
| 660326 | `client/assets/characters/H15/H15_portrait.jpg` |
| 620702 | `client/assets/characters/H14/H14_portrait.jpg` |
| 598732 | `client/assets/ui/shop/shop_banner_featured.jpg` |
| 558478 | `client/assets/characters/H30/H30_portrait.jpg` |
| 554085 | `client/assets/characters/H23/H23_portrait.jpg` |
| 548821 | `client/assets/enemies/E30/concept.jpg` |
| 548821 | `client/assets/enemies/E30/idle.jpg` |
| 548821 | `client/assets/enemies/E30/portrait.jpg` |
| 548816 | `client/assets/ui/equipment/eq_icon_unchanging_protocol.jpg` |
| 548542 | `client/assets/enemies/E20/concept.jpg` |
| 548542 | `client/assets/enemies/E20/idle.jpg` |
| 548542 | `client/assets/enemies/E20/portrait.jpg` |
| 538432 | `client/assets/enemies/E12/concept.jpg` |
| 538432 | `client/assets/enemies/E12/idle.jpg` |
| 538432 | `client/assets/enemies/E12/portrait.jpg` |
| 537763 | `client/assets/enemies/E27/concept.jpg` |
| 537763 | `client/assets/enemies/E27/idle.jpg` |
| 537763 | `client/assets/enemies/E27/portrait.jpg` |
| 536158 | `client/assets/maps/map_ufa_campaign.jpg` |
| 534552 | `client/assets/ui/equipment/ui_icon_mat_equipment_scrap.jpg` |
| 534360 | `client/assets/ui/equipment/eq_icon_final_counter_armor.jpg` |

## Duplicate groups (sample)

_No non-media duplicates found in hashed subset._

## Secret-name hits

_Values not printed. Review manually; rotate if real secrets are committed._

- `scripts/check_release_keystore.sh` — name_match

## DELETE_CANDIDATE (tracked)

_Candidates only. Owner must approve file-by-file before any deletion (PR-4)._

_No tracked DELETE_CANDIDATE by heuristic. See untracked local noise and delete-candidates report._

## Untracked local noise (not committed)

Count: **416**. Dominated by Godot `.import` regenerations and blender scratch dirs.
These must **not** be mass-added without review; also must **not** be `git clean`'d without owner OK.

Sample:

- `client/assets/branding/bg_chat.jpg.import`
- `client/assets/branding/bg_shop.jpg.import`
- `client/assets/branding/bg_vip.jpg.import`
- `client/assets/characters/H13/H13_full.jpg.import`
- `client/assets/characters/H13/H13_portrait.jpg.import`
- `client/assets/characters/H14/H14_full.jpg.import`
- `client/assets/characters/H14/H14_portrait.jpg.import`
- `client/assets/characters/H15/H15_full.jpg.import`
- `client/assets/characters/H15/H15_portrait.jpg.import`
- `client/assets/characters/H16/H16_full.jpg.import`
- `client/assets/characters/H16/H16_portrait.jpg.import`
- `client/assets/characters/H17/H17_full.jpg.import`
- `client/assets/characters/H17/H17_portrait.jpg.import`
- `client/assets/characters/H18/H18_full.jpg.import`
- `client/assets/characters/H18/H18_portrait.jpg.import`
- `client/assets/characters/H19/H19_full.jpg.import`
- `client/assets/characters/H19/H19_portrait.jpg.import`
- `client/assets/characters/H20/H20_full.jpg.import`
- `client/assets/characters/H20/H20_portrait.jpg.import`
- `client/assets/characters/H21/H21_full.jpg.import`
- `client/assets/characters/H21/H21_portrait.jpg.import`
- `client/assets/characters/H22/H22_full.jpg.import`
- `client/assets/characters/H22/H22_portrait.jpg.import`
- `client/assets/characters/H23/H23_full.jpg.import`
- `client/assets/characters/H23/H23_portrait.jpg.import`
- `client/assets/characters/H24/H24_full.jpg.import`
- `client/assets/characters/H24/H24_portrait.jpg.import`
- `client/assets/characters/H25/H25_full.jpg.import`
- `client/assets/characters/H25/H25_portrait.jpg.import`
- `client/assets/characters/H26/H26_full.jpg.import`
- … +386 more

## Classification notes (manual)

| Path | Heuristic | Manual |
|------|-----------|--------|
| `docker-compose.yml` | UNKNOWN | **KEEP** — local Postgres/Redis |
| `scripts/check_release_keystore.sh` | UNKNOWN/secret-name | **KEEP** — checker script, not a keystore |

## Next (PR-2+)

1. Normalize AGENTS / PROJECT_CONTEXT / STATUS / TASK_QUEUE with evidence statuses.
2. Add AI_TASK_ROUTER + ARCHITECTURE_MAP + link/asset validators.
3. Owner-approved cleanup only from delete-candidates list.
