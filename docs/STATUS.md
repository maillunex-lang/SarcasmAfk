# STATUS.md — Verified project snapshot

> Date: **2026-11-19** · Baseline `main` SHA **`747a6f5`** · Active: `cursor/visual-overhaul-stage-f-4106`  
> **Single status source for agents.** Cold-start: [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) · Queue: [`TASK_QUEUE.md`](TASK_QUEUE.md)  
> Backup: [`reports/REPO_REORG_BACKUP.md`](reports/REPO_REORG_BACKUP.md) · Cleanup: [`reports/REPO_REORG_CLEANUP_DECISIONS.md`](reports/REPO_REORG_CLEANUP_DECISIONS.md)

## NOW

1. **T-158** Visual Overhaul Stage F — **DONE_VERIFIED** on PR branch (Theme + H13–H36 busts + gallery + anims + debug APK).  
2. T-157 CH01 Expansion E merged (`#28` → `main`).  
3. Owner blockers unchanged: T-128 device accept, T-129 live URL, T-126 keystore, T-131 Stage E, T-153 payments.

## Subsystem matrix (evidence-based)

| Subsystem | Status | Evidence |
|-----------|--------|----------|
| Godot MVP screens + CH01 path | `DONE_VERIFIED` (mock) | `client/scenes/*`, smokes; CI Godot job |
| Live API auth/battle/rewards | `DONE_VERIFIED` | `go test`; live smokes; CI go-api |
| Session resume / live probe | `DONE_VERIFIED` | `smoke_session_resume.sh`, D-NET-05 |
| Online shop TEST_PURCHASE / VIP / gacha pity | `PARTIAL` | APIs + client; real pay `BLOCKED` (T-153) |
| Chat WS + PG persist | `DONE_VERIFIED` | migrations 006; CI Postgres |
| Guild roles/quests/vault | `PARTIAL` | APIs + UI; wars/boss empty |
| EQUIPMENT-001 | `PARTIAL` | catalog/UI; TEMP icons; no random drop |
| MONSTERS TEMP atlases/VFX/SFX | `PARTIAL` | assets + validator; Stage E `BLOCKED` |
| Visual Overhaul 001 A–F | `DONE_VERIFIED` (TEMP art) | Theme.tres + H13–H36 busts + `visual_gallery/` + anims + smokes + debug APK; Stage E Kaeron still blocked |
| CH01 RPG Expansion A–E | `DONE_VERIFIED` (automation) | merged #28; device accept still T-128 |
| Arena / events live | `BLOCKED` | D-SCOPE-01; T-112 |
| CH02 | `BLOCKED` | T-090 / D-SCOPE-02 |
| Release signed APK | `BLOCKED` | T-126 keystore |
| REPO-REORG-001 | `DONE_VERIFIED` | merged #27 |

## BLOCKED (owner)

| ID | Need |
|----|------|
| T-128 | CH01 device/owner accept |
| T-131 | H01 Blender grip → Stage E |
| T-126 / T-129 | Release keystore / device API URL |
| T-090 | CH02 unlock |
| T-153 | Real payment provider |
| REORG-DEL | Approve delete candidates |

## Known limits

- Shop = `TEST_PURCHASE` only.  
- New art often TEMP.  
- Do not mass-commit untracked `.import` without approval.
