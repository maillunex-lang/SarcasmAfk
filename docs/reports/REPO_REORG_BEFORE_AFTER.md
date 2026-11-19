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

## After (this branch, merge-ready)

| Area | State |
|------|-------|
| Backup | Branch + annotated tag + local bundle (see `REPO_REORG_BACKUP.md`) — **re-verified on origin** |
| Inventory | `repo_inventory.json` + audit + broken-links (0) |
| AI context | `PROJECT_CONTEXT`, `AI_TASK_ROUTER`, `ARCHITECTURE_MAP`, `AI_ONBOARDING_TEST`; refreshed AGENTS/STATUS/INDEX/DECISIONS/TASK_QUEUE |
| Deletes | **None tracked** — dispositions in `REPO_REORG_CLEANUP_DECISIONS.md` |
| Hygiene | `.gitignore` blender exports/source/work (files kept on disk) |
| Validators | `check_doc_links` / `check_ai_docs` / `check_content_refs` in `ci_validate.sh` |
| `main` | **Unchanged** until reviewed merge of PR #27 |

## Metrics

| Metric | Before | After (branch) |
|--------|--------|----------------|
| Tracked files @ baseline | 1139 | +reports/scripts/docs (see PR diff); **0 tracked deletions** |
| Internal MD link breaks | unknown | **0** |
| Open PRs @ backup | 0 | #27 reorg (no auto-merge) |
| Force-push / history rewrite | — | **none** |

## Still required from owner

1. Protect backup branch against force-push/deletion.  
2. Copy bundle from agent VM (`/home/ubuntu/repo-backups/…`) to private storage.  
3. Review & merge PR #27 (no direct push to `main`).
