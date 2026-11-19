#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export BLENDER_BIN="${BLENDER_BIN:-blender}"
bash "$ROOT/tools/blender_pipeline/run_pipeline.sh" sample_unit
test -f "$ROOT/tools/blender_pipeline/samples/sample_unit.atlas.json"
echo "smoke_blender_pipeline_ok"
