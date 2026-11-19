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
	vbox.add_child(DesignTokens.make_label("RPG-мок: материалы и слоты оружия/брони/аксессуара", 20, DesignTokens.COLOR_TEXT_MUTED))
	vbox.add_child(DesignTokens.make_label(GameState.currency_line(), 20, DesignTokens.COLOR_ACCENT_CYAN))

	vbox.add_child(DesignTokens.make_label("Материалы", 28, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	for k in GameState.inventory.keys():
		vbox.add_child(DesignTokens.make_label("%s × %s" % [str(k), str(GameState.inventory[k])], 22, DesignTokens.COLOR_TEXT_IVORY, HORIZONTAL_ALIGNMENT_LEFT))

	vbox.add_child(DesignTokens.make_label("Экипировка отряда", 28, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for id in GameState.party_ids:
		if str(id) == "":
			continue
		list.add_child(_equip_row(str(id)))

	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	vbox.add_child(back)


func _equip_row(hero_id: String) -> PanelContainer:
	var h := GameState.get_hero(hero_id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 12))
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(DesignTokens.make_label("%s · %s" % [hero_id, str(h.get("name", ""))], 24, DesignTokens.COLOR_TEXT_IVORY, HORIZONTAL_ALIGNMENT_LEFT))
	var eq: Dictionary = GameState.equipment.get(hero_id, {"weapon": "", "armor": "", "accessory": ""})
	box.add_child(DesignTokens.make_label(
		"W:%s A:%s C:%s" % [str(eq.get("weapon", "-")), str(eq.get("armor", "-")), str(eq.get("accessory", "-"))],
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
