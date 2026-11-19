# VISUAL_AUDIT.md — BashLegends Visual Overhaul 001

> Generated: 2026-11-19T14:41:06.210947+00:00
> Assets: **546** · Scenes: **23** · Broken AssetPaths: **0**

## Summary counts

- By extension: `{'.jpg': 485, '.png': 48, '.ttf': 3, '.ogg': 10}`
- By status heuristic: `{'PRESENT': 347, 'TEMP': 196, 'FINAL_FONT_OFL': 3}`

## Screens (23)

| ID | Scene | Script | Visual status | Notes |
|---|---|---|---|---|
| AFK | `res://scenes/afk/afk.tscn` | `res://scripts/ui/afk_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| ARENA | `res://scenes/arena/arena.tscn` | `res://scripts/ui/arena_screen.gd` | LOCKED_STUB | D-SCOPE-01 locked / unavailable UI. |
| BATTLE | `res://scenes/battle/battle.tscn` | `res://scripts/ui/battle.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| BESTIARY | `res://scenes/bestiary/bestiary.tscn` | `res://scripts/ui/bestiary_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| SPLASH | `res://scenes/boot/splash.tscn` | `res://scripts/ui/splash.gd` | POLISHED_TEMP | Splash uses branding + OFL fonts; art still TEMP. |
| CAMPAIGN | `res://scenes/campaign/campaign.tscn` | `res://scripts/ui/campaign.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| CHAT | `res://scenes/chat/chat.tscn` | `res://scripts/ui/chat_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| DIALOG | `res://scenes/dialog/dialog.tscn` | `res://scripts/ui/dialog_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| EVENTS | `res://scenes/events/events.tscn` | `res://scripts/ui/events_screen.gd` | LOCKED_STUB | D-SCOPE-01 locked / unavailable UI. |
| EXPEDITION | `res://scenes/expedition/expedition.tscn` | `res://scripts/ui/expedition_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| GACHA | `res://scenes/gacha/gacha.tscn` | `res://scripts/ui/gacha_screen.gd` | POLISHED_TEMP | Stage C polish started; dedicated BG/portal where applicable. |
| GUILD | `res://scenes/guild/guild.tscn` | `res://scripts/ui/guild_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| HERO_DETAIL | `res://scenes/heroes/hero_detail.tscn` | `res://scripts/ui/hero_detail_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| HEROES | `res://scenes/heroes/heroes.tscn` | `res://scripts/ui/heroes_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| HOME | `res://scenes/home/home.tscn` | `res://scripts/ui/home.gd` | POLISHED_TEMP | Stage C polish started; dedicated BG/portal where applicable. |
| INVENTORY | `res://scenes/inventory/inventory.tscn` | `res://scripts/ui/inventory_screen.gd` | POLISHED_TEMP | Stage C polish started; dedicated BG/portal where applicable. |
| L01 | `res://scenes/location/l01.tscn` | `res://scripts/ui/l01.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| MAP | `res://scenes/map/map.tscn` | `res://scripts/ui/map_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| MORE | `res://scenes/more/more.tscn` | `res://scripts/ui/more_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| PARTY | `res://scenes/party/party.tscn` | `res://scripts/ui/party_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| POI | `res://scenes/poi/poi.tscn` | `res://scripts/ui/poi_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| SHOP | `res://scenes/shop/shop.tscn` | `res://scripts/ui/shop_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |
| VIP | `res://scenes/vip/vip.tscn` | `res://scripts/ui/vip_screen.gd` | TEMP | Code-built UI; art mostly TEMP branding. |

## Known gaps

| ID | Status | Note |
|---|---|---|
| FONTS_RUNTIME | DONE_THIS_PR | Manrope+Cinzel OFL wired |
| MAPS_FOLDER | MISSING | client/assets/maps empty; map uses BG_MAP |
| DIALOG_H13_H36 | MISSING | dialog portraits only H01–H12 + NPC |
| THEME_TRES | MISSING | No Godot Theme .tres; DesignTokens helpers only |
| GACHA_RESULT_VFX | TEMP | Text results only; portal art added |
| STAGE_E_ATLASES | BLOCKED | D-ART-06 / T-131 |

## Broken AssetPaths constants

- None.

## Machine registry

JSON: `client/data/visual/asset_registry.json`
