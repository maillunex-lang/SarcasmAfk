# STATUS.md — Verified project snapshot

> Date: **2026-11-19** · Baseline `main` · Active: `cursor/flutter-afk-mmorpg-4106`  
> **Single status source for agents.** Cold-start: [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) · Queue: [`TASK_QUEUE.md`](TASK_QUEUE.md)  
> Backup: [`reports/REPO_REORG_BACKUP.md`](reports/REPO_REORG_BACKUP.md) · Cleanup: [`reports/REPO_REORG_CLEANUP_DECISIONS.md`](reports/REPO_REORG_CLEANUP_DECISIONS.md)

## NOW

1. **Flutter AFK MMORPG demo** — 2.5D vertical маг vs волк (`flutter_afk_mmorpg/`); ice icicle + fireball. Branch `cursor/flutter-afk-mmorpg-4106`.  
2. City hub (D-UI-CITY-01) + stretch `expand` kept; AFK-shell battle design rejected (archive restore on `main`).  
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
| Visual Overhaul 001 A–F | `DONE_VERIFIED` (TEMP art) | Theme.tres + H13–H36 busts + gallery; Stage E Kaeron still blocked |
| CITY-HUB-001 Ufa interactive hub | `DONE_VERIFIED` (TEMP art) | D-UI-CITY-01; `home.gd` city + 10 hotspots + decor anims + `smoke_city_hub.gd` |
| AFK-shell UI (battle L/R + hub chrome) | `DEPRECATED` (owner reject) | D-UI-SHELL-01 revoked; battle restored from `backup/main-pre-reorg-…` |
| CH01 RPG Expansion A–E | `DONE_VERIFIED` (automation) | merged #28; device accept still T-128 |
| Arena / events live | `BLOCKED` | D-SCOPE-01; T-112 |
| CH02 | `BLOCKED` | T-090 / D-SCOPE-02 |
| Release signed APK | `BLOCKED` | T-126 keystore |
| REPO-REORG-001 | `DONE_VERIFIED` | merged #27 |
| Flutter AFK MMORPG demo | `PARTIAL` (demo) | `flutter_afk_mmorpg/` 2.5D маг vs волк; ice/fireball VFX |

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
- City hub art = TEMP panorama + code hotspots until final iso pack.  
- New art often TEMP.  
- Do not mass-commit untracked `.import` without approval.
