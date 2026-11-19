# PROJECT_CONTEXT.md — БашЛегенды: Эпоха Абсурда

> Snapshot: **2026-11-19** · baseline `main` `2b1aef7` (REORG #27) · product: T-157 Expansion E  
> Entry: [`../AGENTS.md`](../AGENTS.md) → this file → [`STATUS.md`](STATUS.md) → [`TASK_QUEUE.md`](TASK_QUEUE.md)

## What it is

Mobile **Android-only** idle RPG / campaign hybrid: absurd bureaucratic fantasy set in Bashkortostan (CH01 = Уфа). Display name **БашЛегенды: Эпоха Абсурда**; repo stays `SarcasmAfk`; internal id `BashLegends`.

## Stack

| Layer | Tech |
|-------|------|
| Client | Godot **4.3**, portrait **9:16**, code-built UI (`DesignTokens`) |
| Server | Go API (`server/cmd/api`), authoritative battle tick-sim |
| Data | JSON content under `client/data/`; Postgres+Redis **opt-in** via compose |
| CI | `.github/workflows/ci.yml` — JSON, Godot smokes, Go+PG/Redis |

## Layout

```
AGENTS.md                 AI entry
client/                   Godot project (scenes, scripts, assets, data)
server/                   Go module + migrations
docs/                     Specs, status, reports
scripts/                  Local CI / smokes / auditors
tools/blender_pipeline/   Atlas tooling (Stage E owner grip blocked)
.github/workflows/        CI
docker-compose.yml        Local PG/Redis
```

## Current milestone

Post–Visual Overhaul 001 (`#26`) + REPO-REORG (`#27`) on `main`. CH01 Expansion A–E automation verified (T-157). Online systems Draft live; EQUIPMENT-001 + MONSTERS TEMP on main. **CH02 / real payments / Stage E Kaeron atlases blocked.**

## Hard constraints

- Do **not** open CH02, activate real payments, rename package ID, or mass-generate Stage E art.
- Do **not** call a feature DONE without tests + STATUS/TASK_QUEUE evidence.
- TEMP art stays labeled TEMP; Arena/Events remain locked stubs (D-SCOPE-01).

## Verify quickly

```bash
bash scripts/ci_validate.sh
# or: python3 scripts/audit_repo.py
#     (cd server && go test ./... -count=1)
```
