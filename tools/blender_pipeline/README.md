# Blender → transparent 2D atlas pipeline (T-031 / D-ART-01)

Scripts only — outputs are **dev samples**, not final owner art (D-ART-02/03).

## Flow

1. **create_rig** — minimal proxy mesh + idle action in a `.blend`
2. **render_frames** — orthographic PNG sequence with transparent film
3. **pack_atlas** — sprite sheet + `atlas.json` for Godot `AtlasTexture` / AnimatedSprite
4. **validate** — size, alpha, frame count gates

## Run

```bash
# Requires: blender (4.0+), python3
export BLENDER_BIN="${BLENDER_BIN:-blender}"
bash tools/blender_pipeline/run_pipeline.sh sample_unit
# → tools/blender_pipeline/out/sample_unit/{frames,atlas.png,atlas.json,report.json}
```

Optional: `ASSET_ID=hero_proxy bash tools/blender_pipeline/run_pipeline.sh hero_proxy`

## Godot import (later)

Point combat sprites at `atlas.png` + frame rects from `atlas.json`. Placeholders remain until owner art-approve.
