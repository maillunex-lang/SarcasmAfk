# AI_TASK_ROUTER.md — what to read / run / avoid

> Snapshot: **2026-11-19** · Always start at [`../AGENTS.md`](../AGENTS.md)

| Task type | Read (2–5 files) | Commands | Do not touch |
|-----------|------------------|----------|--------------|
| Pick next work | `STATUS.md`, `TASK_QUEUE.md`, open PRs on GitHub | `gh pr list --state open` | Random docs; inventing new P0 |
| Godot UI / screen | `ARCHITECTURE_MAP.md`, `UI_DESIGN_SYSTEM.md` or `DESIGN_SYSTEM.md`, target `client/scripts/ui/*.gd`, `asset_paths.gd` | Godot headless smoke for that screen; `smoke_visual_screens.gd` | Package ID; CH02 scenes |
| Battle / combat | `PHASE0_SPEC.md` (contracts), `battle.gd` / `battle_engine`, `server/internal/battleverify` | `smoke_ch01.gd`, `go test ./internal/battleverify` | Balance without TASK_QUEUE item |
| CH01 content JSON | `CAMPAIGN_LOCATIONS.md`, matching `client/data/**` | `python3 scripts/validate_ch01_expansion.py`; JSON CI | Renaming Q/B/L IDs without DECISIONS |
| Online shop/VIP/gacha/chat/guild | `ONLINE_SYSTEMS_SPEC.md`, `httpapi/online.go`, matching client screen | `go test ./...`; live smokes in `ci_validate.sh` | Real payment provider (T-153) |
| Equipment | `EQUIPMENT_SYSTEM.md`, `client/data/equipment/*`, inventory UI | equipment / inventory smokes | Claiming final art |
| Monsters / VFX | `MONSTERS_CH01.md`, `enemy_*_registry.json`, combat sprites | `validate_monsters_ch01.py` | Stage E Kaeron (T-131) without owner |
| Visual polish | `VISUAL_OVERHAUL_001.md`, `VISUAL_QA_REPORT.md`, `DesignTokens` | `smoke_visual_screens.gd` | Deleting TEMP assets as “final” |
| City hub / Home UX | `CITY_HUB_001.md`, `D-UI-CITY-01`, `home.gd`, `ufa_buildings.json` | `smoke_city_hub.gd` | Arena live; final iso art without TEMP mark |
| Android APK | `ANDROID_BUILD.md`, export presets example | `scripts/build_debug_apk.sh` (if toolchain present) | Release signing without keystore (T-126) |
| Docs / AI context | `INDEX.md`, this router, `STATUS.md` | `python3 scripts/audit_repo.py` | Parallel STATUS_V2 files |
| Repo cleanup | `reports/REPO_REORG_DELETE_CANDIDATES.md` | — | Any delete without owner checklist |
| Server migrations | `server/migrations/*`, store adapters | `go test ./internal/store`; compose up if needed | Dropping prod DB; rewriting history |

## Status vocabulary (TASK_QUEUE)

| Status | Meaning |
|--------|---------|
| `NOT_STARTED` | No meaningful code yet |
| `IN_PROGRESS` | Active work |
| `PARTIAL` | Usable but incomplete / TEMP / gated |
| `IMPLEMENTED_UNVERIFIED` | Code exists; tests/evidence thin |
| `BLOCKED` | Waiting on owner / decision / external |
| `DONE_VERIFIED` | Paths + tests + acceptance + commit/PR evidence |
| `DEPRECATED` | Superseded; keep for history |

Legacy `DONE` / `TODO` / `DOING` in older rows map to `DONE_VERIFIED` / `NOT_STARTED` / `IN_PROGRESS` only when evidence exists; otherwise downgrade in STATUS notes—not by erasing IDs.
