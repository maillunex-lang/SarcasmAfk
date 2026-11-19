# ARCHITECTURE_MAP.md

> Snapshot: **2026-11-19** · baseline `main` `60ebe23`

## Subsystems

```
[Godot Client] --HTTP/WS--> [Go API] --optional--> [Postgres] [Redis]
      |                         |
 client/data JSON          store/memory | store/postgres
      |                         |
 scenes/UI + GameState     battleverify tick-sim (authoritative)
```

## Client entry points

| Path | Role |
|------|------|
| `client/project.godot` | Godot project; autoloads |
| `client/scripts/autoload/game_state.gd` | Progress, party, economy, API mode |
| `client/scripts/autoload/design_tokens.gd` | UI tokens / fonts |
| `client/scripts/autoload/asset_paths.gd` | `res://` path constants + helpers |
| `client/scripts/net/api_client.gd` | Mock + live HTTP client |
| `client/scripts/ui/*_screen.gd` / `battle.gd` | Screens (code-built) |
| `client/scenes/**` | Thin scene shells |
| `client/data/**` | Quests, battles, heroes, equipment, shop, … |

## Server entry points

| Path | Role |
|------|------|
| `server/cmd/api/main.go` | Process entry |
| `server/internal/httpapi/` | Routes: auth, battles, rewards, online, admin |
| `server/internal/store/` | Memory + Postgres adapters |
| `server/internal/battleverify/` | ATB tick simulation / ultimates |
| `server/migrations/` | SQL migrations 001+ |

## Content contracts (CH01)

| ID set | Source of truth |
|--------|-----------------|
| Q01–Q12 | `client/data/quests/ch01_quests.json` |
| B01–B30 | `client/data/battles/ch01_battles.json` |
| L01–L10 | `client/data/locations/ch01_locations.json` |
| Enemies | `client/data/enemies/ch01_enemies.json` + art registries |
| Heroes H01–H36 | `client/data/heroes/roster_release36.json` |
| Dialogues | `client/data/dialogues/ch01_q*.json` |

## Dependency rules

- Client may mock (`USE_MOCK` / `use_mock`); release defaults prefer live probe (D-NET-05).
- Battle rewards on live path come from server finish (idempotent).
- Do not invent CH02 location/battle IDs in client gates.

## Key docs by subsystem

| Need | Doc |
|------|-----|
| Product rules | `GDD.md`, `DECISIONS.md` |
| Campaign | `CAMPAIGN_LOCATIONS.md` |
| Online | `ONLINE_SYSTEMS_SPEC.md` |
| Equipment | `EQUIPMENT_SYSTEM.md` |
| Monsters | `MONSTERS_CH01.md` |
| Visual | `VISUAL_OVERHAUL_001.md`, `UI_DESIGN_SYSTEM.md` |
| Android | `ANDROID_BUILD.md` |
