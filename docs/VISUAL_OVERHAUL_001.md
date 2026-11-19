# VISUAL OVERHAUL 001 — BashLegends

> Started: 2026-11-19 · Branch: `cursor/visual-overhaul-001-beaf` · Base: `main` @ `71035ef`

## Goal

Bring all screens to a coherent **Premium Clean Stylized Anime Fantasy 2.5D + Premium Fantasy Mobile UI** look without violating D-ART / D-SCOPE locks.

## Stage status

| Stage | Status | Notes |
|-------|--------|-------|
| A Audit | DONE (this PR) | 23 scenes inventoried; registry JSON+MD |
| B Design system | IN PROGRESS | OFL fonts + expanded DesignTokens |
| C Core path | IN PROGRESS | Splash/Home/Gacha/Inventory polish |
| D RPG screens | TODO | Heroes/detail/party/AFK/expedition |
| E Online systems | TODO | Shop/VIP/guild/chat deepen |
| F Polish | TODO | Animations, APK, before/after shots |

## Constraints honored

- No CH02 / Stage E Kaeron atlases / real payments / package ID change.
- TEMP art remains labeled TEMP.
- Arena/events stay locked stubs (D-SCOPE-01).

## Deliverables this PR

- `docs/VISUAL_AUDIT.md`, `docs/ASSET_REGISTRY.md`, `docs/UI_DESIGN_SYSTEM.md`
- `docs/ASSET_GENERATION_PROMPTS.md`, `docs/VISUAL_QA_REPORT.md`
- `client/data/visual/asset_registry.json`
- `scripts/audit_visual_assets.py`
- Fonts Manrope/Cinzel (OFL)
- New art: `bg_inventory.jpg`, `gacha_portal.jpg`, `ui_empty_state.jpg`
- Splash fade-in; Home display type; Gacha portal; Inventory BG

## Next PR

Stage C continuation: battle reward chrome, dialog contrast, map marker polish + more generated icons.
