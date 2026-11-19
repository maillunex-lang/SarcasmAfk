# REPO_REORG_BACKUP.md — REPO-REORG-001

> Created: **2026-11-19T14:51:16Z** · Executor: Cursor Cloud Agent  
> Purpose: immutable snapshot of `origin/main` **before** any reorg edits.

## Snapshot

| Field | Value |
|-------|-------|
| `origin/main` SHA | `60ebe23ddc4b78a1c5d8bb72b96d1dd9638f4615` |
| Short SHA | `60ebe23` |
| UTC stamp | `20261119-1451` |
| Tracked files | 1139 |
| `.git` size (approx) | 206M |
| Open PRs at backup | **0** |
| Remote | `origin` → `github.com/maillunex-lang/SarcasmAfk` |

## Working tree note (pre-backup)

- Tracked working tree was **clean** vs `origin/main` (0 modified/staged).
- **416 untracked** local files present (Godot `.import` sidecars regenerated in VM + `tools/blender_pipeline/{exports,source,work}/` scratch). **Not committed. Not deleted** (`git clean` / `reset` forbidden by REORG rules).

## Backup refs (GitHub)

| Kind | Name | Resolves to |
|------|------|-------------|
| Branch | `backup/main-pre-reorg-20261119-1451-60ebe23` | `60ebe23ddc4b78a1c5d8bb72b96d1dd9638f4615` |
| Annotated tag | `backup-main-pre-reorg-20261119-1451-60ebe23` | commit `60ebe23…` (tag object `d3bd070…`) |

### Verify commands

```bash
git fetch origin --tags
git rev-parse origin/backup/main-pre-reorg-20261119-1451-60ebe23
# → 60ebe23ddc4b78a1c5d8bb72b96d1dd9638f4615
git rev-list -n 1 backup-main-pre-reorg-20261119-1451-60ebe23
# → 60ebe23ddc4b78a1c5d8bb72b96d1dd9638f4615
```

### Restore commands

```bash
# Restore main tip to backup (owner only; do NOT force-push without explicit approval)
git checkout -B restore/main-from-backup origin/backup/main-pre-reorg-20261119-1451-60ebe23
# Or create PR from backup branch into main if needed.
```

## Local git bundle (outside repository)

| Field | Value |
|-------|-------|
| Path | `/home/ubuntu/repo-backups/SarcasmAfk-pre-reorg-20261119-1451-60ebe23.bundle` |
| Also | `/tmp/SarcasmAfk-pre-reorg-20261119-1451-60ebe23.bundle` |
| Size | 105M |
| SHA256 | `95be09656218ef422e280e48f9ef9fbd81567e6d303cf686b92237b65ff3c6fb` |
| Verify | `git bundle verify <path>` → complete history, sha1 |
| Contents | `--branches --tags` |

**Not committed to Git.** Artifact upload to `/opt/cursor/artifacts` rejected large binary (0-byte on copy); durable copy kept under `/home/ubuntu/repo-backups/`. Owner should download/copy this bundle to private storage.

## Branch protection

Attempted GitHub API branch protection on backup branch → **HTTP 403** (`Resource not accessible by integration`). **Owner action required:** protect `backup/main-pre-reorg-20261119-1451-60ebe23` against force-push and deletion in GitHub Settings.

## Work branch for reorg

`cursor/chore-repo-reorg-001-beaf` created from `origin/main` @ `60ebe23`.  
`main` will not be changed until owner-approved PR merge.
