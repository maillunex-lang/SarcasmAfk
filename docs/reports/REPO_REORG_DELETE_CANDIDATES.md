# REPO_REORG_DELETE_CANDIDATES.md — awaiting owner confirmation

> SHA `60ebe23ddc4b78a1c5d8bb72b96d1dd9638f4615` · **NO FILES DELETED**. Approve rows explicitly before PR-4.

## A. Tracked DELETE_CANDIDATE

_None from heuristic on tracked tree._

## B. Untracked local (VM-only) — safe to ignore or discard locally

Not in git history. Recommended: leave alone or discard **locally** with owner OK; do not commit mass `.import` flood.

| Approve discard locally? | Pattern | Count (approx) | Notes |
|-------------------------|---------|----------------|-------|
| [ ] | `client/assets/**/*.import` (untracked) | ~413 | Regenerable by Godot `--import`; many assets already have committed `.import` |
| [ ] | `tools/blender_pipeline/exports/` | present | Scratch exports |
| [ ] | `tools/blender_pipeline/source/` | present | Scratch source |
| [ ] | `tools/blender_pipeline/work/` | present | Scratch work |

## C. Suspected doc consolidation (NOT delete)

Review for CONSOLIDATE/ARCHIVE in PR-2; do not delete first-class specs.

- Conflicting status narratives across `STATUS.md` vs merged VO work — update in place.
- Multiple audit reports under `docs/reports/` — KEEP as history.

## Owner reply format

Reply with checked paths, e.g.:

```
APPROVE DELETE:
- path/one
KEEP:
- path/two
```

## D. Identical media content groups (KEEP until owner decides)

_Same SHA256; often intentional TEMP copies (concept=idle=portrait). Prefer symlink/dedupe only with owner OK._

### `45a40f191946…` (10 files)
- [ ] `client/assets/locations/L06/loc_L06_sky.jpg`
- [ ] `client/assets/locations/L10/loc_L10_sky.jpg`
- [ ] `client/assets/locations/L09/loc_L09_sky.jpg`
- [ ] `client/assets/locations/L05/loc_L05_sky.jpg`
- [ ] `client/assets/locations/L03/loc_L03_sky.jpg`
- [ ] `client/assets/locations/L07/loc_L07_sky.jpg`
- [ ] `client/assets/locations/L02/loc_L02_sky.jpg`
- [ ] `client/assets/locations/L08/loc_L08_sky.jpg`
- [ ] `client/assets/locations/L_shared/loc_shared_sky.jpg`
- [ ] `client/assets/locations/L04/loc_L04_sky.jpg`

### `d7d8d402ecf1…` (6 files)
- [ ] `client/assets/locations/L10/loc_L10_far.jpg`
- [ ] `client/assets/locations/L05/loc_L05_far.jpg`
- [ ] `client/assets/locations/L03/loc_L03_far.jpg`
- [ ] `client/assets/locations/L07/loc_L07_far.jpg`
- [ ] `client/assets/locations/L02/loc_L02_far.jpg`
- [ ] `client/assets/locations/L_shared/loc_shared_far_ufa.jpg`

### `a3f510a870be…` (3 files)
- [ ] `client/assets/enemies/E09/portrait.jpg`
- [ ] `client/assets/enemies/E09/idle.jpg`
- [ ] `client/assets/enemies/E09/concept.jpg`

### `e8c87cdf8737…` (3 files)
- [ ] `client/assets/enemies/E23/portrait.jpg`
- [ ] `client/assets/enemies/E23/idle.jpg`
- [ ] `client/assets/enemies/E23/concept.jpg`

### `a9e276ac8dca…` (3 files)
- [ ] `client/assets/enemies/E01/portrait.jpg`
- [ ] `client/assets/enemies/E01/idle.jpg`
- [ ] `client/assets/enemies/E01/concept.jpg`

### `4b10a9f4f1cc…` (3 files)
- [ ] `client/assets/enemies/E24/portrait.jpg`
- [ ] `client/assets/enemies/E24/idle.jpg`
- [ ] `client/assets/enemies/E24/concept.jpg`

### `1b2cf7b63ea2…` (3 files)
- [ ] `client/assets/enemies/E05/portrait.jpg`
- [ ] `client/assets/enemies/E05/idle.jpg`
- [ ] `client/assets/enemies/E05/concept.jpg`

### `6c13ad9a8934…` (3 files)
- [ ] `client/assets/enemies/E29A/portrait.jpg`
- [ ] `client/assets/enemies/E29A/idle.jpg`
- [ ] `client/assets/enemies/E29A/concept.jpg`

### `1d873f87a12f…` (3 files)
- [ ] `client/assets/enemies/E20/portrait.jpg`
- [ ] `client/assets/enemies/E20/idle.jpg`
- [ ] `client/assets/enemies/E20/concept.jpg`

### `5da09dcb7d8d…` (3 files)
- [ ] `client/assets/enemies/E17/portrait.jpg`
- [ ] `client/assets/enemies/E17/idle.jpg`
- [ ] `client/assets/enemies/E17/concept.jpg`

### `d86bddc92c8f…` (3 files)
- [ ] `client/assets/enemies/E06/portrait.jpg`
- [ ] `client/assets/enemies/E06/idle.jpg`
- [ ] `client/assets/enemies/E06/concept.jpg`

### `1f13faec52b1…` (3 files)
- [ ] `client/assets/enemies/E08/portrait.jpg`
- [ ] `client/assets/enemies/E08/idle.jpg`
- [ ] `client/assets/enemies/E08/concept.jpg`

### `83c9e1d455be…` (3 files)
- [ ] `client/assets/enemies/E16/portrait.jpg`
- [ ] `client/assets/enemies/E16/idle.jpg`
- [ ] `client/assets/enemies/E16/concept.jpg`

### `007776797eb9…` (3 files)
- [ ] `client/assets/enemies/E11/portrait.jpg`
- [ ] `client/assets/enemies/E11/idle.jpg`
- [ ] `client/assets/enemies/E11/concept.jpg`

### `2a90081d33b3…` (3 files)
- [ ] `client/assets/enemies/E27/portrait.jpg`
- [ ] `client/assets/enemies/E27/idle.jpg`
- [ ] `client/assets/enemies/E27/concept.jpg`

### `fa357b0140f5…` (3 files)
- [ ] `client/assets/enemies/E30/portrait.jpg`
- [ ] `client/assets/enemies/E30/idle.jpg`
- [ ] `client/assets/enemies/E30/concept.jpg`

### `af88c7d4ee6b…` (3 files)
- [ ] `client/assets/enemies/E07/portrait.jpg`
- [ ] `client/assets/enemies/E07/idle.jpg`
- [ ] `client/assets/enemies/E07/concept.jpg`

### `f9c9056e1167…` (3 files)
- [ ] `client/assets/enemies/E15/portrait.jpg`
- [ ] `client/assets/enemies/E15/idle.jpg`
- [ ] `client/assets/enemies/E15/concept.jpg`

### `f579c1cb642e…` (3 files)
- [ ] `client/assets/enemies/E04/portrait.jpg`
- [ ] `client/assets/enemies/E04/idle.jpg`
- [ ] `client/assets/enemies/E04/concept.jpg`

### `9003f2b31cf9…` (3 files)
- [ ] `client/assets/enemies/E10/portrait.jpg`
- [ ] `client/assets/enemies/E10/idle.jpg`
- [ ] `client/assets/enemies/E10/concept.jpg`

### `1a929ab18406…` (3 files)
- [ ] `client/assets/enemies/E26/portrait.jpg`
- [ ] `client/assets/enemies/E26/idle.jpg`
- [ ] `client/assets/enemies/E26/concept.jpg`

### `029f95d747ad…` (3 files)
- [ ] `client/assets/enemies/E28/portrait.jpg`
- [ ] `client/assets/enemies/E28/idle.jpg`
- [ ] `client/assets/enemies/E28/concept.jpg`

### `c1e7fd96c11f…` (3 files)
- [ ] `client/assets/enemies/E22/portrait.jpg`
- [ ] `client/assets/enemies/E22/idle.jpg`
- [ ] `client/assets/enemies/E22/concept.jpg`

### `940d07aafde3…` (3 files)
- [ ] `client/assets/enemies/E12/portrait.jpg`
- [ ] `client/assets/enemies/E12/idle.jpg`
- [ ] `client/assets/enemies/E12/concept.jpg`

### `ff545b36ad69…` (3 files)
- [ ] `client/assets/enemies/E14/portrait.jpg`
- [ ] `client/assets/enemies/E14/idle.jpg`
- [ ] `client/assets/enemies/E14/concept.jpg`

### `c2da783b605c…` (3 files)
- [ ] `client/assets/enemies/E03/portrait.jpg`
- [ ] `client/assets/enemies/E03/idle.jpg`
- [ ] `client/assets/enemies/E03/concept.jpg`

### `be4194743875…` (3 files)
- [ ] `client/assets/enemies/E25/portrait.jpg`
- [ ] `client/assets/enemies/E25/idle.jpg`
- [ ] `client/assets/enemies/E25/concept.jpg`

### `cbac9ad972e1…` (3 files)
- [ ] `client/assets/enemies/E29/portrait.jpg`
- [ ] `client/assets/enemies/E29/idle.jpg`
- [ ] `client/assets/enemies/E29/concept.jpg`

### `f1fe20ab9b0e…` (3 files)
- [ ] `client/assets/enemies/E21/portrait.jpg`
- [ ] `client/assets/enemies/E21/idle.jpg`
- [ ] `client/assets/enemies/E21/concept.jpg`

### `7a561aeff04b…` (3 files)
- [ ] `client/assets/enemies/E02/portrait.jpg`
- [ ] `client/assets/enemies/E02/idle.jpg`
- [ ] `client/assets/enemies/E02/concept.jpg`

### `d71664024153…` (3 files)
- [ ] `client/assets/enemies/E13/portrait.jpg`
- [ ] `client/assets/enemies/E13/idle.jpg`
- [ ] `client/assets/enemies/E13/concept.jpg`

### `7ac04a19f623…` (2 files)
- [ ] `client/assets/dialogs/dialog_portrait_H09.jpg`
- [ ] `client/assets/characters/H09/H09_portrait.jpg`

### `1724b2a6693a…` (2 files)
- [ ] `client/assets/dialogs/dialog_portrait_H07.jpg`
- [ ] `client/assets/characters/H07/H07_portrait.jpg`

### `4cee1a3ac2a3…` (2 files)
- [ ] `client/assets/dialogs/dialog_portrait_H08.jpg`
- [ ] `client/assets/characters/H08/H08_portrait.jpg`

### `cc60f7fbbbd2…` (2 files)
- [ ] `client/assets/dialogs/dialog_portrait_H03.jpg`
- [ ] `client/assets/characters/H03/H03_portrait.jpg`

### `dc8dfaae96c2…` (2 files)
- [ ] `client/assets/dialogs/dialog_portrait_H06.jpg`
- [ ] `client/assets/characters/H06/H06_portrait.jpg`

### `33b3280082b3…` (2 files)
- [ ] `client/assets/dialogs/dialog_portrait_H04.jpg`
- [ ] `client/assets/characters/H04/H04_portrait.jpg`

### `c919ed163dda…` (2 files)
- [ ] `client/assets/dialogs/dialog_portrait_H02.jpg`
- [ ] `client/assets/characters/H02/H02_portrait.jpg`

### `caadfe8eae2c…` (2 files)
- [ ] `client/assets/dialogs/dialog_portrait_H11.jpg`
- [ ] `client/assets/characters/H11/H11_portrait.jpg`

### `8216cfa6b46d…` (2 files)
- [ ] `client/assets/dialogs/dialog_portrait_H01.jpg`
- [ ] `client/assets/characters/H01/H01_portrait.jpg`

