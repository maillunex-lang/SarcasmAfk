class_name DesignTokens
extends RefCounted
## Design tokens from docs/DESIGN_SYSTEM.md — V0-A helpers (no runtime Node required).

const COLOR_BG_NAVY := Color("#101C35")
const COLOR_BG_DEEP := Color("#1D3154")
const COLOR_BG_ELEVATED := Color("#243A63")
const COLOR_ACCENT_GOLD := Color("#E8BC68")
const COLOR_ACCENT_CYAN := Color("#54D9DA")
const COLOR_TEXT_IVORY := Color("#F5F0E5")
const COLOR_TEXT_MUTED := Color("#B7C0D4")
const COLOR_TEXT_ON_GOLD := Color("#1A1408")
const COLOR_DANGER_CORAL := Color("#E86D70")
const COLOR_SUCCESS_MINT := Color("#6BCB8B")

const DISPLAY_NAME := "БашЛегенды: Эпоха Абсурда"
const INTERNAL_ID := "BashLegends"
const SLOGAN := "Сатира, магия и очередь на 800 лет."


static func make_panel_style(bg: Color = COLOR_BG_DEEP, radius: float = 20.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(int(radius))
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(COLOR_ACCENT_GOLD, 0.2)
	return style


static func make_button(text: String, primary: bool = true) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 96)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var normal := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	if primary:
		normal.bg_color = COLOR_ACCENT_GOLD
		pressed.bg_color = COLOR_ACCENT_GOLD.darkened(0.08)
		button.add_theme_color_override("font_color", COLOR_TEXT_ON_GOLD)
		button.add_theme_color_override("font_pressed_color", COLOR_TEXT_ON_GOLD)
		button.add_theme_color_override("font_hover_color", COLOR_TEXT_ON_GOLD)
	else:
		normal.bg_color = COLOR_BG_DEEP
		normal.border_color = COLOR_ACCENT_GOLD
		normal.set_border_width_all(2)
		pressed.bg_color = COLOR_BG_ELEVATED
		pressed.border_color = COLOR_ACCENT_GOLD
		pressed.set_border_width_all(2)
		button.add_theme_color_override("font_color", COLOR_TEXT_IVORY)
	normal.set_corner_radius_all(16)
	pressed.set_corner_radius_all(16)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_font_size_override("font_size", 36)
	return button


static func make_label(text: String, size: int = 32, color: Color = COLOR_TEXT_IVORY, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label
