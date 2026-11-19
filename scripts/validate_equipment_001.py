#!/usr/bin/env python3
"""Validate EQUIPMENT-001 catalog (32 templates, sets, CH01 rewards)."""
from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
DATA = ROOT / "client" / "data" / "equipment"


def fail(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    cat = json.loads((DATA / "equipment_catalog_v1.json").read_text(encoding="utf-8"))
    sets = json.loads((DATA / "equipment_sets.json").read_text(encoding="utf-8"))
    templates = cat.get("templates", [])
    if len(templates) != 32:
        fail(f"expected 32 templates, got {len(templates)}")
    ids = [t["template_id"] for t in templates]
    if len(set(ids)) != 32:
        fail("template IDs not unique")
    slots = set(cat.get("slots", []))
    rarities = set(cat.get("rarities", []))
    set_ids = {s["set_id"] for s in sets.get("sets", [])}
    mythic_count = 0
    for t in templates:
        if t["slot"] not in slots:
            fail(f"{t['template_id']} bad slot")
        if t["rarity"] not in rarities:
            fail(f"{t['template_id']} bad rarity")
        if t["rarity"] == "Mythic":
            mythic_count += 1
        sid = t.get("set_id")
        if sid and sid not in set_ids:
            fail(f"{t['template_id']} unknown set {sid}")
        for k, v in (t.get("base_stats") or {}).items():
            if k not in ("hp", "atk", "defense", "speed"):
                fail(f"{t['template_id']} unsupported stat {k}")
            if not isinstance(v, (int, float)) or v < 0:
                fail(f"{t['template_id']} bad stat {k}={v}")
        if int(t.get("required_hero_level", 1)) < 1:
            fail(f"{t['template_id']} bad req level")
        if int(t.get("max_upgrade", 0)) < 0:
            fail(f"{t['template_id']} bad max_upgrade")
    if mythic_count != 0:
        fail("Mythic items must not be in CH01 catalog pack")
    # aliases map to existing templates
    for old, new in (cat.get("aliases") or {}).items():
        if new not in ids:
            fail(f"alias {old} -> missing {new}")
    # CH01 rewards
    required = {
        "eq_n_starter_blade",
        "eq_ch01_clerk_coat",
        "eq_n_starter_charm",
        "eq_n_blank_form",
        "eq_r_queue_token",
        "eq_sr_emergency_armor",
    }
    reward_ids = {r["template_id"] for r in cat.get("ch01_guaranteed_rewards", [])}
    if reward_ids != required:
        fail(f"CH01 rewards mismatch {reward_ids}")
    if "eq_ch01_clerk_coat" not in ids:
        fail("missing eq_ch01_clerk_coat")
    mats = {m["item_id"] for m in cat.get("materials", [])}
    if "mat_equipment_scrap" not in mats:
        fail("missing mat_equipment_scrap")
    print("OK equipment-001 validation")
    print(f"  templates={len(templates)} sets={len(set_ids)} ch01_rewards={len(reward_ids)}")


if __name__ == "__main__":
    main()
