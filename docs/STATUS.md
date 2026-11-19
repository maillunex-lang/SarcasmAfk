# STATUS.md — Verified project snapshot

> Date: **2026-11-19** · Baseline `main` SHA **`60ebe23`** · Reorg branch `cursor/chore-repo-reorg-001-beaf`  
> Cold-start: [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) · Queue: [`TASK_QUEUE.md`](TASK_QUEUE.md)  
> Backup: [`reports/REPO_REORG_BACKUP.md`](reports/REPO_REORG_BACKUP.md)

## NOW

1. **REPO-REORG-001** — AI context + audit (PR [#27](https://github.com/maillunex-lang/SarcasmAfk/pull/27)); deletions **blocked** until owner approves the candidate list.  
2. Product follow-ups on `main`: T-157 (CH01 expansion E2E/APK report), owner-gated blockers below.  
3. Visual Overhaul 001 **merged** to `main` (PR #26) — Stage F (gallery/Theme/APK) still open.

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
| Arena / events live | `BLOCKED` | UI stubs D-SCOPE-01; T-112 |
| CH02 | `BLOCKED` | T-090 / D-SCOPE-02 |
| Release signed APK | `BLOCKED` | T-126 keystore |
| REPO-REORG cleanup deletes | `BLOCKED` | awaiting owner checklist |

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
