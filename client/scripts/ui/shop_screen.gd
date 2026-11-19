extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_GACHA)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("Магазин", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label(
		"Режим: simulated · не реальные платежи",
		20,
		DesignTokens.COLOR_DANGER_CORAL
	))
	vbox.add_child(DesignTokens.make_label(
		"Золото %d · Алмазы %d · Билеты %d" % [GameState.soft_currency, GameState.hard_currency, GameState.summon_tickets],
		20,
		DesignTokens.COLOR_TEXT_MUTED
	))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)

	var res: Dictionary = GameState.api.shop_catalog()
	var skus: Array = res.get("skus", [])
	for sku in skus:
		if typeof(sku) != TYPE_DICTIONARY:
			continue
		if sku.get("enabled", true) == false:
			continue
		if str(sku.get("purchase_mode", "")) == "test_payment":
			continue
		list.add_child(_sku_row(sku))

	var vip := DesignTokens.make_button("VIP", false)
	vip.pressed.connect(func() -> void: SceneNav.to_vip(get_tree()))
	vbox.add_child(vip)
	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	vbox.add_child(back)


func _sku_row(sku: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 14))
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(DesignTokens.make_label(str(sku.get("title", sku.get("sku", ""))), 24, DesignTokens.COLOR_TEXT_IVORY))
	box.add_child(DesignTokens.make_label(
		"%s · %s" % [str(sku.get("category", "")), str(sku.get("purchase_mode", "simulated"))],
		16,
		DesignTokens.COLOR_TEXT_MUTED
	))
	var buy := DesignTokens.make_button("Получить (симуляция)", true)
	var id := str(sku.get("sku", ""))
	buy.pressed.connect(func() -> void:
		var r: Dictionary = GameState.api.shop_purchase(id)
		if bool(r.get("ok", false)):
			if int(r.get("granted_soft", 0)) > 0:
				GameState.soft_currency += int(r.get("granted_soft", 0))
			if int(r.get("granted_tickets", 0)) > 0:
				GameState.summon_tickets += int(r.get("granted_tickets", 0))
			GameState.save_game()
			GameState.progress_changed.emit()
			SceneNav.to_shop(get_tree())
	)
	box.add_child(buy)
	return panel
