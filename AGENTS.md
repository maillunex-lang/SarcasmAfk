# AGENTS.md — Entry for every AI (Cursor / Codex / Claude)

**Read order (do not skip):**

1. This file  
2. [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md) — product, stack, constraints  
3. [`docs/STATUS.md`](docs/STATUS.md) — verified snapshot (NOW / works / blocked)  
4. [`docs/TASK_QUEUE.md`](docs/TASK_QUEUE.md) — task IDs + next action  
5. [`docs/AI_TASK_ROUTER.md`](docs/AI_TASK_ROUTER.md) — which files/commands for the task type  
6. One domain spec + **only the relevant code**  
7. Confirm against git `main` + open PRs before coding  

Map: [`docs/INDEX.md`](docs/INDEX.md) · Architecture: [`docs/ARCHITECTURE_MAP.md`](docs/ARCHITECTURE_MAP.md) · Decisions: [`docs/DECISIONS.md`](docs/DECISIONS.md)

## Project

| | |
|---|---|
| Repo | `maillunex-lang/SarcasmAfk` (do not rename) |
| Display | БашЛегенды: Эпоха Абсурда |
| Client | Godot **4.3** · Android · 9:16 · `client/` |
| Server | Go API · `server/` · Postgres/Redis optional |
| Branches | Work on `cursor/<name>-beaf`; change `main` only via reviewed PR |

## Hard rules

- Never mark `DONE_VERIFIED` without: code paths + tests/smoke + acceptance + commit/PR.
- Docs ≠ proof of implementation. Prefer STATUS evidence tables.
- Do not open CH02, real payments, Stage E Kaeron mass art, or package-ID renames without owner decision in `DECISIONS.md`.
- No force-push, history rewrite, `git clean -fdx`, or mass deletes. Cleanup only from an owner-approved file list.
- TEMP art stays TEMP. Arena/events stay locked stubs (D-SCOPE-01).
- After meaningful work: update `STATUS.md` + `TASK_QUEUE.md` (+ `ROAD.md` journal), then commit/push.

## Verify

```bash
bash scripts/ci_validate.sh
python3 scripts/audit_repo.py          # inventory (reorg)
(cd server && go test ./... -count=1)
```

Godot: headless smokes under `client/scripts/tools/smoke_*.gd` (CI installs Godot 4.3).

## Safety / secrets

- Do not print `.env`, keystore material, or API key values.
- `scripts/check_release_keystore.sh` checks presence — it is not a secret store.
- If a real secret is found in git: stop, report **path + risk type only**, recommend rotation.

## Reorg (REPO-REORG-001)

Backup: [`docs/reports/REPO_REORG_BACKUP.md`](docs/reports/REPO_REORG_BACKUP.md)  
Audit: [`docs/reports/REPO_REORG_AUDIT.md`](docs/reports/REPO_REORG_AUDIT.md)  
Deletes: **wait for owner** — [`docs/reports/REPO_REORG_DELETE_CANDIDATES.md`](docs/reports/REPO_REORG_DELETE_CANDIDATES.md)
