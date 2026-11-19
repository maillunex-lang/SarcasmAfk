extends "res://scripts/ui/screen_base.gd"

var hero_id: String = ""


func _ready() -> void:
	super._ready()
	hero_id = str(GameState.get_meta("hero_detail_id", "H01"))
	_set_bg_texture(AssetPaths.BG_HEROES)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	var h := GameState.get_hero(hero_id)
	var owned := bool(GameState.owned_heroes.get(hero_id, false))
	var status := str(h.get("status", "approved_mvp"))
	vbox.add_child(DesignTokens.make_label(str(h.get("name", hero_id)), 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label(
		"%s · %s · %s · %s" % [hero_id, str(h.get("class", "")), str(h.get("rarity", "")), str(h.get("faction", ""))],
		20,
		DesignTokens.COLOR_TEXT_MUTED
	))
	if status == "draft":
		vbox.add_child(DesignTokens.make_label("DRAFT — имена/баланс на утверждении", 18, DesignTokens.COLOR_DANGER_CORAL))
	var art := str(h.get("art_status", ""))
	if art == "TEMP_PLACEHOLDER" or art.begins_with("pipeline"):
		vbox.add_child(DesignTokens.make_label("Арт: %s (не финальный)" % art, 16, DesignTokens.COLOR_TEXT_MUTED))
	vbox.add_child(DesignTokens.make_label("Lunex: %s" % str(h.get("lunex_visual_id", "")), 16, DesignTokens.COLOR_ACCENT_CYAN))

	var tex := TextureRect.new()
	tex.texture = AssetPaths.tex(str(h.get("portrait", AssetPaths.hero_portrait(hero_id))))
	tex.custom_minimum_size = Vector2(0, 280)
	tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not owned:
		tex.modulate = Color(0.45, 0.45, 0.45, 0.8)
	vbox.add_child(tex)

	var lvl := int(GameState.hero_levels.get(hero_id, 1))
	var stars := int(GameState.hero_stars.get(hero_id, 0))
	var power := int(GameState.hero_power.get(hero_id, 0))
	if power <= 0 and owned:
		GameState._recalc_hero_power(hero_id)
		power = int(GameState.hero_power.get(hero_id, 0))
	vbox.add_child(DesignTokens.make_label(
		"Ур. %d · ★ %d · Мощь %d · Золото %d" % [lvl, stars, power, GameState.soft_currency],
		22,
		DesignTokens.COLOR_TEXT_IVORY
	))
	vbox.add_child(DesignTokens.make_label(
		"HP %s · ATK %s · DEF %s · SPD %s" % [h.get("hp", 0), h.get("atk", 0), h.get("defense", 0), h.get("speed", 0)],
		18,
		DesignTokens.COLOR_TEXT_MUTED
	))
	vbox.add_child(DesignTokens.make_label("ULT: %s" % str(h.get("ultimate_name", "")), 20, DesignTokens.COLOR_ACCENT_GOLD))

	if owned:
		var up := DesignTokens.make_button("Повысить уровень (сервер)", true)
		up.pressed.connect(func() -> void:
			if GameState.level_up_hero(hero_id):
				SceneNav.to_hero_detail(get_tree(), hero_id)
		)
		vbox.add_child(up)
		var star := DesignTokens.make_button("Повысить звёзды", false)
		star.pressed.connect(func() -> void:
			if GameState.star_up_hero(hero_id):
				SceneNav.to_hero_detail(get_tree(), hero_id)
		)
		vbox.add_child(star)

	var back := DesignTokens.make_button("К коллекции", false)
	back.pressed.connect(func() -> void: SceneNav.to_heroes(get_tree()))
	vbox.add_child(back)
