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
		"TEST_PURCHASE · цены-заглушки · не реальная выручка",
		18,
		DesignTokens.COLOR_DANGER_CORAL
	))
	vbox.add_child(DesignTokens.make_label(
		"Золото %d · Алмазы %d · Билеты %d · VIP очки %d" % [
			GameState.soft_currency, GameState.hard_currency, GameState.summon_tickets, GameState.vip_points
		],
		18,
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
	box.add_child(DesignTokens.make_label(str(sku.get("title", sku.get("sku", ""))), 22, DesignTokens.COLOR_TEXT_IVORY))
	var price := str(sku.get("price_display", "0 ₽"))
	var label := str(sku.get("price_label", "Тестовый режим"))
	box.add_child(DesignTokens.make_label("%s · %s" % [price, label], 16, DesignTokens.COLOR_ACCENT_GOLD))
	box.add_child(DesignTokens.make_label(str(sku.get("category", "")), 14, DesignTokens.COLOR_TEXT_MUTED))
	var buy := DesignTokens.make_button("Тестовая покупка", true)
	var id := str(sku.get("sku", ""))
	buy.pressed.connect(func() -> void:
		var r: Dictionary = GameState.api.shop_purchase(id)
		if not bool(r.get("ok", false)):
			return
		if str(r.get("transaction_type", "")) != "TEST_PURCHASE" and not bool(r.get("mock", false)):
			return
		var granted: Dictionary = r.get("granted", {})
		if typeof(granted) == TYPE_DICTIONARY:
			GameState.soft_currency += int(granted.get("soft", r.get("granted_soft", 0)))
			GameState.hard_currency += int(granted.get("hard", 0))
			GameState.summon_tickets += int(granted.get("tickets", r.get("granted_tickets", 0)))
			GameState.vip_points += int(granted.get("vip_points", 0))
		elif int(r.get("granted_soft", 0)) > 0:
			GameState.soft_currency += int(r.get("granted_soft", 0))
		var prog = r.get("progress", {})
		if typeof(prog) == TYPE_DICTIONARY and not prog.is_empty():
			GameState.soft_currency = int(prog.get("soft_currency", GameState.soft_currency))
			GameState.hard_currency = int(prog.get("hard_currency", GameState.hard_currency))
			GameState.summon_tickets = int(prog.get("summon_tickets", GameState.summon_tickets))
			GameState.vip_points = int(prog.get("vip_points", GameState.vip_points))
			GameState.vip_level = int(prog.get("vip_level", GameState.vip_level))
		GameState.save_game()
		GameState.progress_changed.emit()
		SceneNav.to_shop(get_tree())
	)
	box.add_child(buy)
	return panel
