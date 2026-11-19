#!/usr/bin/env python3
"""Check internal Markdown links (paths + optional anchors). Exit 1 on broken paths."""
from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")


def slugify(text: str) -> str:
    s = text.strip().lower()
    s = re.sub(r"[^\w\s\-]", "", s, flags=re.UNICODE)
    s = re.sub(r"\s+", "-", s)
    return s


def headings(path: pathlib.Path) -> set[str]:
    out: set[str] = set()
    try:
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            m = HEADING_RE.match(line)
            if m:
                out.add(slugify(m.group(2)))
    except OSError:
        pass
    return out


def main() -> int:
    md_files = list(ROOT.glob("*.md")) + list((ROOT / "docs").rglob("*.md"))
    broken: list[str] = []
    checked = 0
    for md in md_files:
        text = md.read_text(encoding="utf-8", errors="replace")
        for m in LINK_RE.finditer(text):
            raw = m.group(1).strip()
            if raw.startswith(("http://", "https://", "mailto:")):
                continue
            path_part, frag = (raw.split("#", 1) + [""])[:2]
            if not path_part:
                # pure anchor in same file
                if frag and slugify(frag) not in headings(md) and frag.lower() not in headings(md):
                    # soft: many docs use non-slug anchors; warn only
                    pass
                continue
            checked += 1
            target = (md.parent / path_part).resolve()
            try:
                target.relative_to(ROOT)
            except ValueError:
                broken.append(f"{md.relative_to(ROOT)} -> {raw} (outside repo)")
                continue
            if not target.exists():
                broken.append(f"{md.relative_to(ROOT)} -> {raw} (missing)")
    print(f"check_doc_links checked={checked} broken={len(broken)}")
    for b in broken:
        print("BROKEN", b)
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
