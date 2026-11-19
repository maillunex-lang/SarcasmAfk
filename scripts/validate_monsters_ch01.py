#!/usr/bin/env python3
"""Validate MONSTERS-CH01-001 catalog: 29 IDs, no E18/E19, battles link."""
from __future__ import annotations
import json, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]

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
    pilots = {"E01","E03","E05","E10","E13","E20","E22","E28","E30"}
    for p in pilots:
        path = ROOT / f"client/assets/enemies/{p}/concept.jpg"
        if not path.exists():
            fail(f"missing pilot concept {path}")
    print("OK monsters-ch01 validation")
    print(f"  enemies=29 battles_types={len(used)} pilots={len(pilots)}")

if __name__ == "__main__":
    main()
