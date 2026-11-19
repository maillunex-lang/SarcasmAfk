#!/usr/bin/env python3
"""Cross-check CH01 content IDs, battle→enemy_type, sprites, and dynamic Godot asset paths."""
from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
DATA = ROOT / "client" / "data"
ASSETS = ROOT / "client" / "assets"


def load(path: pathlib.Path):
    return json.loads(path.read_text(encoding="utf-8"))


def res_to_disk(res_path: str) -> pathlib.Path | None:
    if not res_path or not isinstance(res_path, str):
        return None
    if not res_path.startswith("res://"):
        return None
    rel = res_path[len("res://") :]
    return ROOT / "client" / rel


def exists_res(res_path: str) -> bool:
    p = res_to_disk(res_path)
    return bool(p and p.is_file())


def dynamic_enemy_paths(eid: str) -> dict[str, str]:
    """Mirrors AssetPaths enemy helpers (concept / idle / combat still / atlases)."""
    return {
        "concept": f"res://assets/enemies/{eid}/concept.jpg",
        "idle": f"res://assets/enemies/{eid}/idle.jpg",
        "portrait": f"res://assets/enemies/{eid}/portrait.jpg",
        "combat_idle": f"res://assets/combat/{eid}/{eid}_idle.png",
        "atlas_idle": f"res://assets/enemies/{eid}/atlases/idle.jpg",
    }


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    quests = load(DATA / "quests/ch01_quests.json")["quests"]
    battles = load(DATA / "battles/ch01_battles.json")["battles"]
    locations = load(DATA / "locations/ch01_locations.json")["locations"]
    enemies = load(DATA / "enemies/ch01_enemies.json")["enemies"]

    q_ids = {str(q.get("quest_id", q.get("id", ""))) for q in quests}
    b_ids = {str(b.get("battle_id", b.get("id", ""))) for b in battles}
    l_ids = {str(x.get("location_id", x.get("id", ""))) for x in locations}
    e_ids = {str(e.get("id", e.get("enemy_type", ""))) for e in enemies}
    e_by_id = {str(e.get("id", "")): e for e in enemies}

    # Required CH01 ID sets
    for i in range(1, 13):
        qid = f"CH01-Q{i:02d}"
        if qid not in q_ids:
            errors.append(f"missing quest {qid}")
    for i in range(1, 31):
        bid = f"B{i:02d}"
        if bid not in b_ids:
            errors.append(f"missing battle {bid}")
    for i in range(1, 11):
        lid = f"L{i:02d}"
        if lid not in l_ids:
            errors.append(f"missing location {lid}")

    for i in range(1, 13):
        p = DATA / "dialogues" / f"ch01_q{i:02d}.json"
        if not p.is_file():
            errors.append(f"missing dialogue file {p.relative_to(ROOT)}")

    # Quest → battle / location / dialogue
    for q in quests:
        qid = str(q.get("quest_id", ""))
        lid = str(q.get("location_id", ""))
        if lid and lid not in l_ids:
            errors.append(f"quest {qid} unknown location_id {lid}")
        for bid in q.get("battle_ids", []) or []:
            if str(bid) not in b_ids:
                errors.append(f"quest {qid} unknown battle_id {bid}")

    # Location layers (dynamic + JSON)
    for loc in locations:
        lid = str(loc.get("location_id", ""))
        layers = loc.get("layers") or {}
        if not isinstance(layers, dict):
            continue
        for layer_name, res in layers.items():
            if not res:
                continue
            if not str(res).startswith("res://"):
                errors.append(f"location {lid} layer {layer_name} not res:// ({res})")
                continue
            if not exists_res(str(res)):
                errors.append(f"location {lid} missing asset {res}")
        # dynamic convention AssetPaths.location_layer — enforced for CH01 L01–L10
        if lid in {f"L{i:02d}" for i in range(1, 11)}:
            for layer_name in ("sky", "far", "mid"):
                dyn = f"res://assets/locations/{lid}/loc_{lid}_{layer_name}.jpg"
                if not exists_res(dyn):
                    override = str((layers or {}).get(layer_name, ""))
                    if not override or not exists_res(override):
                        errors.append(f"location {lid} missing dynamic layer {dyn}")
        elif layers:
            # non-canonical loc: only validate declared layer paths
            pass

    used_enemy_types: set[str] = set()
    sprite_checked = 0

    for b in battles:
        bid = str(b.get("battle_id", ""))
        qid = str(b.get("quest_id", ""))
        lid = str(b.get("location_id", ""))
        if qid and qid not in q_ids:
            errors.append(f"battle {bid} bad quest_id {qid}")
        if lid and lid not in l_ids:
            errors.append(f"battle {bid} bad location_id {lid}")

        for en in b.get("enemies", []) or []:
            if not isinstance(en, dict):
                errors.append(f"battle {bid} enemy entry not object")
                continue
            et = str(en.get("enemy_type", ""))
            if not et:
                errors.append(f"battle {bid} enemy missing enemy_type")
                continue
            used_enemy_types.add(et)
            if et not in e_ids:
                errors.append(f"battle {bid} unknown enemy_type {et}")

            sprite = str(en.get("sprite", ""))
            if sprite:
                sprite_checked += 1
                if not sprite.startswith("res://"):
                    errors.append(f"battle {bid} sprite not res:// ({sprite})")
                elif not exists_res(sprite):
                    errors.append(f"battle {bid} missing sprite {sprite}")

            # dynamic combat still expected for known types
            dyn_combat = dynamic_enemy_paths(et)["combat_idle"]
            if et in e_ids and not exists_res(dyn_combat):
                # allow battle sprite override if it exists
                if not (sprite and exists_res(sprite)):
                    errors.append(f"enemy {et} missing combat idle {dyn_combat}")

    # Per-enemy catalog assets + dynamic paths
    for eid, e in e_by_id.items():
        if not eid:
            continue
        for field in ("sprite", "portrait", "idle"):
            res = str(e.get(field, "") or "")
            if res and not exists_res(res):
                errors.append(f"enemy {eid} catalog {field} missing {res}")
        paths = dynamic_enemy_paths(eid)
        # concept required by atlas generator / validate_monsters
        if not exists_res(paths["concept"]):
            errors.append(f"enemy {eid} missing concept {paths['concept']}")
        # at least one of idle still / combat idle / atlas idle
        if not (
            exists_res(paths["idle"])
            or exists_res(paths["combat_idle"])
            or exists_res(paths["atlas_idle"])
        ):
            errors.append(f"enemy {eid} missing idle/combat/atlas still")

    # Enemy types referenced in battles but not in catalog already flagged;
    # catalog types never used → warning only (may be reserved)
    unused = sorted(e_ids - used_enemy_types - {""})
    for eid in unused:
        warnings.append(f"enemy {eid} in catalog but unused in ch01_battles")

    print(
        "check_content_refs",
        f"quests={len(q_ids)} battles={len(b_ids)} locations={len(l_ids)} enemies={len(e_ids)}",
        f"sprites_checked={sprite_checked}",
        f"errors={len(errors)} warnings={len(warnings)}",
    )
    for e in errors[:80]:
        print("ERR", e)
    for w in warnings[:20]:
        print("WARN", w)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
