extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_MAP)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_display_label("Карта республики", 40))
	vbox.add_child(DesignTokens.make_label(
		"Уфа — CH01. Стерлитамак и далее — CH02+ (закрыто до завершения первой главы).",
		22,
		DesignTokens.COLOR_TEXT_MUTED
	))
	vbox.add_child(DesignTokens.make_label(GameState.currency_line(), 20, DesignTokens.COLOR_ACCENT_CYAN))

	if ResourceLoader.exists(AssetPaths.MAP_UFA):
		var map_art := TextureRect.new()
		map_art.texture = AssetPaths.tex(AssetPaths.MAP_UFA)
		map_art.custom_minimum_size = Vector2(0, 360)
		map_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		map_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		map_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(map_art)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)

	for city in GameState.cities:
		list.add_child(_city_row(city))

	var enter := DesignTokens.make_button("Войти в Уфу · L01", true)
	enter.pressed.connect(_enter_ufa_l01)
	vbox.add_child(enter)

	var camp := DesignTokens.make_button("Кампания Уфы (CH01)", false)
	camp.pressed.connect(func() -> void: SceneNav.to_campaign(get_tree()))
	vbox.add_child(camp)

	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(pad)
	HubChrome.attach(self, get_tree(), "map")


func _enter_ufa_l01() -> void:
	# Vertical slice entry: ensure CH01-Q01 is active then open L01.
	if GameState.active_quest_id == "" and not GameState.is_quest_completed("CH01-Q01"):
		GameState.start_quest("CH01-Q01")
	elif GameState.active_quest_id == "" and GameState.is_quest_available("CH01-Q01"):
		GameState.start_quest("CH01-Q01")
	SceneNav.to_location(get_tree())


func _city_row(city: Dictionary) -> PanelContainer:
	var unlocked := bool(city.get("unlocked", false))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 16))
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := "%s · %s" % [str(city.get("name", "")), str(city.get("region", ""))]
	box.add_child(DesignTokens.make_label(title, 28, DesignTokens.COLOR_ACCENT_GOLD if unlocked else DesignTokens.COLOR_TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(DesignTokens.make_label(
		str(city.get("hint", "")),
		20,
		DesignTokens.COLOR_SUCCESS_MINT if unlocked else DesignTokens.COLOR_TEXT_MUTED,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	var gate := "Открыт" if unlocked else "НЕДОСТУПНО · CH02+"
	if str(city.get("id", "")) == "UFA":
		gate = "Открыт · CH01"
	box.add_child(DesignTokens.make_label(gate, 20, DesignTokens.COLOR_TEXT_IVORY, HORIZONTAL_ALIGNMENT_LEFT))
	return panel
