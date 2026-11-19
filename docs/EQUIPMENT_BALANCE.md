# EQUIPMENT-001 — Balance (Draft)

`balance_version`: `EQUIPMENT-001-draft-1`

## Order of operations

1. Sum equipped instance flat stats at upgrade level `u`: `floor(base * (1 + growth * u))`.
2. Count set pieces **on the same hero**.
3. Apply 2-piece then 4-piece % bonuses to the summed (base + flat) values.
4. Apply hero level multiplier and skill flat ATK bonuses.

`growth` default = `0.10` from catalog.

## Upgrade costs (Draft)

`soft = 100 * (u+1) * rarity_multiplier`  
`mat_equipment_scrap = 1 + floor(u/2)` for R+ (N: soft only)

Multipliers: N1 R2 SR4 SSR8 UR16 Mythic32.

Caps: N+3 R+5 SR+8 SSR+10 UR+12 Mythic+15.

## Salvage yield (Draft)

N1 R3 SR8 SSR20 UR50 · Mythic forbidden.

## Inventory

Capacity 200 instances. Overflow → `equipment_pending` (not deleted).

## Sets (Draft %)

| Set | 2pc | 4pc |
|-----|-----|-----|
| Страж Очереди | DEF +8% | HP +10% |
| Архивная Мудрость | ATK +6% | SPEED +5% |
| Аварийный Протокол | HP +8% | DEF +8% |
| Последняя Печать | ATK +8% | HP +8% |

All values are **Draft for testing**, editable via catalog JSON — not production-approved.
