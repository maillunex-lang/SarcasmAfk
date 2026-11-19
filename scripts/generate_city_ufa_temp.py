#!/usr/bin/env python3
"""Generate TEMP panoramic layers for Ufa city hub (CITY-HUB-001)."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "client" / "assets" / "city" / "ufa"
W, H = 2400, 1400


def _font(size: int):
    for p in (
        ROOT / "client/assets/fonts/Manrope-Bold.ttf",
        ROOT / "client/assets/fonts/Manrope-Regular.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ):
        if Path(p).is_file():
            return ImageFont.truetype(str(p), size=size)
    return ImageFont.load_default()


def sky() -> Image.Image:
    img = Image.new("RGB", (W, H), (16, 28, 53))
    d = ImageDraw.Draw(img)
    for y in range(0, 520):
        t = y / 520.0
        r = int(16 + (45 - 16) * t)
        g = int(28 + (70 - 28) * t)
        b = int(53 + (110 - 53) * t)
        d.line([(0, y), (W, y)], fill=(r, g, b))
    # soft sun disc
    d.ellipse([1700, 60, 1900, 260], fill=(232, 188, 104))
    d.ellipse([1720, 80, 1880, 240], fill=(245, 240, 229))
    return img


def far() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ridge = [
        (0, 520),
        (120, 430),
        (280, 480),
        (460, 390),
        (680, 460),
        (900, 370),
        (1120, 450),
        (1340, 360),
        (1600, 440),
        (1840, 380),
        (2100, 430),
        (2400, 360),
        (2400, 640),
        (0, 640),
    ]
    d.polygon(ridge, fill=(29, 49, 84, 220))
    # distant towers
    for x in (520, 980, 1410, 1880):
        d.rectangle([x, 300, x + 48, 520], fill=(36, 58, 99, 230))
        d.polygon([(x - 8, 300), (x + 24, 250), (x + 56, 300)], fill=(232, 188, 104, 200))
    return img


def mid() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 560, W, H], fill=(20, 36, 64, 255))
    # plaza
    d.ellipse([820, 780, 1320, 920], fill=(36, 58, 99, 255))
    # water near dock
    d.polygon([(1900, 980), (2400, 920), (2400, 1200), (1880, 1200)], fill=(84, 217, 218, 90))
    font = _font(28)
    d.text((40, 40), "TEMP · Уфа city layers", fill=(183, 192, 212, 180), font=font)
    return img


def road() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon(
        [(0, 980), (600, 940), (1200, 1000), (1800, 930), (2400, 980), (2400, 1120), (0, 1120)],
        fill=(16, 28, 53, 240),
    )
    # dashed center
    x = 40
    while x < W:
        d.rectangle([x, 1038, x + 48, 1048], fill=(232, 188, 104, 160))
        x += 90
    return img


def composite() -> Image.Image:
    base = sky()
    for layer in (far(), mid(), road()):
        base = Image.alpha_composite(base.convert("RGBA"), layer).convert("RGB")
    d = ImageDraw.Draw(base)
    font = _font(36)
    d.text((60, 1280), "Уфа, столица Абсурда · TEMP panorama", fill=(245, 240, 229), font=font)
    return base


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    sky().save(OUT / "city_ufa_sky.jpg", quality=88)
    far().convert("RGB").save(OUT / "city_ufa_far.jpg", quality=88)
    mid().convert("RGB").save(OUT / "city_ufa_mid.jpg", quality=88)
    road().convert("RGB").save(OUT / "city_ufa_road.jpg", quality=88)
    composite().save(OUT / "city_ufa_panorama.jpg", quality=90)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
