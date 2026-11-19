#!/usr/bin/env python3
"""VISUAL OVERHAUL 001 — asset / scene audit → JSON + Markdown."""
from __future__ import annotations

import json
import pathlib
import re
import sys
from collections import Counter
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parents[1]
CLIENT = ROOT / "client"
OUT_JSON = ROOT / "client/data/visual/asset_registry.json"
OUT_MD = ROOT / "docs/VISUAL_AUDIT.md"
OUT_REG_MD = ROOT / "docs/ASSET_REGISTRY.md"

SCENES = sorted((CLIENT / "scenes").rglob("*.tscn"))
ASSET_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".ogg", ".wav", ".ttf", ".otf"}


def res_exists(res_path: str) -> bool:
    if not res_path.startswith("res://"):
        return False
    return (CLIENT / res_path.replace("res://", "")).exists()


def collect_asset_paths() -> list[dict]:
    assets = []
    for p in sorted((CLIENT / "assets").rglob("*")):
        if not p.is_file() or p.suffix.lower() not in ASSET_EXTS:
            continue
        rel = p.relative_to(CLIENT).as_posix()
        status = "TEMP" if "TEMP" in p.name.upper() or "/atlases/" in rel or "vfx/shared" in rel or "sfx/shared" in rel else "PRESENT"
        if "fonts" in rel:
            status = "FINAL_FONT_OFL"
        assets.append(
            {
                "id": rel.replace("/", "_").replace(".", "_"),
                "path": f"res://{rel}",
                "bytes": p.stat().st_size,
                "ext": p.suffix.lower(),
                "status": status,
            }
        )
    return assets


def scrape_assetpaths_constants() -> list[dict]:
    text = (CLIENT / "scripts/autoload/asset_paths.gd").read_text(encoding="utf-8")
    rows = []
    for name, path in re.findall(r'const\s+(\w+)\s*:?=\s*"(res://[^"]+)"', text):
        rows.append(
            {
                "id": name,
                "path": path,
                "exists": res_exists(path),
                "status": "OK" if res_exists(path) else "BROKEN",
            }
        )
    return rows


def scrape_scenes() -> list[dict]:
    rows = []
    for sc in SCENES:
        txt = sc.read_text(encoding="utf-8", errors="ignore")
        m = re.search(r'path="(res://scripts/ui/[^"]+\.gd)"', txt)
        script = m.group(1) if m else ""
        rows.append(
            {
                "id": sc.stem.upper(),
                "scene": f"res://{sc.relative_to(CLIENT).as_posix()}",
                "script": script,
                "script_exists": res_exists(script) if script else False,
                "build": "code_built_ScreenBase",
            }
        )
    return rows


def main() -> None:
    assets = collect_asset_paths()
    constants = scrape_assetpaths_constants()
    scenes = scrape_scenes()
    broken = [c for c in constants if not c["exists"]]
    by_ext = Counter(a["ext"] for a in assets)
    by_status = Counter(a["status"] for a in assets)

    # Heuristic screen statuses for Stage A
    screens = []
    for sc in scenes:
        sid = sc["id"]
        status = "TEMP"
        notes = "Code-built UI; art mostly TEMP branding."
        if sid in ("ARENA", "EVENTS"):
            status = "LOCKED_STUB"
            notes = "D-SCOPE-01 locked / unavailable UI."
        elif sid == "SPLASH":
            status = "POLISHED_TEMP"
            notes = "Splash uses branding + OFL fonts; art still TEMP."
        elif sid in ("HOME", "GACHA", "INVENTORY"):
            status = "POLISHED_TEMP"
            notes = "Stage C polish started; dedicated BG/portal where applicable."
        screens.append({**sc, "visual_status": status, "notes": notes})

    registry = {
        "version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "project": "BashLegends Visual Overhaul 001",
        "counts": {
            "assets": len(assets),
            "scenes": len(scenes),
            "assetpaths_constants": len(constants),
            "broken_constants": len(broken),
            "by_ext": dict(by_ext),
            "by_status": dict(by_status),
        },
        "screens": screens,
        "assetpaths_constants": constants,
        "assets": assets,
        "known_gaps": [
            {"id": "FONTS_RUNTIME", "status": "DONE_THIS_PR", "note": "Manrope+Cinzel OFL wired"},
            {"id": "MAPS_FOLDER", "status": "MISSING", "note": "client/assets/maps empty; map uses BG_MAP"},
            {"id": "DIALOG_H13_H36", "status": "MISSING", "note": "dialog portraits only H01–H12 + NPC"},
            {"id": "THEME_TRES", "status": "MISSING", "note": "No Godot Theme .tres; DesignTokens helpers only"},
            {"id": "GACHA_RESULT_VFX", "status": "TEMP", "note": "Text results only; portal art added"},
            {"id": "STAGE_E_ATLASES", "status": "BLOCKED", "note": "D-ART-06 / T-131"},
        ],
    }
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(registry, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# VISUAL_AUDIT.md — BashLegends Visual Overhaul 001",
        "",
        f"> Generated: {registry['generated_at']}",
        f"> Assets: **{len(assets)}** · Scenes: **{len(scenes)}** · Broken AssetPaths: **{len(broken)}**",
        "",
        "## Summary counts",
        "",
        f"- By extension: `{dict(by_ext)}`",
        f"- By status heuristic: `{dict(by_status)}`",
        "",
        "## Screens (23)",
        "",
        "| ID | Scene | Script | Visual status | Notes |",
        "|---|---|---|---|---|",
    ]
    for s in screens:
        lines.append(
            f"| {s['id']} | `{s['scene']}` | `{s['script']}` | {s['visual_status']} | {s['notes']} |"
        )
    lines += [
        "",
        "## Known gaps",
        "",
        "| ID | Status | Note |",
        "|---|---|---|",
    ]
    for g in registry["known_gaps"]:
        lines.append(f"| {g['id']} | {g['status']} | {g['note']} |")
    lines += [
        "",
        "## Broken AssetPaths constants",
        "",
    ]
    if broken:
        for b in broken:
            lines.append(f"- `{b['id']}` → `{b['path']}`")
    else:
        lines.append("- None.")
    lines += [
        "",
        "## Machine registry",
        "",
        f"JSON: `{OUT_JSON.relative_to(ROOT).as_posix()}`",
        "",
    ]
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")

    reg_md = [
        "# ASSET_REGISTRY.md",
        "",
        f"> Auto from `scripts/audit_visual_assets.py` · {registry['generated_at']}",
        "",
        f"Total media files under `client/assets`: **{len(assets)}**",
        "",
        "See `client/data/visual/asset_registry.json` for full machine-readable catalog.",
        "",
        "## AssetPaths constants",
        "",
        "| Const | Path | Exists |",
        "|---|---|---|",
    ]
    for c in constants:
        reg_md.append(f"| `{c['id']}` | `{c['path']}` | {'yes' if c['exists'] else 'NO'} |")
    OUT_REG_MD.write_text("\n".join(reg_md) + "\n", encoding="utf-8")

    print("OK visual audit")
    print(f"  assets={len(assets)} scenes={len(scenes)} broken={len(broken)}")
    if broken:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
