#!/usr/bin/env python3
"""Validate MONSTERS-CH01-001 catalog: 29 IDs, atlases, battles link."""
from __future__ import annotations
import json, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ANIMS = ("idle", "attack", "hit", "death", "special", "telegraph")
MIN_FRAMES = 4
FRAME = 256


def fail(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    cat = json.loads((ROOT / "client/data/enemies/enemy_catalog_ch01.json").read_text(encoding="utf-8"))
    enemies = cat.get("enemies", [])
    if len(enemies) != 29:
        fail(f"expected 29 enemies, got {len(enemies)}")
    ids = [e["id"] for e in enemies]
    if len(set(ids)) != 29:
        fail("duplicate ids")
    if "E18" in ids or "E19" in ids:
        fail("E18/E19 must not exist")
    if "E29A" not in ids or "E30" not in ids:
        fail("missing E29A or E30")
    battles = json.loads((ROOT / "client/data/battles/ch01_battles.json").read_text(encoding="utf-8"))
    used = set()
    for b in battles["battles"]:
        for e in b.get("enemies", []):
            used.add(e["enemy_type"])
    missing = used - set(ids)
    if missing:
        fail(f"battles reference unknown types {missing}")
    unused = set(ids) - used
    if unused:
        fail(f"catalog types unused in battles {unused}")
    for e in enemies:
        eid = e["id"]
        concept = ROOT / f"client/assets/enemies/{eid}/concept.jpg"
        if not concept.exists():
            fail(f"missing concept {concept}")
        idle = ROOT / f"client/assets/enemies/{eid}/idle.jpg"
        if not idle.exists():
            fail(f"missing idle {idle}")
        art = e.get("art", {})
        atlases = art.get("atlases", {})
        for anim in ANIMS:
            ref = str(atlases.get(anim, "MISSING"))
            if ref == "MISSING" or not ref:
                fail(f"{eid} atlas {anim} is MISSING")
            rel = ref.replace("res://", "")
            img = ROOT / "client" / rel
            if not img.exists():
                fail(f"{eid} missing atlas image {img}")
            meta = img.with_suffix(".json")
            if not meta.exists():
                fail(f"{eid} missing atlas meta {meta}")
            mj = json.loads(meta.read_text(encoding="utf-8"))
            if int(mj.get("frame_count", 0)) < MIN_FRAMES:
                fail(f"{eid}/{anim} frame_count < {MIN_FRAMES}")
            if int(mj.get("frame_w", 0)) != FRAME or int(mj.get("frame_h", 0)) != FRAME:
                fail(f"{eid}/{anim} expected {FRAME}x{FRAME} cells")
            if str(mj.get("image", "")) and str(mj.get("image")) != img.name:
                fail(f"{eid}/{anim} meta image mismatch")
        combat_idle = ROOT / f"client/assets/combat/{eid}/{eid}_idle.png"
        if not combat_idle.exists():
            fail(f"missing combat idle still {combat_idle}")
    # uniqueness: no two types may share the same sprite path
    sprites = set()
    for e in json.loads((ROOT / "client/data/enemies/ch01_enemies.json").read_text(encoding="utf-8"))["enemies"]:
        sp = e.get("sprite", "")
        if sp in sprites:
            fail(f"duplicate sprite path {sp}")
        sprites.add(sp)
        if e["id"] not in sp:
            fail(f"sprite path should include id {e['id']}: {sp}")
    reg = json.loads((ROOT / "client/data/enemies/enemy_art_registry.json").read_text(encoding="utf-8"))
    if int(reg.get("count_temp_atlases", 0)) != 29:
        fail("registry count_temp_atlases != 29")
    fxreg_path = ROOT / "client/data/enemies/enemy_vfx_sfx_registry.json"
    if not fxreg_path.exists():
        fail("missing enemy_vfx_sfx_registry.json")
    fxreg = json.loads(fxreg_path.read_text(encoding="utf-8"))
    if int(fxreg.get("count_enemies", 0)) != 29:
        fail("vfx/sfx registry count_enemies != 29")
    for vfx_id, ref in (fxreg.get("vfx") or {}).items():
        rel = str(ref).replace("res://", "")
        png = ROOT / "client" / rel
        if not png.exists():
            fail(f"missing shared vfx {png}")
        meta = png.with_suffix(".json")
        if not meta.exists():
            fail(f"missing vfx meta {meta}")
    for sfx_id, ref in (fxreg.get("sfx") or {}).items():
        rel = str(ref).replace("res://", "")
        ogg = ROOT / "client" / rel
        if not ogg.exists():
            fail(f"missing shared sfx {ogg}")
    for e in enemies:
        art = e.get("art", {})
        for bucket in ("vfx", "sfx"):
            block = art.get(bucket, {})
            if not isinstance(block, dict) or not block:
                fail(f"{e['id']} missing art.{bucket}")
            for _k, ref in block.items():
                rel = str(ref).replace("res://", "")
                if not (ROOT / "client" / rel).exists():
                    fail(f"{e['id']} missing {bucket} file {rel}")
    print("OK monsters-ch01 validation")
    print(f"  enemies=29 battles_types={len(used)} atlases={len(ANIMS)} frames>={MIN_FRAMES} vfx_sfx=TEMP")


if __name__ == "__main__":
    main()
