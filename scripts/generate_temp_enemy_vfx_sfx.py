#!/usr/bin/env python3
"""Generate TEMP shared VFX sheets + procedural SFX for MONSTERS-CH01.

Not Stage E / D-ART-06. Shared library per CHARACTER_STYLE_GUIDE §9 / §12.
"""
from __future__ import annotations

import json
import math
import pathlib
import struct
import subprocess
import sys
import wave

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[1]
VFX_DIR = ROOT / "client/assets/vfx/shared"
SFX_DIR = ROOT / "client/assets/sfx/shared"
REGISTRY = ROOT / "client/data/enemies/enemy_vfx_sfx_registry.json"
CATALOG = ROOT / "client/data/enemies/enemy_catalog_ch01.json"

FRAME = 128
FRAME_COUNT = 6
SAMPLE_RATE = 22050

# Visual id → RGB accent (CHARACTER_STYLE_GUIDE colors)
VFX_DEFS = {
    "hit": {"rgb": (255, 110, 90), "shape": "slash"},       # coral damage
    "mark": {"rgb": (255, 200, 70), "shape": "ring"},       # gold mark
    "shield": {"rgb": (90, 220, 200), "shape": "hex"},      # mint/cyan shield
    "heal": {"rgb": (110, 230, 170), "shape": "cross"},     # mint heal
    "slow": {"rgb": (170, 150, 255), "shape": "wave"},      # lilac control
    "disrupt": {"rgb": (200, 140, 255), "shape": "spark"},  # lilac control
    "weaken": {"rgb": (255, 160, 80), "shape": "spark"},
    "burn": {"rgb": (255, 90, 40), "shape": "flame"},
    "special_burst": {"rgb": (80, 210, 255), "shape": "burst"},  # cyan+gold system
    "death_burst": {"rgb": (140, 150, 170), "shape": "fade"},
    "telegraph": {"rgb": (255, 230, 120), "shape": "pulse"},
    "boss_burst": {"rgb": (255, 180, 60), "shape": "burst"},
}

# special.kind → shared vfx id
KIND_TO_VFX = {
    "MARK": "mark",
    "MARK_THEN_STRIKE": "mark",
    "MARK_AND_SLOW_SPLIT": "mark",
    "MARK_EMPOWER": "mark",
    "MARK_DELAYED_STRIKE": "mark",
    "SHIELD_E28_MARK": "mark",
    "ATK_WEAKEN": "weaken",
    "WEAKEN": "weaken",
    "WEAKEN_TWO": "weaken",
    "SHIELD_SELF": "shield",
    "SHIELD_ALLY_LOWEST": "shield",
    "SHIELD_ALLY_WEAKEN_FRONT": "shield",
    "SHIELD_THEN_STRIKE": "shield",
    "GUARD_SELF": "shield",
    "SLOW": "slow",
    "SLOW_BACK": "slow",
    "SLOW_TWO": "slow",
    "DISRUPT": "disrupt",
    "DISRUPT_EMPOWER": "disrupt",
    "BURN": "burn",
    "HEAL_ALLY_LOWEST": "heal",
    "BOSS_E20": "boss_burst",
    "BOSS_E30": "boss_burst",
}

SFX_DEFS = {
    "hit": {"freq": 220, "dur": 0.12, "kind": "noise_thump"},
    "attack": {"freq": 340, "dur": 0.10, "kind": "whoosh"},
    "death": {"freq": 110, "dur": 0.28, "kind": "fall"},
    "special": {"freq": 520, "dur": 0.22, "kind": "chime"},
    "telegraph": {"freq": 660, "dur": 0.16, "kind": "warn"},
    "shield": {"freq": 480, "dur": 0.18, "kind": "chime"},
    "heal": {"freq": 700, "dur": 0.20, "kind": "chime"},
    "mark": {"freq": 400, "dur": 0.14, "kind": "tick"},
    "slow": {"freq": 160, "dur": 0.22, "kind": "fall"},
    "disrupt": {"freq": 300, "dur": 0.15, "kind": "noise_thump"},
}


def fail(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def _draw_shape(draw: ImageDraw.ImageDraw, shape: str, t: float, rgb: tuple[int, int, int], alpha: int) -> None:
    cx = cy = FRAME // 2
    color = (*rgb, alpha)
    r = int(18 + 40 * t)
    if shape == "slash":
        w = int(8 + 10 * (1 - abs(t - 0.5) * 2))
        draw.line([(cx - 48, cy + 36), (cx + 48, cy - 36)], fill=color, width=w)
        draw.line([(cx - 40, cy + 44), (cx + 40, cy - 28)], fill=(*rgb, alpha // 2), width=max(2, w // 2))
    elif shape == "ring":
        bbox = [cx - r, cy - r, cx + r, cy + r]
        draw.ellipse(bbox, outline=color, width=max(3, int(6 * (1 - t * 0.5))))
    elif shape == "hex":
        pts = []
        for i in range(6):
            a = math.radians(60 * i - 30)
            pts.append((cx + int(r * math.cos(a)), cy + int(r * math.sin(a))))
        draw.polygon(pts, outline=color)
        draw.polygon([(x, y) for x, y in pts], fill=(*rgb, max(20, alpha // 4)))
    elif shape == "cross":
        draw.rectangle([cx - 8, cy - r, cx + 8, cy + r], fill=color)
        draw.rectangle([cx - r, cy - 8, cx + r, cy + 8], fill=color)
    elif shape == "wave":
        for i in range(3):
            rr = r - i * 10
            if rr > 4:
                draw.arc([cx - rr, cy - rr // 2, cx + rr, cy + rr // 2], 200, 340, fill=color, width=3)
    elif shape == "spark":
        for i in range(8):
            a = math.radians(45 * i + t * 40)
            x2 = cx + int((20 + r) * math.cos(a))
            y2 = cy + int((20 + r) * math.sin(a))
            draw.line([(cx, cy), (x2, y2)], fill=color, width=3)
    elif shape == "flame":
        pts = [(cx, cy - r), (cx + r // 2, cy), (cx + r // 3, cy + r // 2), (cx, cy + r // 3), (cx - r // 3, cy + r // 2), (cx - r // 2, cy)]
        draw.polygon(pts, fill=color)
    elif shape == "burst":
        for i in range(12):
            a = math.radians(30 * i)
            x2 = cx + int((12 + r * 1.2) * math.cos(a))
            y2 = cy + int((12 + r * 1.2) * math.sin(a))
            draw.line([(cx, cy), (x2, y2)], fill=color, width=4)
        draw.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], fill=(*rgb, alpha))
    elif shape == "fade":
        draw.ellipse([cx - r, cy - r // 2, cx + r, cy + r], fill=(*rgb, alpha // 2))
        draw.ellipse([cx - r // 2, cy - r, cx + r // 2, cy + r // 3], fill=color)
    elif shape == "pulse":
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color, width=4)
        draw.ellipse([cx - r // 2, cy - r // 2, cx + r // 2, cy + r // 2], fill=(*rgb, alpha // 3))
    else:
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)


def pack_vfx(vfx_id: str, rgb: tuple[int, int, int], shape: str) -> None:
    atlas = Image.new("RGBA", (FRAME * FRAME_COUNT, FRAME), (0, 0, 0, 0))
    frames_meta = []
    for i in range(FRAME_COUNT):
        t = i / max(FRAME_COUNT - 1, 1)
        cell = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
        draw = ImageDraw.Draw(cell, "RGBA")
        alpha = int(255 * (1.0 - t * 0.75))
        _draw_shape(draw, shape, t, rgb, alpha)
        atlas.paste(cell, (i * FRAME, 0), cell)
        frames_meta.append({"name": f"{vfx_id}_{i:02d}", "x": i * FRAME, "y": 0, "w": FRAME, "h": FRAME})
    VFX_DIR.mkdir(parents=True, exist_ok=True)
    out_png = VFX_DIR / f"{vfx_id}.png"
    out_json = VFX_DIR / f"{vfx_id}.json"
    atlas.save(out_png, "PNG", optimize=True)
    meta = {
        "asset_id": f"vfx_{vfx_id}",
        "animation": vfx_id,
        "frame_count": FRAME_COUNT,
        "frame_w": FRAME,
        "frame_h": FRAME,
        "atlas_w": FRAME * FRAME_COUNT,
        "atlas_h": FRAME,
        "image": out_png.name,
        "transparent": True,
        "status": "TEMP_VFX",
        "note": "TEMP procedural shared VFX — not Stage E (D-ART-06)",
        "frames": frames_meta,
    }
    out_json.write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _synth(kind: str, freq: float, dur: float) -> list[float]:
    n = int(SAMPLE_RATE * dur)
    samples: list[float] = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = max(0.0, 1.0 - t / dur)
        if kind == "noise_thump":
            # cheap LCG noise
            noise = ((i * 1103515245 + 12345) & 0x7FFFFFFF) / 0x7FFFFFFF * 2 - 1
            samples.append(noise * env * 0.45 * math.exp(-t * 18) + 0.25 * math.sin(2 * math.pi * freq * t) * env)
        elif kind == "whoosh":
            f = freq * (1.0 + t * 2.5)
            samples.append(0.35 * math.sin(2 * math.pi * f * t) * env * env)
        elif kind == "fall":
            f = freq * (1.0 - 0.7 * t / dur)
            samples.append(0.4 * math.sin(2 * math.pi * f * t) * env)
        elif kind == "chime":
            samples.append(
                0.28 * math.sin(2 * math.pi * freq * t) * env
                + 0.18 * math.sin(2 * math.pi * freq * 1.5 * t) * env
            )
        elif kind == "warn":
            pulse = 0.5 + 0.5 * math.sin(2 * math.pi * 12 * t)
            samples.append(0.3 * math.sin(2 * math.pi * freq * t) * env * pulse)
        elif kind == "tick":
            samples.append(0.35 * math.sin(2 * math.pi * freq * t) * math.exp(-t * 25))
        else:
            samples.append(0.2 * math.sin(2 * math.pi * freq * t) * env)
    return samples


def write_sfx(sfx_id: str, cfg: dict) -> None:
    SFX_DIR.mkdir(parents=True, exist_ok=True)
    wav_path = SFX_DIR / f"{sfx_id}.wav"
    ogg_path = SFX_DIR / f"{sfx_id}.ogg"
    samples = _synth(cfg["kind"], float(cfg["freq"]), float(cfg["dur"]))
    with wave.open(str(wav_path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
        w.writeframes(frames)
    # Prefer OGG for Godot runtime size.
    cmd = [
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-i", str(wav_path), "-c:a", "libvorbis", "-q:a", "3", str(ogg_path),
    ]
    subprocess.run(cmd, check=True)
    wav_path.unlink(missing_ok=True)


def write_registry(ids: list[str]) -> None:
    by_enemy = {}
    cat = json.loads(CATALOG.read_text(encoding="utf-8"))
    for e in cat["enemies"]:
        eid = e["id"]
        kind = str(e.get("special", {}).get("kind", ""))
        vfx = KIND_TO_VFX.get(kind, "special_burst")
        by_enemy[eid] = {
            "special_kind": kind,
            "special_vfx": f"res://assets/vfx/shared/{vfx}.png",
            "hit_vfx": "res://assets/vfx/shared/hit.png",
            "death_vfx": "res://assets/vfx/shared/death_burst.png",
            "telegraph_vfx": "res://assets/vfx/shared/telegraph.png",
            "attack_sfx": "res://assets/sfx/shared/attack.ogg",
            "hit_sfx": "res://assets/sfx/shared/hit.ogg",
            "death_sfx": "res://assets/sfx/shared/death.ogg",
            "special_sfx": f"res://assets/sfx/shared/{'shield' if 'SHIELD' in kind or kind == 'GUARD_SELF' else 'heal' if 'HEAL' in kind else 'mark' if 'MARK' in kind else 'special'}.ogg",
        }
    reg = {
        "version": 1,
        "status": "TEMP_VFX_SFX",
        "policy": "Shared TEMP procedural VFX/SFX library for CH01 enemies. D-ART-06: not FINAL.",
        "vfx": {k: f"res://assets/vfx/shared/{k}.png" for k in VFX_DEFS},
        "sfx": {k: f"res://assets/sfx/shared/{k}.ogg" for k in SFX_DEFS},
        "kind_to_vfx": KIND_TO_VFX,
        "enemies": by_enemy,
        "count_enemies": len(by_enemy),
    }
    REGISTRY.write_text(json.dumps(reg, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    # Annotate catalog art.vfx / art.sfx
    for e in cat["enemies"]:
        eid = e["id"]
        art = e.setdefault("art", {})
        art["status"] = "TEMP_ATLAS_VFX"
        mapped = by_enemy[eid]
        art["vfx"] = {
            "hit": mapped["hit_vfx"],
            "death": mapped["death_vfx"],
            "special": mapped["special_vfx"],
            "telegraph": mapped["telegraph_vfx"],
        }
        art["sfx"] = {
            "attack": mapped["attack_sfx"],
            "hit": mapped["hit_sfx"],
            "death": mapped["death_sfx"],
            "special": mapped["special_sfx"],
        }
    cat["note"] = (
        "Abilities Draft. TEMP atlases + shared TEMP VFX/SFX for all 29. "
        "Not Stage E / D-ART-06 final art."
    )
    CATALOG.write_text(json.dumps(cat, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    for vid, cfg in VFX_DEFS.items():
        print(f"vfx {vid}")
        pack_vfx(vid, cfg["rgb"], cfg["shape"])
    for sid, cfg in SFX_DEFS.items():
        print(f"sfx {sid}")
        write_sfx(sid, cfg)
    cat = json.loads(CATALOG.read_text(encoding="utf-8"))
    ids = [e["id"] for e in cat["enemies"]]
    if len(ids) != 29:
        fail(f"expected 29 enemies, got {len(ids)}")
    write_registry(ids)
    print(f"OK TEMP VFX={len(VFX_DEFS)} SFX={len(SFX_DEFS)} enemies={len(ids)}")


if __name__ == "__main__":
    main()
