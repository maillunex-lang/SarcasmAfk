# VISUAL OVERHAUL 001 — BashLegends

> Started: 2026-11-19 · Branch: `cursor/visual-overhaul-001-beaf` · Base: `main` @ `71035ef`

## Goal

Bring all screens to a coherent **Premium Clean Stylized Anime Fantasy 2.5D + Premium Fantasy Mobile UI** look without violating D-ART / D-SCOPE locks.

## Stage status

| Stage | Status | Notes |
|-------|--------|-------|
| A Audit | DONE (this PR) | 23 scenes inventoried; registry JSON+MD |
| B Design system | IN PROGRESS | OFL fonts + expanded DesignTokens |
| C Core path | IN PROGRESS | Splash/Home/Dialog/Battle + Gacha/Inventory |
| D RPG screens | IN PROGRESS | Heroes/party/bestiary + map_ufa art |
| E Online systems | IN PROGRESS | Guild crest/vault/board; shop display title |
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
- New art: `bg_inventory.jpg`, `gacha_portal.jpg`, `ui_empty_state.jpg`, `bg_party.jpg`, `bg_bestiary.jpg`, `bg_dialog.jpg`
- Splash fade-in; Home display type; Gacha portal; Inventory BG
- Party/Bestiary/Dialog TEMP BGs; Heroes rarity frames; Battle victory display chrome
- Map Ufa campaign art; guild crest/vault/board icons; TEMP gacha rarity frames
- `smoke_visual_screens.gd` headless screen/asset gate in `ci_validate.sh`

## Next PR

Stage D/E deepen: map marker polish, Theme.tres, dialog busts H13–H36, guild/shop icons, before/after gallery + APK.
