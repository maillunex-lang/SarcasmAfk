# ASSET_GENERATION_PROMPTS.md

Production prompts for Visual Overhaul 001. Generated assets marked DONE; others PENDING / GENERATION_BLOCKED.

## DONE this PR

### VO-BG-INVENTORY
```
Premium mobile RPG vertical 9:16 fantasy background for inventory and arsenal screen,
deep navy blue night atmosphere with soft gold ornamental frame hints, magical cyan light
particles, stylized clean anime fantasy, no characters no text no logos no UI buttons
```
→ `client/assets/branding/bg_inventory.jpg` (TEMP)

### VO-GACHA-PORTAL
```
Premium mobile RPG gacha summon portal illustration, vertical 9:16, ornate magical cyan-gold
portal circle on deep navy night sky, floating parchment tickets and soft particles,
clean stylized anime fantasy, no text no logos no watermarks
```
→ `client/assets/branding/gacha_portal.jpg` (TEMP)

### VO-UI-EMPTY
```
Mobile RPG empty state illustration icon square, ornate empty treasure chest silhouette
in navy and gold with soft cyan glow, clean stylized fantasy, no text no logos
```
→ `client/assets/ui/panels/ui_empty_state.jpg` (TEMP)

### VO-BG-PARTY / BESTIARY / DIALOG
Done TEMP → `bg_party.jpg`, `bg_bestiary.jpg`, `bg_dialog.jpg`.

### VO-ICON-GUILD / VO-MAP-UFA / VO-GACHA-RESULT
Done TEMP → `guild_icon_{crest,vault,board}.jpg`, `map_ufa_campaign.jpg`, `gacha_frame_*.png`.

## DONE Stage F

| ID | Output |
|----|--------|
| VO-DIALOG-H13+ | `client/assets/dialogs/dialog_portrait_H13…H36.jpg` via `scripts/generate_dialog_busts_h13_h36.py` (TEMP stamp) |
| VO-THEME-TRES | `client/themes/bashlegends_theme.tres` |
| VO-GALLERY | `docs/reports/visual_gallery/` via `scripts/generate_visual_gallery.py` |

## PENDING (later)

| ID | Need | Prompt gist |
|----|------|-------------|
| VO-VIP-CHAT-DEPTH | Deeper VIP/chat chrome | optional polish after device accept |

## BLOCKED

| ID | Reason |
|----|--------|
| Stage E H01 atlases | D-ART-06 / T-131 owner grip |
| Final enemy Blender atlases | D-ART-06 |
| Real payment art | D-SHOP-01 / T-153 |
