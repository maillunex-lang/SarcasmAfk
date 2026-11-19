# UI_DESIGN_SYSTEM.md — Runtime design code

> Source of truth for Godot helpers: `client/scripts/autoload/design_tokens.gd`  
> Spec origin: `docs/DESIGN_SYSTEM.md` (still authoritative for tokens)

## Runtime fonts (OFL)

| Role | File |
|------|------|
| Body | `res://assets/fonts/Manrope-Regular.ttf` |
| Bold / UI title | `res://assets/fonts/Manrope-Bold.ttf` |
| Display | `res://assets/fonts/Cinzel-SemiBold.ttf` |

Applied via `DesignTokens.make_label` / `make_display_label` / `make_button`.

## Color tokens

Unchanged navy/gold/cyan/ivory/coral/mint + rarity colors N→UR in `DesignTokens`.

## Spacing / radius

`SPACE_XS…XL`, `RADIUS_BTN=16`, `RADIUS_PANEL=20`, `TOUCH_MIN=88`.

## Components

- `make_panel_style` — elevated panel + soft shadow
- `make_button` / `make_ghost_button`
- `make_label` / `make_display_label`
- `make_currency_chip`
- `rarity_color(rarity)`

## Theme `.tres`

`client/themes/bashlegends_theme.tres` — wired via `project.godot` `[gui] theme/custom`.  
Helpers in `DesignTokens` remain the primary code-built UI path; Theme covers default Button/Label/Panel/LineEdit.

## City hub (D-UI-CITY-01)

Home = interactive Ufa city (`home.gd`), not a 2×3 dashboard.  
Spec: [`CITY_HUB_001.md`](CITY_HUB_001.md). Bottom nav label: **Город**.
