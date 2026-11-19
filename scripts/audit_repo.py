#!/usr/bin/env python3
"""REPO-REORG-001 inventory auditor (read-only).

Writes docs/reports/repo_inventory.json and prints summary stats.
Does not delete or modify project files other than the report outputs.
"""
from __future__ import annotations

import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT_JSON = ROOT / "docs" / "reports" / "repo_inventory.json"
OUT_MD = ROOT / "docs" / "reports" / "REPO_REORG_AUDIT.md"
OUT_DELETE = ROOT / "docs" / "reports" / "REPO_REORG_DELETE_CANDIDATES.md"

SECRET_NAME_RE = re.compile(
    r"(?i)(^\.env($|\.)|credentials|keystore|\.pem$|\.p12$|secret|api[_-]?key)"
)
GENERATED_HINTS = (
    ".godot/",
    "__pycache__/",
    ".pyc",
    "node_modules/",
    "/build/",
    ".apk",
    ".aab",
    ".bundle",
)
BINARY_EXT = {
    ".png",
    ".jpg",
    ".jpeg",
    ".webp",
    ".gif",
    ".ogg",
    ".wav",
    ".mp3",
    ".ttf",
    ".otf",
    ".bin",
    ".exe",
    ".dll",
    ".so",
    ".dylib",
    ".zip",
    ".7z",
    ".rar",
    ".blend",
    ".fbx",
    ".glb",
    ".gltf",
    ".ctex",
    ".import",
}


def run(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()


def classify(path: str) -> tuple[str, str, str]:
    """Return (subsystem, status, rationale). status in KEEP/CONSOLIDATE/ARCHIVE/DELETE_CANDIDATE/UNKNOWN."""
    p = path.replace("\\", "/")
    low = p.lower()
    if SECRET_NAME_RE.search(pathlib.Path(p).name) or "keystore" in low:
        return "secrets", "UNKNOWN", "Possible secret-bearing name; do not delete; rotate if real secret committed"
    if any(h in low for h in GENERATED_HINTS):
        return "generated", "DELETE_CANDIDATE", "Looks like generated/cache/build artifact"
    if p.endswith(".import"):
        return "godot-import", "KEEP", "Godot import sidecar (needed for headless ResourceLoader)"
    if p.startswith("docs/") and ("FINAL" in p or "_V2" in p or "OLD" in p or "COPY" in p):
        return "docs", "CONSOLIDATE", "Possible stale doc naming pattern"
    if p.startswith("docs/reports/"):
        return "docs-reports", "KEEP", "Historical report; archive only after link audit"
    if p.startswith("client/"):
        return "client", "KEEP", "Godot client"
    if p.startswith("server/"):
        return "server", "KEEP", "Go API"
    if p.startswith("docs/"):
        return "docs", "KEEP", "Documentation"
    if p.startswith("scripts/"):
        return "scripts", "KEEP", "Tooling/CI"
    if p.startswith("tools/"):
        if "/exports/" in p or "/work/" in p or "/source/" in p:
            return "tools-scratch", "DELETE_CANDIDATE", "Blender pipeline scratch/export worktree (verify not release)"
        return "tools", "KEEP", "Tooling"
    if p.startswith(".github/"):
        return "ci", "KEEP", "GitHub Actions"
    if p in ("AGENTS.md", "README.md", "LICENSE", ".gitignore", ".gitattributes"):
        return "root", "KEEP", "Root policy/entrypoint"
    return "other", "UNKNOWN", "Needs manual review"


def file_sha256(path: pathlib.Path, limit: int = 64 * 1024 * 1024) -> str | None:
    try:
        size = path.stat().st_size
        if size > limit:
            return None
        h = hashlib.sha256()
        with path.open("rb") as f:
            for chunk in iter(lambda: f.read(1024 * 1024), b""):
                h.update(chunk)
        return h.hexdigest()
    except OSError:
        return None


def main() -> int:
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('--json-only', action='store_true', help='Refresh JSON inventory only; do not rewrite markdown reports')
    args, _ = ap.parse_known_args()
    sha = run(["git", "rev-parse", "HEAD"])
    branch = run(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    files = run(["git", "ls-tree", "-r", "--name-only", "HEAD"]).splitlines()
    inventory = []
    hashes: dict[str, list[str]] = defaultdict(list)
    ext_counts: Counter[str] = Counter()
    status_counts: Counter[str] = Counter()
    subsystem_counts: Counter[str] = Counter()
    large: list[dict] = []
    secret_hits: list[dict] = []

    for rel in files:
        abs_path = ROOT / rel
        ext = pathlib.Path(rel).suffix.lower() or "(none)"
        ext_counts[ext] += 1
        try:
            size = abs_path.stat().st_size if abs_path.exists() else 0
        except OSError:
            size = 0
        subsystem, status, rationale = classify(rel)
        status_counts[status] += 1
        subsystem_counts[subsystem] += 1
        entry = {
            "path": rel,
            "ext": ext,
            "size": size,
            "subsystem": subsystem,
            "status": status,
            "rationale": rationale,
            "binary": ext in BINARY_EXT,
        }
        if SECRET_NAME_RE.search(pathlib.Path(rel).name) or "keystore" in rel.lower():
            secret_hits.append({"path": rel, "risk": "name_match", "note": "value not printed"})
        if size >= 512 * 1024:
            large.append({"path": rel, "size": size})
        digest = None
        if size and size <= 8 * 1024 * 1024 and ext not in {".jpg", ".jpeg", ".png", ".ogg", ".ttf"}:
            digest = file_sha256(abs_path, limit=8 * 1024 * 1024)
            if digest:
                hashes[digest].append(rel)
                entry["sha256"] = digest
        inventory.append(entry)

    duplicates = [
        {"sha256": d, "paths": ps, "count": len(ps)}
        for d, ps in hashes.items()
        if len(ps) > 1
    ]
    duplicates.sort(key=lambda x: -x["count"])

    delete_candidates = [e for e in inventory if e["status"] == "DELETE_CANDIDATE"]
    unknown = [e for e in inventory if e["status"] == "UNKNOWN"]

    # Untracked local noise (not in git)
    untracked = []
    try:
        porcelain = run(["git", "status", "--porcelain"])
        for line in porcelain.splitlines():
            if line.startswith("??"):
                untracked.append(line[3:].strip())
    except subprocess.CalledProcessError:
        pass

    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "git_sha": sha,
        "branch": branch,
        "tracked_count": len(files),
        "status_counts": dict(status_counts),
        "subsystem_counts": dict(subsystem_counts),
        "ext_top": ext_counts.most_common(40),
        "large_files": sorted(large, key=lambda x: -x["size"])[:80],
        "duplicate_groups": duplicates[:100],
        "secret_name_hits": secret_hits,
        "delete_candidates": delete_candidates,
        "unknown": unknown[:200],
        "untracked_local_count": len(untracked),
        "untracked_local_sample": untracked[:50],
        "files": inventory,
    }
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    # Markdown audit
    lines = [
        "# REPO_REORG_AUDIT.md — REPO-REORG-001",
        "",
        f"> Snapshot: **{payload['generated_at']}** · SHA `{sha}` · branch `{branch}`",
        f"> Machine inventory: [`repo_inventory.json`](repo_inventory.json)",
        "",
        "## Scope",
        "",
        "Read-only inventory of **tracked** files at HEAD. No deletions performed.",
        "",
        "## Totals",
        "",
        f"- Tracked files: **{len(files)}**",
        f"- Status counts: `{dict(status_counts)}`",
        f"- Subsystem counts: `{dict(subsystem_counts)}`",
        f"- Duplicate content groups (non-media sample ≤8MB): **{len(duplicates)}**",
        f"- Secret-name hits (paths only): **{len(secret_hits)}**",
        f"- Local untracked (not in git): **{len(untracked)}**",
        "",
        "## Large files (≥512 KiB)",
        "",
        "| Size | Path |",
        "|------|------|",
    ]
    for item in payload["large_files"][:40]:
        lines.append(f"| {item['size']} | `{item['path']}` |")

    lines += [
        "",
        "## Duplicate groups (sample)",
        "",
    ]
    if not duplicates:
        lines.append("_No non-media duplicates found in hashed subset._")
    else:
        lines.append("| Count | Paths |")
        lines.append("|------:|-------|")
        for g in duplicates[:25]:
            paths = "<br>".join(f"`{p}`" for p in g["paths"][:6])
            if len(g["paths"]) > 6:
                paths += f"<br>… +{len(g['paths'])-6}"
            lines.append(f"| {g['count']} | {paths} |")

    lines += [
        "",
        "## Secret-name hits",
        "",
        "_Values not printed. Review manually; rotate if real secrets are committed._",
        "",
    ]
    if not secret_hits:
        lines.append("_None by filename heuristic._")
    else:
        for h in secret_hits:
            lines.append(f"- `{h['path']}` — {h['risk']}")

    lines += [
        "",
        "## DELETE_CANDIDATE (tracked)",
        "",
        "_Candidates only. Owner must approve file-by-file before any deletion (PR-4)._",
        "",
    ]
    if not delete_candidates:
        lines.append("_No tracked DELETE_CANDIDATE by heuristic. See untracked local noise and delete-candidates report._")
    else:
        lines.append("| Path | Rationale |")
        lines.append("|------|-----------|")
        for e in delete_candidates:
            lines.append(f"| `{e['path']}` | {e['rationale']} |")

    lines += [
        "",
        "## Untracked local noise (not committed)",
        "",
        f"Count: **{len(untracked)}**. Dominated by Godot `.import` regenerations and blender scratch dirs.",
        "These must **not** be mass-added without review; also must **not** be `git clean`'d without owner OK.",
        "",
        "Sample:",
        "",
    ]
    for u in untracked[:30]:
        lines.append(f"- `{u}`")
    if len(untracked) > 30:
        lines.append(f"- … +{len(untracked)-30} more")

    lines += [
        "",
        "## Next (PR-2+)",
        "",
        "1. Normalize AGENTS / PROJECT_CONTEXT / STATUS / TASK_QUEUE with evidence statuses.",
        "2. Add AI_TASK_ROUTER + ARCHITECTURE_MAP + link/asset validators.",
        "3. Owner-approved cleanup only from delete-candidates list.",
        "",
    ]
    if not args.json_only:
        OUT_MD.write_text("\n".join(lines), encoding="utf-8")

    # Separate deletion candidates doc for owner confirmation
    dlines = [
        "# REPO_REORG_DELETE_CANDIDATES.md — awaiting owner confirmation",
        "",
        f"> SHA `{sha}` · **NO FILES DELETED**. Approve rows explicitly before PR-4.",
        "",
        "## A. Tracked DELETE_CANDIDATE",
        "",
    ]
    if not delete_candidates:
        dlines.append("_None from heuristic on tracked tree._")
    else:
        dlines.append("| Approve? | Path | Evidence / rationale | Risk |")
        dlines.append("|----------|------|----------------------|------|")
        for e in delete_candidates:
            dlines.append(f"| [ ] | `{e['path']}` | {e['rationale']} | Low–Med |")

    dlines += [
        "",
        "## B. Untracked local (VM-only) — safe to ignore or discard locally",
        "",
        "Not in git history. Recommended: leave alone or discard **locally** with owner OK; do not commit mass `.import` flood.",
        "",
        "| Approve discard locally? | Pattern | Count (approx) | Notes |",
        "|-------------------------|---------|----------------|-------|",
        f"| [ ] | `client/assets/**/*.import` (untracked) | ~{sum(1 for u in untracked if u.endswith('.import'))} | Regenerable by Godot `--import`; many assets already have committed `.import` |",
        f"| [ ] | `tools/blender_pipeline/exports/` | present | Scratch exports |",
        f"| [ ] | `tools/blender_pipeline/source/` | present | Scratch source |",
        f"| [ ] | `tools/blender_pipeline/work/` | present | Scratch work |",
        "",
        "## C. Suspected doc consolidation (NOT delete)",
        "",
        "Review for CONSOLIDATE/ARCHIVE in PR-2; do not delete first-class specs.",
        "",
        "- Conflicting status narratives across `STATUS.md` vs merged VO work — update in place.",
        "- Multiple audit reports under `docs/reports/` — KEEP as history.",
        "",
        "## Owner reply format",
        "",
        "Reply with checked paths, e.g.:",
        "",
        "```",
        "APPROVE DELETE:",
        "- path/one",
        "KEEP:",
        "- path/two",
        "```",
        "",
    ]
    if not args.json_only:
        OUT_DELETE.write_text("\n".join(dlines), encoding="utf-8")

    print("OK audit_repo")
    print("tracked", len(files))
    print("status", dict(status_counts))
    print("delete_candidates", len(delete_candidates))
    print("duplicates", len(duplicates))
    print("wrote", OUT_JSON.relative_to(ROOT))
    if not args.json_only:
        print("wrote", OUT_MD.relative_to(ROOT))
        print("wrote", OUT_DELETE.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
