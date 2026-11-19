# EQUIPMENT-001 — System

Unique equipment instances integrated with CH01 RPG Expansion.

## Model

- Catalog templates live in `client/data/equipment/equipment_catalog_v1.json` (32 items).
- Owned items are UUID instances on `AccountProgress.equipment_instances` (Memory + Postgres JSONB).
- Hero slots (`weapon` / `armor` / `accessory` / `relic`) store **instance IDs**, not template IDs.
- Legacy `starter_*` / inventory stacks migrate idempotently via `MigrateLegacyEquipment`.

## API

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/v1/equipment/catalog` | Templates, sets, balance |
| GET | `/v1/equipment/inventory` | Owned instances |
| GET | `/v1/heroes/{id}/equipment` | Slots + combat snapshot |
| POST | `/v1/equipment/{id}/equip` | Equip / transfer |
| POST | `/v1/equipment/{id}/unequip` | Unequip |
| POST | `/v1/equipment/{id}/upgrade` | +1 upgrade |
| POST | `/v1/equipment/{id}/lock` | Lock / unlock |
| POST | `/v1/equipment/{id}/salvage` | Salvage to scrap |

Mutations accept `request_id` + `expected_version` (optimistic concurrency + idempotency).

## Combat

Server computes flat stats from equipped instances (`floor(base * (1 + 0.10 * u))`), then set % bonuses (2/4 piece), then hero level / skill modifiers. Battle finish grants CH01 first-clear equipment via `CH01-{BATTLE}-EQ-FIRST_CLEAR`.

## Client

- `inventory_screen.gd` — tabs, cards, equip/upgrade/lock/salvage, TEMP icons.
- Mock path uses `GameState.equipment_instances`; live path uses API.

## Partial / planned

- Secondary combat effects (`crit_*`, etc.) not applied (engine lacks them) — primary stats only.
- Random drop tables remain **OFF** (`random_drop.enabled=false`).
- Mythic templates supported in schema but not issued.
- Dedicated admin UI section — catalog is editable via JSON for now.
