#!/usr/bin/env python3
"""Check internal Markdown links: file paths + GitHub-style anchors (incl. duplicates)."""
from __future__ import annotations

import pathlib
import re
import sys
import unicodedata

ROOT = pathlib.Path(__file__).resolve().parents[1]
LINK_RE = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
# strip simple markdown decorations inside headings
MD_DECOR_RE = re.compile(r"[`*_~]+")


def github_slug(text: str) -> str:
    """Approximate GitHub Flavored Markdown heading anchors (unicode kept)."""
    s = MD_DECOR_RE.sub("", text.strip()).lower()
    # NFKC for compatibility forms
    s = unicodedata.normalize("NFKC", s)
    out: list[str] = []
    for ch in s:
        cat = unicodedata.category(ch)
        if ch in (" ", "-", "_"):
            out.append("-" if ch == " " else ch)
        elif cat.startswith("L") or cat.startswith("N"):
            out.append(ch)
        # drop punctuation / symbols
    slug = "".join(out)
    slug = re.sub(r"-{2,}", "-", slug).strip("-")
    return slug


def heading_anchor_set(path: pathlib.Path) -> set[str]:
    """Build the set of valid anchors, applying -1, -2… for duplicate titles."""
    seen_counts: dict[str, int] = {}
    anchors: set[str] = set()
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return anchors
    for line in lines:
        m = HEADING_RE.match(line)
        if not m:
            continue
        base = github_slug(m.group(2))
        if base == "":
            continue
        n = seen_counts.get(base, 0)
        seen_counts[base] = n + 1
        slug = base if n == 0 else f"{base}-{n}"
        anchors.add(slug)
        # also accept raw percent-decoded / exact base for first occurrence convenience
        if n == 0:
            anchors.add(base)
    return anchors


def resolve_md(link_path: str, from_file: pathlib.Path) -> pathlib.Path | None:
    if not link_path:
        return from_file
    target = (from_file.parent / link_path).resolve()
    try:
        target.relative_to(ROOT.resolve())
    except ValueError:
        return None
    return target


def main() -> int:
    md_files = list(ROOT.glob("*.md")) + list((ROOT / "docs").rglob("*.md"))
    # precompute anchors
    anchor_cache = {p.resolve(): heading_anchor_set(p) for p in md_files}

    broken: list[str] = []
    checked_paths = 0
    checked_anchors = 0

    for md in md_files:
        text = md.read_text(encoding="utf-8", errors="replace")
        for m in LINK_RE.finditer(text):
            raw = m.group(1).strip()
            if not raw or raw.startswith(("http://", "https://", "mailto:", "tel:")):
                continue
            # ignore pure images already excluded by (?<!!)
            if " " in raw and not raw.startswith("#"):
                # possible "path \"title\"" form
                raw = raw.split(" ", 1)[0].strip("\"'")

            path_part, frag = (raw.split("#", 1) + [""])[:2]
            frag = frag.strip()

            if path_part:
                checked_paths += 1
                target = resolve_md(path_part, md)
                if target is None:
                    broken.append(f"{md.relative_to(ROOT)} -> {raw} (outside repo)")
                    continue
                if not target.exists():
                    broken.append(f"{md.relative_to(ROOT)} -> {raw} (missing file)")
                    continue
                if frag:
                    if target.suffix.lower() != ".md":
                        # non-md fragment (e.g. html) — skip strict check
                        continue
                    checked_anchors += 1
                    anchors = anchor_cache.get(target.resolve()) or heading_anchor_set(target)
                    want = frag
                    # browsers may keep unicode; compare slugified fragment too
                    want_slug = github_slug(frag.replace("-", " ")) if "%" not in frag else frag
                    # prefer exact slug match as authored
                    if want not in anchors and want.lower() not in anchors and want_slug not in anchors:
                        broken.append(
                            f"{md.relative_to(ROOT)} -> {raw} (bad anchor; have {len(anchors)} headings)"
                        )
            else:
                # same-file anchor
                if not frag:
                    continue
                checked_anchors += 1
                anchors = anchor_cache.get(md.resolve()) or heading_anchor_set(md)
                if frag not in anchors and frag.lower() not in anchors:
                    broken.append(
                        f"{md.relative_to(ROOT)} -> #{frag} (bad same-file anchor)"
                    )

    print(
        f"check_doc_links paths={checked_paths} anchors={checked_anchors} broken={len(broken)}"
    )
    for b in broken:
        print("BROKEN", b)
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
