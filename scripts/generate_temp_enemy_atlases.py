#!/usr/bin/env python3
"""Generate TEMP multi-frame combat atlases for all CH01 enemies.

Procedural warp/tint sheets from concept.jpg — not Stage E / D-ART-06 final art.
Layout matches Blender pipeline drafts: 8 × 256×256 horizontal PNG + JSON meta.
"""
from __future__ import annotations

import json
import math
import pathlib
import sys

from PIL import Image, ImageEnhance, ImageOps

ROOT = pathlib.Path(__file__).resolve().parents[1]
ENEMIES_DIR = ROOT / "client/assets/enemies"
CATALOG = ROOT / "client/data/enemies/enemy_catalog_ch01.json"
REGISTRY = ROOT / "client/data/enemies/enemy_art_registry.json"
CH01 = ROOT / "client/data/enemies/ch01_enemies.json"

FRAME = 256
FRAME_COUNT = 8
ANIMS = ("idle", "attack", "hit", "death", "special", "telegraph")


def fail(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def load_base(eid: str) -> Image.Image:
    path = ENEMIES_DIR / eid / "concept.jpg"
    if not path.exists():
        path = ENEMIES_DIR / eid / "idle.jpg"
    if not path.exists():
        fail(f"no concept/idle for {eid}")
    img = Image.open(path).convert("RGBA")
    # Letterbox to square then downscale to combat cell size.
    side = max(img.size)
    canvas = Image.new("RGBA", (side, side), (12, 18, 36, 255))
    ox = (side - img.width) // 2
    oy = (side - img.height) // 2
    canvas.paste(img, (ox, oy), img)
    return canvas.resize((FRAME, FRAME), Image.Resampling.LANCZOS)


def _affine(img: Image.Image, scale: float, dx: float, dy: float, rot: float = 0.0) -> Image.Image:
    w, h = img.size
    cx, cy = w / 2, h / 2
    # PIL AFFINE maps output→input; build inverse of translate∘rotate∘scale around center.
    rad = math.radians(rot)
    cos_a, sin_a = math.cos(rad), math.sin(rad)
    # out = T(dx,dy) * R * S * (in - c) + c
    # invert: in = S^-1 * R^-1 * (out - c - T) + c
    a = cos_a / scale
    b = sin_a / scale
    c = -a * (cx + dx) - b * (cy + dy) + cx
    d = -sin_a / scale
    e = cos_a / scale
    f = -d * (cx + dx) - e * (cy + dy) + cy
    return img.transform(
        (w, h),
        Image.Transform.AFFINE,
        (a, b, c, d, e, f),
        resample=Image.Resampling.BILINEAR,
        fillcolor=(12, 18, 36, 255),
    )


def _tint(img: Image.Image, rgb_mul: tuple[float, float, float], alpha_mul: float = 1.0) -> Image.Image:
    r, g, b, a = img.split()
    r = r.point(lambda v: max(0, min(255, int(v * rgb_mul[0]))))
    g = g.point(lambda v: max(0, min(255, int(v * rgb_mul[1]))))
    b = b.point(lambda v: max(0, min(255, int(v * rgb_mul[2]))))
    if alpha_mul != 1.0:
        a = a.point(lambda v: max(0, min(255, int(v * alpha_mul))))
    return Image.merge("RGBA", (r, g, b, a))


def _brightness(img: Image.Image, factor: float) -> Image.Image:
    return ImageEnhance.Brightness(img).enhance(factor)


def frame_for(anim: str, i: int, base: Image.Image) -> Image.Image:
    t = i / max(FRAME_COUNT - 1, 1)
    wave = math.sin(t * math.pi * 2)
    if anim == "idle":
        # Subtle bob + breathing scale.
        return _affine(base, 1.0 + 0.03 * wave, 0, -4 * wave, rot=1.2 * wave)
    if anim == "attack":
        # Wind-up then lunge forward (negative X for left-facing enemy side is fine as TEMP).
        if i < 3:
            return _affine(base, 0.96 - 0.02 * i, -6 * i, 2 * i, rot=-2 * i)
        return _affine(base, 1.08 + 0.02 * (i - 3), 18 + 6 * (i - 3), -4, rot=3)
    if anim == "hit":
        # Recoil + red flash.
        flashed = _tint(base, (1.35, 0.75, 0.75))
        return _affine(flashed, 1.0 - 0.04 * abs(wave), -10 * abs(wave), 4 * abs(wave), rot=-6 * wave)
    if anim == "death":
        # Sink, desaturate, fade.
        gray = ImageOps.grayscale(base).convert("RGBA")
        mix = Image.blend(base, gray, min(1.0, t * 1.1))
        faded = _tint(mix, (0.85, 0.85, 0.9), alpha_mul=1.0 - 0.55 * t)
        return _affine(faded, 1.0 - 0.12 * t, 0, 18 * t, rot=8 * t)
    if anim == "special":
        # Hue-ish pulse via channel swap + scale punch.
        hot = _tint(base, (0.85 + 0.4 * abs(wave), 0.95, 1.25 + 0.2 * abs(wave)))
        hot = _brightness(hot, 1.0 + 0.15 * abs(wave))
        return _affine(hot, 1.0 + 0.08 * abs(wave), 4 * wave, -6 * abs(wave), rot=4 * wave)
    if anim == "telegraph":
        # Bright flash outline proxy.
        bright = _brightness(base, 1.15 + 0.35 * abs(wave))
        bright = _tint(bright, (1.1, 1.05, 0.85 + 0.25 * abs(wave)))
        return _affine(bright, 1.0 + 0.05 * abs(wave), 0, 0, rot=0)
    fail(f"unknown anim {anim}")
    return base


def pack_atlas(frames: list[Image.Image], out_img: pathlib.Path, out_json: pathlib.Path, eid: str, anim: str) -> None:
    # Opaque navy TEMP sheets as JPEG (concepts have no real alpha; keeps repo size sane).
    atlas = Image.new("RGB", (FRAME * FRAME_COUNT, FRAME), (12, 18, 36))
    meta_frames = []
    for i, fr in enumerate(frames):
        atlas.paste(fr.convert("RGB"), (i * FRAME, 0))
        meta_frames.append(
            {
                "name": f"{anim}_{i:02d}",
                "x": i * FRAME,
                "y": 0,
                "w": FRAME,
                "h": FRAME,
                "source": f"proc_{anim}_{i:02d}.jpg",
            }
        )
    out_img.parent.mkdir(parents=True, exist_ok=True)
    # Remove prior PNG drafts if regenerating.
    png_legacy = out_img.with_suffix(".png")
    if png_legacy.exists() and png_legacy != out_img:
        png_legacy.unlink()
    atlas.save(out_img, "JPEG", quality=82, optimize=True)
    meta = {
        "asset_id": eid,
        "animation": anim,
        "frame_count": FRAME_COUNT,
        "frame_w": FRAME,
        "frame_h": FRAME,
        "atlas_w": FRAME * FRAME_COUNT,
        "atlas_h": FRAME,
        "image": out_img.name,
        "transparent": False,
        "opaque_pixels": FRAME * FRAME_COUNT * FRAME,
        "frames": meta_frames,
        "status": "TEMP_ATLAS",
        "note": "TEMP procedural JPEG atlas from concept.jpg — not Stage E (D-ART-06)",
    }
    out_json.write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_idle_still(first: Image.Image, eid: str) -> None:
    """Also refresh combat/{eid}/{eid}_idle.png for AssetPaths.combat_idle."""
    combat_dir = ROOT / "client/assets/combat" / eid
    combat_dir.mkdir(parents=True, exist_ok=True)
    # Keep PNG still for existing AssetPaths.combat_idle contract (H01/E01 drafts).
    first.convert("RGBA").save(combat_dir / f"{eid}_idle.png", "PNG", optimize=True)


def update_catalog(ids: list[str]) -> None:
    cat = json.loads(CATALOG.read_text(encoding="utf-8"))
    cat["note"] = (
        "Abilities Draft. TEMP multi-frame atlases for all 29 (procedural from concepts). "
        "Not Stage E / D-ART-06 final art."
    )
    by_id = {e["id"]: e for e in cat["enemies"]}
    for eid in ids:
        e = by_id[eid]
        art = e.setdefault("art", {})
        art["status"] = "TEMP_ATLAS"
        base = f"res://assets/enemies/{eid}"
        art["concept"] = f"{base}/concept.jpg"
        art["portrait"] = f"{base}/portrait.jpg"
        art["sprite"] = f"{base}/atlases/idle.jpg"
        art["atlases"] = {
            anim: f"{base}/atlases/{anim}.jpg" for anim in ANIMS
        }
    CATALOG.write_text(json.dumps(cat, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def update_registry(ids: list[str]) -> None:
    reg = {
        "version": 1,
        "balance_version": "MONSTERS-CH01-001-draft-1",
        "policy": "TEMP multi-frame atlases for all 29 (procedural). D-ART-06: not FINAL Stage E.",
        "count_temp_concepts": 29,
        "count_temp_atlases": 29,
        "count_unique": 29,
        "anims": list(ANIMS),
        "frame_count": FRAME_COUNT,
        "frame_size": FRAME,
        "assets": [],
    }
    for eid in ids:
        base = f"res://assets/enemies/{eid}"
        reg["assets"].append(
            {
                "id": eid,
                "status": "TEMP_ATLAS",
                "concept": f"{base}/concept.jpg",
                "portrait": f"{base}/portrait.jpg",
                "idle": f"{base}/idle.jpg",
                "atlases": {anim: f"{base}/atlases/{anim}.jpg" for anim in ANIMS},
            }
        )
    REGISTRY.write_text(json.dumps(reg, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def update_ch01_enemies(ids: list[str]) -> None:
    data = json.loads(CH01.read_text(encoding="utf-8"))
    for e in data["enemies"]:
        eid = e["id"]
        if eid in ids:
            e["sprite"] = f"res://assets/enemies/{eid}/atlases/idle.jpg"
            e["note"] = "TEMP multi-frame atlases (MONSTERS-CH01); not Stage E"
    data["note"] = "All 29 enemy_types have unique TEMP multi-frame atlases (idle/attack/hit/death/special/telegraph)."
    CH01.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    cat = json.loads(CATALOG.read_text(encoding="utf-8"))
    ids = [e["id"] for e in cat["enemies"]]
    if len(ids) != 29:
        fail(f"expected 29 enemies, got {len(ids)}")
    for eid in ids:
        print(f"atlas {eid} …")
        base = load_base(eid)
        out_dir = ENEMIES_DIR / eid / "atlases"
        first_idle = None
        for anim in ANIMS:
            frames = [frame_for(anim, i, base) for i in range(FRAME_COUNT)]
            if anim == "idle":
                first_idle = frames[0]
            pack_atlas(frames, out_dir / f"{anim}.jpg", out_dir / f"{anim}.json", eid, anim)
        if first_idle is not None:
            write_idle_still(first_idle, eid)
    update_catalog(ids)
    update_registry(ids)
    update_ch01_enemies(ids)
    print(f"OK generated TEMP atlases for {len(ids)} enemies × {len(ANIMS)} anims × {FRAME_COUNT} frames")


if __name__ == "__main__":
    main()
