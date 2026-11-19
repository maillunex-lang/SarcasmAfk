#!/usr/bin/env python3
"""Generate TEMP dialog busts for H13–H36 from character portraits (VO Stage F)."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
CHARS = ROOT / "client" / "assets" / "characters"
OUT = ROOT / "client" / "assets" / "dialogs"


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    made = 0
    for i in range(13, 37):
        hid = f"H{i}"
        src = CHARS / hid / f"{hid}_portrait.jpg"
        dst = OUT / f"dialog_portrait_{hid}.jpg"
        if not src.is_file():
            raise SystemExit(f"missing portrait {src}")
        im = Image.open(src).convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS)
        # Soft vignette + TEMP stamp so assets stay clearly draft.
        overlay = Image.new("RGBA", im.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)
        for r in range(0, 180, 4):
            alpha = int(90 * (r / 180))
            draw.ellipse(
                [r, r, 1024 - r, 1024 - r],
                outline=(16, 28, 53, alpha),
                width=4,
            )
        draw.rectangle([24, 24, 1000, 1000], outline=(232, 188, 104, 140), width=6)
        draw.rectangle([40, 40, 220, 100], fill=(16, 28, 53, 180))
        draw.text((56, 52), "TEMP", fill=(232, 188, 104, 230))
        composed = Image.alpha_composite(im.convert("RGBA"), overlay).convert("RGB")
        composed.save(dst, quality=88, optimize=True)
        made += 1
        print("OK", dst.relative_to(ROOT))
    print(f"dialog_busts_ok count={made}")


if __name__ == "__main__":
    main()
