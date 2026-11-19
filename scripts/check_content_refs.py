#!/usr/bin/env python3
"""Cross-check CH01 quest/battle/location/enemy ID presence (read-only)."""
from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
DATA = ROOT / "client" / "data"


def load(path: pathlib.Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    errors: list[str] = []
    quests = load(DATA / "quests/ch01_quests.json")["quests"]
    battles = load(DATA / "battles/ch01_battles.json")["battles"]
    locations = load(DATA / "locations/ch01_locations.json")["locations"]
    enemies = load(DATA / "enemies/ch01_enemies.json")["enemies"]
    q_ids = {str(q.get("quest_id", q.get("id", ""))) for q in quests}
    b_ids = {str(b.get("battle_id", b.get("id", ""))) for b in battles}
    l_ids = {str(x.get("location_id", x.get("id", ""))) for x in locations}
    e_ids = {str(e.get("id", e.get("enemy_type", ""))) for e in enemies}

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

    # battle → quest / location refs
    for b in battles:
        qid = str(b.get("quest_id", ""))
        lid = str(b.get("location_id", ""))
        if qid and qid not in q_ids:
            errors.append(f"battle {b.get('battle_id')} bad quest_id {qid}")
        if lid and lid not in l_ids:
            errors.append(f"battle {b.get('battle_id')} bad location_id {lid}")

    print(
        "check_content_refs",
        f"quests={len(q_ids)} battles={len(b_ids)} locations={len(l_ids)} enemies={len(e_ids)}",
        f"errors={len(errors)}",
    )
    for e in errors[:50]:
        print("ERR", e)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
