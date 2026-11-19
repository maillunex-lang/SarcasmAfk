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
	vbox.add_theme_constant_override("separation", 16)

	vbox.add_child(DesignTokens.make_label(DesignTokens.DISPLAY_NAME, 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label(DesignTokens.SLOGAN, 22, DesignTokens.COLOR_TEXT_MUTED))
	var cur_row := HBoxContainer.new()
	cur_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cur_row.add_theme_constant_override("separation", 12)
	vbox.add_child(cur_row)
	for pair in [
		[AssetPaths.ICON_SOFT, str(GameState.soft_currency)],
		[AssetPaths.ICON_HARD, str(GameState.hard_currency)],
		[AssetPaths.ICON_TICKET, str(GameState.summon_tickets)],
	]:
		var ic := TextureRect.new()
		ic.texture = AssetPaths.tex(str(pair[0]))
		ic.custom_minimum_size = Vector2(48, 48)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cur_row.add_child(ic)
		cur_row.add_child(DesignTokens.make_label(str(pair[1]), 22, DesignTokens.COLOR_ACCENT_CYAN))

	var stage := PanelContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_DEEP, 0.82), 24))
	vbox.add_child(stage)
	var stage_box := VBoxContainer.new()
	stage_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stage.add_child(stage_box)
	var hero := TextureRect.new()
	hero.texture = AssetPaths.tex(AssetPaths.hero_full("H01"))
	hero.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.custom_minimum_size = Vector2(0, 520)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_box.add_child(hero)
	stage_box.add_child(DesignTokens.make_label("H01 · Каэрон", 30, DesignTokens.COLOR_TEXT_IVORY))

	vbox.add_child(DesignTokens.make_label(GameState.chapter_progress_text(), 22, DesignTokens.COLOR_TEXT_MUTED))

	var mid := GameState.mid_quest_continue()
	if not mid.is_empty():
		var cont := DesignTokens.make_button(str(mid.get("label", "Продолжить")), true)
		var dest := str(mid.get("dest", "location"))
		cont.pressed.connect(func() -> void: _continue_mid_quest(dest))
		vbox.add_child(cont)
		vbox.add_child(DesignTokens.make_label(str(mid.get("hint", "")), 20, DesignTokens.COLOR_TEXT_MUTED))

	var map_btn := DesignTokens.make_button("Карта Уфы", mid.is_empty())
	map_btn.pressed.connect(func() -> void: SceneNav.to_map(get_tree()))
	vbox.add_child(map_btn)

	var campaign := DesignTokens.make_button("Кампания CH01", false)
	campaign.pressed.connect(func() -> void: SceneNav.to_campaign(get_tree()))
	vbox.add_child(campaign)

	var afk := DesignTokens.make_button("AFK-награды", false)
	afk.pressed.connect(func() -> void: SceneNav.to_afk(get_tree()))
	vbox.add_child(afk)

	# Space for hub nav
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(pad)

	HubChrome.attach(self, get_tree(), "home")


func _continue_mid_quest(dest: String) -> void:
	match dest:
		"dialog":
			SceneNav.to_dialog(get_tree())
		"party":
			SceneNav.to_party(get_tree())
		"battle":
			SceneNav.to_battle(get_tree())
		"location":
			SceneNav.to_location(get_tree())
		_:
			SceneNav.to_map(get_tree())


func _set_background(path: String) -> void:
	var bg := TextureRect.new()
	bg.texture = AssetPaths.tex(path)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)
