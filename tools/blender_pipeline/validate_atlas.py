"""Validate atlas.png + atlas.json for combat sprite import gates."""
from __future__ import annotations

import json
import sys
from pathlib import Path

# Reuse PNG reader
sys.path.insert(0, str(Path(__file__).resolve().parent))
from pack_atlas import read_png  # noqa: E402


def validate(out_dir: Path) -> dict:
    atlas = out_dir / "atlas.png"
    meta_path = out_dir / "atlas.json"
    report: dict = {"ok": True, "checks": []}

    def check(name: str, ok: bool, detail: str = "") -> None:
        report["checks"].append({"name": name, "ok": ok, "detail": detail})
        if not ok:
            report["ok"] = False

    check("atlas_png_exists", atlas.is_file(), str(atlas))
    check("atlas_json_exists", meta_path.is_file(), str(meta_path))
    if not report["ok"]:
        return report

    meta = json.loads(meta_path.read_text(encoding="utf-8"))
    w, h, rgba = read_png(atlas)
    check("dims_match_meta", w == int(meta["atlas_w"]) and h == int(meta["atlas_h"]), f"{w}x{h}")
    check("frame_count_ge_4", int(meta.get("frame_count", 0)) >= 4, str(meta.get("frame_count")))
    check("square_frames", int(meta["frame_w"]) == int(meta["frame_h"]), f"{meta['frame_w']}x{meta['frame_h']}")
    alphas = rgba[3::4]
    transparent = sum(1 for a in alphas if a < 8)
    opaque = sum(1 for a in alphas if a > 200)
    check("has_transparency", transparent > 0, f"transparent_px={transparent}")
    check("has_opaque_content", opaque > 100, f"opaque_px={opaque}")
    check("marked_dev_sample", "not final" in str(meta.get("note", "")).lower() or "D-ART" in str(meta.get("note", "")))
    return report


def main() -> None:
    out_dir = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    report = validate(out_dir)
    (out_dir / "report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if report["ok"] else 1)


if __name__ == "__main__":
    main()
