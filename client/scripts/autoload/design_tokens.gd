class_name DesignTokens
extends RefCounted
## Design tokens from docs/DESIGN_SYSTEM.md / docs/UI_DESIGN_SYSTEM.md.

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

const COLOR_RARITY_N := Color("#8A93A6")
const COLOR_RARITY_R := Color("#4C8DDE")
const COLOR_RARITY_SR := Color("#8B5CF6")
const COLOR_RARITY_SSR := Color("#E8BC68")
const COLOR_RARITY_UR := Color("#F0A0FF")

const SPACE_XS := 8
const SPACE_SM := 16
const SPACE_MD := 24
const SPACE_LG := 32
const SPACE_XL := 48
const RADIUS_BTN := 16
const RADIUS_PANEL := 20
const TOUCH_MIN := 88

const FONT_BODY := "res://assets/fonts/Manrope-Regular.ttf"
const FONT_BOLD := "res://assets/fonts/Manrope-Bold.ttf"
const FONT_DISPLAY := "res://assets/fonts/Cinzel-SemiBold.ttf"

const DISPLAY_NAME := "БашЛегенды: Эпоха Абсурда"
const INTERNAL_ID := "BashLegends"
const SLOGAN := "Сатира, магия и очередь на 800 лет."

static var _font_body: FontFile
static var _font_bold: FontFile
static var _font_display: FontFile


static func font_body() -> Font:
	if _font_body == null and ResourceLoader.exists(FONT_BODY):
		_font_body = load(FONT_BODY) as FontFile
	return _font_body


static func font_bold() -> Font:
	if _font_bold == null and ResourceLoader.exists(FONT_BOLD):
		_font_bold = load(FONT_BOLD) as FontFile
	return _font_bold


static func font_display() -> Font:
	if _font_display == null and ResourceLoader.exists(FONT_DISPLAY):
		_font_display = load(FONT_DISPLAY) as FontFile
	return _font_display


static func rarity_color(rarity: String) -> Color:
	match rarity:
		"N":
			return COLOR_RARITY_N
		"R":
			return COLOR_RARITY_R
		"SR":
			return COLOR_RARITY_SR
		"SSR":
			return COLOR_RARITY_SSR
		"UR", "Mythic":
			return COLOR_RARITY_UR
		_:
			return COLOR_TEXT_MUTED


static func make_panel_style(bg: Color = COLOR_BG_DEEP, radius: float = 20.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(int(radius))
	style.content_margin_left = SPACE_MD
	style.content_margin_right = SPACE_MD
	style.content_margin_top = SPACE_MD
	style.content_margin_bottom = SPACE_MD
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(COLOR_ACCENT_GOLD, 0.2)
	style.shadow_color = Color(0, 0, 0, 0.33)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style


static func _apply_font(control: Control, display: bool = false, bold: bool = false) -> void:
	var f: Font = font_display() if display else (font_bold() if bold else font_body())
	if f != null:
		control.add_theme_font_override("font", f)


static func make_button(text: String, primary: bool = true) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 96)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var normal := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	var disabled := StyleBoxFlat.new()
	if primary:
		normal.bg_color = COLOR_ACCENT_GOLD
		pressed.bg_color = COLOR_ACCENT_GOLD.darkened(0.08)
		disabled.bg_color = Color(COLOR_ACCENT_GOLD, 0.4)
		button.add_theme_color_override("font_color", COLOR_TEXT_ON_GOLD)
		button.add_theme_color_override("font_pressed_color", COLOR_TEXT_ON_GOLD)
		button.add_theme_color_override("font_hover_color", COLOR_TEXT_ON_GOLD)
		button.add_theme_color_override("font_disabled_color", Color(COLOR_TEXT_ON_GOLD, 0.55))
	else:
		normal.bg_color = COLOR_BG_DEEP
		normal.border_color = COLOR_ACCENT_GOLD
		normal.set_border_width_all(2)
		pressed.bg_color = COLOR_BG_ELEVATED
		pressed.border_color = COLOR_ACCENT_GOLD
		pressed.set_border_width_all(2)
		disabled.bg_color = Color(COLOR_BG_DEEP, 0.5)
		disabled.border_color = Color(COLOR_ACCENT_GOLD, 0.35)
		disabled.set_border_width_all(2)
		button.add_theme_color_override("font_color", COLOR_TEXT_IVORY)
		button.add_theme_color_override("font_disabled_color", Color(COLOR_TEXT_IVORY, 0.45))
	normal.set_corner_radius_all(RADIUS_BTN)
	pressed.set_corner_radius_all(RADIUS_BTN)
	disabled.set_corner_radius_all(RADIUS_BTN)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_font_size_override("font_size", 36)
	_apply_font(button, false, true)
	return button


static func make_ghost_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 88)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_color = Color(COLOR_TEXT_IVORY, 0.55)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(RADIUS_BTN)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(COLOR_BG_DEEP, 0.45)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover", pressed)
	button.add_theme_color_override("font_color", COLOR_TEXT_IVORY)
	button.add_theme_font_size_override("font_size", 32)
	_apply_font(button, false, true)
	return button


static func make_label(text: String, size: int = 32, color: Color = COLOR_TEXT_IVORY, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, display: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(label, display, display or size >= 40)
	return label


static func make_display_label(text: String, size: int = 56, color: Color = COLOR_ACCENT_GOLD) -> Label:
	return make_label(text, size, color, HORIZONTAL_ALIGNMENT_CENTER, true)


static func make_currency_chip(icon: Texture2D, value: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", make_panel_style(Color(COLOR_BG_DEEP, 0.92), 12))
	var style: StyleBoxFlat = chip.get_theme_stylebox("panel")
	style.content_margin_left = 10
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	chip.add_child(row)
	if icon != null:
		var ic := TextureRect.new()
		ic.texture = icon
		ic.custom_minimum_size = Vector2(36, 36)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(ic)
	row.add_child(make_label(value, 20, COLOR_ACCENT_CYAN))
	return chip
