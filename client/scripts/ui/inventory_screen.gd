extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_HEROES)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("Инвентарь / экипировка", 36, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("Материалы и слоты оружия / брони / аксессуара", 20, DesignTokens.COLOR_TEXT_MUTED))

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
		ic.custom_minimum_size = Vector2(40, 40)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cur_row.add_child(ic)
		cur_row.add_child(DesignTokens.make_label(str(pair[1]), 22, DesignTokens.COLOR_ACCENT_CYAN))

	vbox.add_child(DesignTokens.make_label("Материалы", 28, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	if GameState.inventory.is_empty():
		vbox.add_child(DesignTokens.make_label(
			"Пока пусто — материалы появятся с наград и AFK",
			20,
			DesignTokens.COLOR_TEXT_MUTED,
			HORIZONTAL_ALIGNMENT_LEFT
		))
	else:
		for k in GameState.inventory.keys():
			vbox.add_child(DesignTokens.make_label(
				"%s × %s" % [str(k), str(GameState.inventory[k])],
				22,
				DesignTokens.COLOR_TEXT_IVORY,
				HORIZONTAL_ALIGNMENT_LEFT
			))

	vbox.add_child(DesignTokens.make_label("Экипировка отряда", 28, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	var any_party := false
	for id in GameState.party_ids:
		if str(id) == "":
			continue
		any_party = true
		list.add_child(_equip_row(str(id)))
	if not any_party:
		list.add_child(DesignTokens.make_label("Отряд пуст — соберите 5 героев", 20, DesignTokens.COLOR_TEXT_MUTED))

	var party_btn := DesignTokens.make_button("К отряду", false)
	party_btn.pressed.connect(func() -> void: SceneNav.to_party(get_tree()))
	vbox.add_child(party_btn)
	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	vbox.add_child(back)


func _equip_row(hero_id: String) -> PanelContainer:
	var h := GameState.get_hero(hero_id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 12))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(96, 96)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture = AssetPaths.tex(AssetPaths.hero_portrait(hero_id))
	row.add_child(portrait)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(box)
	box.add_child(DesignTokens.make_label(
		"%s · %s" % [hero_id, str(h.get("name", ""))],
		24,
		DesignTokens.COLOR_TEXT_IVORY,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	var eq: Dictionary = GameState.equipment.get(hero_id, {"weapon": "", "armor": "", "accessory": ""})
	var w := str(eq.get("weapon", ""))
	var a := str(eq.get("armor", ""))
	var c := str(eq.get("accessory", ""))
	box.add_child(DesignTokens.make_label(
		"Оружие: %s" % (w if w != "" else "—"),
		18,
		DesignTokens.COLOR_TEXT_MUTED,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	box.add_child(DesignTokens.make_label(
		"Броня: %s · Аксессуар: %s" % [a if a != "" else "—", c if c != "" else "—"],
		18,
		DesignTokens.COLOR_TEXT_MUTED,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	var btn := DesignTokens.make_button("Надеть стартовый сет", false)
	btn.custom_minimum_size = Vector2(0, 72)
	btn.pressed.connect(func() -> void:
		GameState.equip_item(hero_id, "weapon", "starter_blade")
		GameState.equip_item(hero_id, "armor", "starter_mail")
		GameState.equip_item(hero_id, "accessory", "starter_charm")
		SceneNav.to_inventory(get_tree())
	)
	box.add_child(btn)
	return panel
