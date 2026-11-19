# REPO_REORG_BEFORE_AFTER.md

> Living report. Baseline `main` **`60ebe23`**. Work branch `cursor/chore-repo-reorg-001-beaf`.

## Before (pre-reorg `main`)

| Area | State |
|------|-------|
| AI entry | `AGENTS.md` short; no `PROJECT_CONTEXT` / router / architecture map |
| STATUS | Stale branch refs (VO / atlases); weak evidence table |
| TASK_QUEUE | Legacy DONE/TODO; next-step ignored VO merge + reorg |
| Inventory | No machine registry of 1139 tracked files |
| Backup | None dedicated for reorg |
| Deletes | No owner checklist |
| Internal MD links | Untested systematically |

## After (this branch, so far)

| Area | State |
|------|-------|
| Backup | Branch + annotated tag + local bundle (see `REPO_REORG_BACKUP.md`) |
| Inventory | `repo_inventory.json` + audit + broken-links (0) + delete-candidates |
| AI context | `PROJECT_CONTEXT`, `AI_TASK_ROUTER`, `ARCHITECTURE_MAP`, `AI_ONBOARDING_TEST`; refreshed AGENTS/STATUS/INDEX/DECISIONS/TASK_QUEUE |
| Deletes | **None** — waiting owner approval |
| Validators/CI extras | Pending PR-3 (`T-161`) |
| `main` | **Unchanged** until you merge |

## Metrics

| Metric | Before | After (branch) |
|--------|--------|----------------|
| Tracked files @ baseline | 1139 | +reports/scripts (see PR diff) |
| Internal MD link breaks | unknown | **0** (docs tree scan) |
| Open PRs @ backup | 0 | #27 reorg (no auto-merge) |
| Force-push / history rewrite | — | **none** |

## Still required from owner

1. Protect backup branch against force-push/deletion.  
2. Copy bundle from agent VM (`/home/ubuntu/repo-backups/…`) to private storage.  
3. Approve/reject rows in `REPO_REORG_DELETE_CANDIDATES.md` before any PR-4.  
4. Explicit OK to merge reorg PRs into `main`.
