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
	vbox.add_child(DesignTokens.make_label(GameState.currency_line(), 22, DesignTokens.COLOR_ACCENT_CYAN))

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
	hero.custom_minimum_size = Vector2(0, 520)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_box.add_child(hero)
	stage_box.add_child(DesignTokens.make_label("H01 · Каэрон", 30, DesignTokens.COLOR_TEXT_IVORY))

	vbox.add_child(DesignTokens.make_label(GameState.chapter_progress_text(), 22, DesignTokens.COLOR_TEXT_MUTED))

	var campaign := DesignTokens.make_button("В кампанию CH01", true)
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


func _set_background(path: String) -> void:
	var bg := TextureRect.new()
	bg.texture = AssetPaths.tex(path)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)
