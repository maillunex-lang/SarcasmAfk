#!/usr/bin/env python3
"""Validate CH01 RPG expansion content (Slice A schema checks)."""
from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
DATA = ROOT / "client" / "data"


def load(path: pathlib.Path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def fail(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    main_quests = load(DATA / "quests" / "ch01_quests.json")
    side = load(DATA / "quests" / "ch01_sidequests.json")
    poi = load(DATA / "poi" / "ch01_poi.json")
    rewards = load(DATA / "rewards" / "ch01_expansion_rewards.json")
    dialogues = load(DATA / "dialogues" / "ch01_expansion_dialogues.json")
    equipment = load(DATA / "equipment" / "ch01_equipment.json")
    battles = load(DATA / "battles" / "ch01_battles.json")
    locations = load(DATA / "locations" / "ch01_locations.json")

    mq = main_quests.get("quests", [])
    if len(mq) != 12:
        fail(f"expected 12 main quests, got {len(mq)}")
    battle_ids = {b["battle_id"] for b in battles.get("battles", [])}
    if len(battle_ids) != 30:
        fail(f"expected 30 battles, got {len(battle_ids)}")
    loc_ids = {loc["location_id"] for loc in locations.get("locations", [])}

    sqs = side.get("sidequests", [])
    if len(sqs) != 5:
        fail(f"expected 5 sidequests, got {len(sqs)}")
    sq_ids = [s["quest_id"] for s in sqs]
    if len(set(sq_ids)) != 5:
        fail("sidequest IDs not unique")
    expected_sq = {f"CH01-SQ0{i}" for i in range(1, 6)}
    if set(sq_ids) != expected_sq:
        fail(f"sidequest IDs mismatch: {sq_ids}")

    pois = poi.get("poi", [])
    if len(pois) != 10:
        fail(f"expected 10 POI, got {len(pois)}")
    poi_ids = [p["poi_id"] for p in pois]
    if len(set(poi_ids)) != 10:
        fail("POI IDs not unique")
    expected_poi = {f"POI-{i:02d}" for i in range(1, 11)}
    if set(poi_ids) != expected_poi:
        fail(f"POI IDs mismatch: {poi_ids}")

    dlg_list = dialogues.get("dialogues", [])
    dlg_ids = [d["dialogue_id"] for d in dlg_list]
    if len(dlg_ids) != len(set(dlg_ids)):
        fail("dialogue IDs not unique")
    dlg_by_id = {d["dialogue_id"]: d for d in dlg_list}

    reward_ids = {b["bundle_id"] for b in rewards.get("bundles", [])}
    eq_ids = {e["item_id"] for e in equipment.get("items", [])}
    if "eq_ch01_clerk_coat" not in eq_ids:
        fail("missing eq_ch01_clerk_coat")

    main_quest_ids = {q["quest_id"] for q in mq}

    for s in sqs:
        loc = s.get("location_id")
        if loc not in loc_ids:
            fail(f"{s['quest_id']} bad location {loc}")
        req = s.get("required_quest")
        if req and req not in main_quest_ids:
            fail(f"{s['quest_id']} required_quest {req} missing")
        for did in (s.get("start_dialogue_id"), s.get("complete_dialogue_id")):
            if did and did not in dlg_by_id:
                fail(f"{s['quest_id']} missing dialogue {did}")
        rb = s.get("reward_bundle_id")
        if rb not in reward_ids:
            fail(f"{s['quest_id']} missing reward {rb}")
        for pid in s.get("poi_ids", []):
            if pid not in set(poi_ids):
                fail(f"{s['quest_id']} references missing POI {pid}")
        if s.get("grants_heroes"):
            fail(f"{s['quest_id']} must not auto-grant heroes")

    for p in pois:
        required = [
            "poi_id",
            "location_id",
            "title",
            "description",
            "icon_asset_id",
            "interaction_type",
            "actions",
            "one_time",
            "state",
            "sort_order",
            "accessibility_label",
        ]
        for key in required:
            if key not in p:
                fail(f"{p.get('poi_id')} missing field {key}")
        if p["location_id"] not in loc_ids:
            fail(f"{p['poi_id']} bad location {p['location_id']}")
        rq = p.get("required_quest")
        if rq and rq not in main_quest_ids:
            fail(f"{p['poi_id']} required_quest {rq} missing")
        did = p.get("dialogue_id")
        if did and did not in dlg_by_id:
            fail(f"{p['poi_id']} missing dialogue {did}")
        for flag in p.get("required_flags") or []:
            if flag.startswith("battle:"):
                bid = flag.split(":", 1)[1]
                if bid not in battle_ids:
                    fail(f"{p['poi_id']} bad battle flag {flag}")

    for b in rewards.get("bundles", []):
        for eq in b.get("equipment") or []:
            if eq not in eq_ids:
                fail(f"reward {b['bundle_id']} unknown equipment {eq}")
        if int(b.get("premium_currency", 0) or 0) != 0:
            fail(f"reward {b['bundle_id']} must not grant premium")

    # Main dialogues Q01-Q12 still present and unchanged count
    for i in range(1, 13):
        path = DATA / "dialogues" / f"ch01_q{i:02d}.json"
        if not path.is_file():
            fail(f"missing main dialogue {path}")
        d = load(path)
        if not d.get("lines"):
            fail(f"empty main dialogue {path}")

    # Expansion inserts present
    for ex in [f"CH01-EX-0{i}" for i in range(1, 7)]:
        if ex not in dlg_by_id:
            fail(f"missing insert dialogue {ex}")

    print("OK ch01 expansion validation")
    print(f"  main_quests={len(mq)} battles={len(battle_ids)} sidequests={len(sqs)} poi={len(pois)}")
    print(f"  dialogues={len(dlg_ids)} rewards={len(reward_ids)} equipment={len(eq_ids)}")


if __name__ == "__main__":
    main()
