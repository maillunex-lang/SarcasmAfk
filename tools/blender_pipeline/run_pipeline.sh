#!/usr/bin/env bash
# End-to-end Blender → atlas smoke (T-031).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PIPE="$ROOT/tools/blender_pipeline"
ASSET_ID="${1:-sample_unit}"
BLENDER_BIN="${BLENDER_BIN:-blender}"
OUT="$PIPE/out/$ASSET_ID"
FRAMES="$OUT/frames"
BLEND="$OUT/${ASSET_ID}.blend"

command -v "$BLENDER_BIN" >/dev/null || { echo "MISS blender ($BLENDER_BIN)"; exit 1; }
mkdir -p "$FRAMES"

echo "== create_rig =="
"$BLENDER_BIN" --background --python "$PIPE/create_rig.py" -- "$ASSET_ID" "$BLEND"

echo "== render_frames =="
"$BLENDER_BIN" --background --python "$PIPE/render_frames.py" -- "$BLEND" "$FRAMES" 1 8

echo "== pack_atlas =="
python3 "$PIPE/pack_atlas.py" "$FRAMES" "$OUT/atlas.png" "$OUT/atlas.json" "$ASSET_ID"

echo "== validate =="
python3 "$PIPE/validate_atlas.py" "$OUT"

# Keep a tiny committed sample meta pointer (image stays under out/, gitignored)
mkdir -p "$PIPE/samples"
cp -f "$OUT/atlas.json" "$PIPE/samples/${ASSET_ID}.atlas.json"
echo "pipeline_ok asset=$ASSET_ID out=$OUT"
