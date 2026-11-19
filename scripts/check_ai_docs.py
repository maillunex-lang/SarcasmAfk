#!/usr/bin/env python3
"""Validate AI canon docs: required files, unique task IDs in first table column."""
from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
REQUIRED = [
    "AGENTS.md",
    "docs/PROJECT_CONTEXT.md",
    "docs/STATUS.md",
    "docs/TASK_QUEUE.md",
    "docs/DECISIONS.md",
    "docs/INDEX.md",
    "docs/AI_TASK_ROUTER.md",
    "docs/ARCHITECTURE_MAP.md",
    "docs/AI_ONBOARDING_TEST.md",
]
ALLOWED_STATUS = {
    "NOT_STARTED",
    "IN_PROGRESS",
    "PARTIAL",
    "IMPLEMENTED_UNVERIFIED",
    "BLOCKED",
    "DONE_VERIFIED",
    "DEPRECATED",
    "DONE",
    "TODO",
    "DOING",
    "CANCELLED",
}
ROW_ID_RE = re.compile(r"^\|\s*(T-\d+)\s*\|")
STATUS_CELL_RE = re.compile(r"\*\*([A-Z_]+)\*\*")


def main() -> int:
    errors: list[str] = []
    for rel in REQUIRED:
        if not (ROOT / rel).is_file():
            errors.append(f"missing required {rel}")

    tq = (ROOT / "docs/TASK_QUEUE.md").read_text(encoding="utf-8", errors="replace")
    ids: list[str] = []
    for line in tq.splitlines():
        m = ROW_ID_RE.match(line)
        if m:
            ids.append(m.group(1))
        if line.startswith("|") and "**" in line:
            cells = [c.strip() for c in line.split("|")]
            # status typically 4th cell (index 3) in queue table
            if len(cells) > 4:
                sm = STATUS_CELL_RE.search(cells[3])
                if sm and sm.group(1) not in ALLOWED_STATUS:
                    errors.append(f"unknown status {sm.group(1)} in row {cells[1]}")

    seen: set[str] = set()
    for i in ids:
        if i in seen:
            errors.append(f"duplicate task id {i}")
        seen.add(i)

    idx = (ROOT / "docs/INDEX.md").read_text(encoding="utf-8", errors="replace")
    for needle in ("PROJECT_CONTEXT.md", "AI_TASK_ROUTER.md", "ARCHITECTURE_MAP.md"):
        if needle not in idx:
            errors.append(f"INDEX.md missing link to {needle}")

    print(f"check_ai_docs task_ids={len(seen)} errors={len(errors)}")
    for e in errors:
        print("ERR", e)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
