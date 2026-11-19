# REPO_REORG_CLEANUP_DECISIONS.md — final disposition (no owner checklist)

> Date: **2026-11-19** · Branch `cursor/chore-repo-reorg-001-beaf`  
> Backup baseline: `60ebe23` (`backup/main-pre-reorg-20261119-1451-60ebe23` + tag)

## Backup confirmation

| Check | Result |
|-------|--------|
| `origin/backup/main-pre-reorg-20261119-1451-60ebe23` | `60ebe23ddc4b78a1c5d8bb72b96d1dd9638f4615` |
| Tag `backup-main-pre-reorg-20261119-1451-60ebe23`^{} | same SHA |
| Matches reorg start `origin/main` | **YES** |

## Tracked files deleted in this PR

**None.**

## Why candidates were kept

### A. Tracked heuristic DELETE_CANDIDATE
Empty set at audit time.

### B. Untracked VM noise
| Item | Decision | Reason |
|------|----------|--------|
| Untracked `*.import` (~400) | **KEEP locally / do not commit** | Regenerable; many assets already have committed `.import`. Not in git history. |
| `tools/blender_pipeline/exports/` (H01 glb + previews) | **KEEP on disk** | Unique art source (D-ART-06 / T-131). Spec forbids deleting unique art sources even if runtime does not load them. Added to `.gitignore` to prevent accidental commit of huge scratch I/O. |
| `tools/blender_pipeline/source/`, `work/` | **KEEP on disk** + gitignore | Pipeline scratch; may hold owner grip work. |

### C. Doc “duplicates”
| Item | Decision | Reason |
|------|----------|--------|
| `DESIGN_SYSTEM.md` vs `UI_DESIGN_SYSTEM.md` | **KEEP both** | Former = token/spec canon; latter = runtime pointer to `design_tokens.gd`. Not redundant drafts. |
| `docs/reports/*` historical audits | **KEEP** | Evidence history; linked from INDEX. |

### D. Identical media (43 SHA groups)
| Group | Decision | Reason |
|-------|----------|--------|
| L02–L10 + L_shared skies (10× same bytes) | **KEEP all paths** | `AssetPaths.location_layer(loc, "sky")` builds `res://assets/locations/Lxx/loc_Lxx_sky.jpg`; JSON layers + `asset_registry.json` + CI/content expectations use per-location paths. Shared file is not a drop-in replacement without rewriting dynamic path convention. |
| L02/L03/L05/L07/L10 + shared far (6×) | **KEEP all paths** | Same dynamic `location_layer(..., "far")` dependency. |
| Enemy `concept.jpg` = `idle.jpg` = `portrait.jpg` per E* | **KEEP all three** | Required by `AssetPaths.enemy_concept` / idle fallback, `validate_monsters_ch01.py`, atlas generator inputs. Content-identical TEMP is intentional, not orphaned. |

**Doubt rule applied:** identical bytes ≠ unused. Search misses do not prove safety when paths are constructed dynamically.

## Non-delete hygiene applied

- `.gitignore`: ignore blender `exports/`, `source/`, `work/` (files remain on agent disk; not removed).
- `DESIGN_SYSTEM.md` status line refreshed to point at live `STATUS.md` (was “assets not produced”).
- Delete-candidates doc marked **RESOLVED — no tracked deletes**.

## Recommended future (out of scope / needs separate task)

- Optional: change `location_layer` to fall back to `L_shared` **then** dedupe skies/far with JSON rewrites + Godot smoke (new TASK_QUEUE item).
- Git LFS for large portraits (do not rewrite history without owner OK).

## Final validator hardening (pre-merge)

- `check_doc_links.py`: GitHub-style anchors with duplicate heading suffixes (`foo`, `foo-1`, `foo-2`).
- `check_content_refs.py`: battle→`enemy_type`, sprite `res://` existence, dynamic combat/location paths (L01–L10), catalog asset fields.
- Status single source remains [`../STATUS.md`](../STATUS.md#now).
