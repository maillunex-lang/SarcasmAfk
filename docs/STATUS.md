# STATUS.md — Verified project snapshot

> Date: **2026-11-19** · Baseline `main` SHA **`2b1aef7`** · Active: `cursor/t157-ch01-expansion-e2e-4106`  
> **Single status source for agents.** Cold-start: [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) · Queue: [`TASK_QUEUE.md`](TASK_QUEUE.md)  
> Backup: [`reports/REPO_REORG_BACKUP.md`](reports/REPO_REORG_BACKUP.md) · Cleanup: [`reports/REPO_REORG_CLEANUP_DECISIONS.md`](reports/REPO_REORG_CLEANUP_DECISIONS.md)

## NOW

1. **T-157** CH01 Expansion E (E2E + debug APK + owner report) — **DONE_VERIFIED** on PR branch; report [`reports/CH01_EXPANSION_E2E_2026-11-19.md`](reports/CH01_EXPANSION_E2E_2026-11-19.md).  
2. REPO-REORG-001 merged (`#27` → `main`).  
3. Next open product: Stage F visual polish / owner device accept (T-128) / still-blocked payments & Stage E.

## Subsystem matrix (evidence-based)

| Subsystem | Status | Evidence |
|-----------|--------|----------|
| Godot MVP screens + CH01 path | `DONE_VERIFIED` (mock) | `client/scenes/*`, `smoke_v0a/c`, `smoke_ch01*`, `smoke_mvp`; CI Godot job |
| Live API auth/battle/rewards | `DONE_VERIFIED` | `server/internal/httpapi`, `go test`; `scripts/smoke_live_api.sh`; CI go-api |
| Session resume / live probe | `DONE_VERIFIED` | `smoke_session_resume.sh`, D-NET-05 client toggle |
| Online shop TEST_PURCHASE / VIP / gacha pity | `PARTIAL` | APIs + client screens; real pay `BLOCKED` (T-153) |
| Chat WS + PG persist | `DONE_VERIFIED` | migrations 006, CI with Postgres service |
| Guild roles/quests/vault | `PARTIAL` | APIs + UI; wars/boss empty |
| EQUIPMENT-001 | `PARTIAL` | catalog/UI/combat flats; TEMP icons; no random drop |
| MONSTERS TEMP atlases/VFX/SFX | `PARTIAL` | assets + `validate_monsters_ch01.py`; Stage E `BLOCKED` |
| Visual Overhaul 001 A–E slice | `PARTIAL` | merged fonts/BGs/guild/map/gacha frames; Theme.tres / H13–H36 busts / gallery open |
| CH01 RPG Expansion A–E | `DONE_VERIFIED` (automation) | data + API + POI UI + `smoke_ch01_expansion.gd` + `smoke_ch01_expansion_live.sh` + debug APK + E2E report; device accept still T-128 |
| Arena / events live | `BLOCKED` | UI stubs D-SCOPE-01; T-112 |
| CH02 | `BLOCKED` | T-090 / D-SCOPE-02 |
| Release signed APK | `BLOCKED` | T-126 keystore |
| REPO-REORG-001 docs/validators | `DONE_VERIFIED` | merged PR #27 |
| REPO-REORG tracked file deletes | `DEPRECATED` | Identical media kept (dynamic paths); see cleanup decisions |

## BLOCKED (owner)

| ID | Need |
|----|------|
| T-128 | CH01 device/owner accept |
| T-131 | H01 Blender grip → Stage E |
| T-126 / T-129 | Release keystore / device API URL |
| T-090 | CH02 unlock |
| T-153 | Real payment provider |
| REORG-DEL | Approve `REPO_REORG_DELETE_CANDIDATES.md` rows |

## Known limits

- Shop = `TEST_PURCHASE` only.  
- New art often TEMP.  
- Local VM may have hundreds of **untracked** `.import` files — do not mass-commit or `git clean` without approval.
