extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_set_background(AssetPaths.BG_HOME)

	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var vbox := _make_root_vbox(Color(0, 0, 0, 0))

	var brand := DesignTokens.make_label(DesignTokens.DISPLAY_NAME, 42, DesignTokens.COLOR_ACCENT_GOLD)
	vbox.add_child(brand)
	vbox.add_child(DesignTokens.make_label(DesignTokens.SLOGAN, 24, DesignTokens.COLOR_TEXT_MUTED))

	var resources := DesignTokens.make_label(
		"Soft: %d   ·   XP: %d" % [GameState.soft_currency, GameState.commander_xp],
		26,
		DesignTokens.COLOR_ACCENT_CYAN
	)
	vbox.add_child(resources)

	var stage := PanelContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_DEEP, 0.82), 24))
	vbox.add_child(stage)

	var stage_box := VBoxContainer.new()
	stage_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stage.add_child(stage_box)

	var hero := TextureRect.new()
	hero.texture = AssetPaths.tex(AssetPaths.H01_FULL)
	hero.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.custom_minimum_size = Vector2(0, 640)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_box.add_child(hero)
	stage_box.add_child(DesignTokens.make_label("H01 · Каэрон", 34, DesignTokens.COLOR_TEXT_IVORY))

	var quest_done := GameState.is_quest_done("CH01-Q01")
	var quest_label := DesignTokens.make_label(
		"CH01-Q01: завершён" if quest_done else "CH01-Q01: Талон в неизвестность",
		24,
		DesignTokens.COLOR_SUCCESS_MINT if quest_done else DesignTokens.COLOR_TEXT_MUTED
	)
	vbox.add_child(quest_label)

	var campaign := DesignTokens.make_button("В кампанию" if not quest_done else "В кампанию (повтор)", true)
	campaign.pressed.connect(func() -> void: SceneNav.to_l01(get_tree()))
	vbox.add_child(campaign)

	var afk_row := HBoxContainer.new()
	afk_row.alignment = BoxContainer.ALIGNMENT_CENTER
	afk_row.add_theme_constant_override("separation", 16)
	vbox.add_child(afk_row)
	var afk_icon := TextureRect.new()
	afk_icon.texture = AssetPaths.tex(AssetPaths.ICON_AFK)
	afk_icon.custom_minimum_size = Vector2(88, 88)
	afk_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	afk_icon.stretch_mode = TextureRect.STRETCH_SCALE
	afk_row.add_child(afk_icon)
	var afk := DesignTokens.make_button("AFK (скоро)", false)
	afk.disabled = true
	afk_row.add_child(afk)


func _set_background(path: String) -> void:
	var bg := TextureRect.new()
	bg.texture = AssetPaths.tex(path)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)
