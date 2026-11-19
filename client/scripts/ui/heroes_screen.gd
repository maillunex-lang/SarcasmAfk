extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_HEROES)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("Коллекция героев", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("12 героев MVP · 4 класса · 6 редкостей", 22, DesignTokens.COLOR_TEXT_MUTED))

	var party_btn := DesignTokens.make_button("Собрать отряд (5)", true)
	party_btn.pressed.connect(func() -> void: SceneNav.to_party(get_tree()))
	vbox.add_child(party_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	for h in GameState.heroes_catalog:
		grid.add_child(_hero_card(h))

	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(pad)
	HubChrome.attach(self, get_tree(), "heroes")


func _hero_card(h: Dictionary) -> PanelContainer:
	var id := str(h.get("id", ""))
	var owned := bool(GameState.owned_heroes.get(id, false))
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 360)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 16))
	var box := VBoxContainer.new()
	panel.add_child(box)
	var tex := TextureRect.new()
	tex.texture = AssetPaths.tex(str(h.get("portrait", "")))
	tex.custom_minimum_size = Vector2(0, 180)
	tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not owned:
		tex.modulate = Color(0.5, 0.5, 0.5, 0.7)
	box.add_child(tex)
	box.add_child(DesignTokens.make_label("%s · %s" % [id, str(h.get("name", ""))], 24, DesignTokens.COLOR_TEXT_IVORY))
	box.add_child(DesignTokens.make_label(
		"%s · %s · %s" % [str(h.get("class", "")), str(h.get("rarity", "")), str(h.get("faction", ""))],
		18,
		DesignTokens.COLOR_TEXT_MUTED
	))
	var lvl := int(GameState.hero_levels.get(id, 0))
	box.add_child(DesignTokens.make_label(
		("Ур. %d" % lvl) if owned else "Не получен",
		20,
		DesignTokens.COLOR_ACCENT_CYAN if owned else DesignTokens.COLOR_DANGER_CORAL
	))
	if owned:
		var up := DesignTokens.make_button("Уровень +", false)
		up.custom_minimum_size = Vector2(0, 72)
		up.pressed.connect(func() -> void:
			if GameState.level_up_hero(id):
				SceneNav.to_heroes(get_tree())
		)
		box.add_child(up)
	return panel
