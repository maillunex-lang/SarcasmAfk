extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_SHOP)

	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.48)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_theme_constant_override("separation", 14)

	vbox.add_child(_build_header())
	vbox.add_child(_build_banner())
	vbox.add_child(DesignTokens.make_label(
		"TEST_PURCHASE · цены-заглушки · не реальная выручка",
		16,
		DesignTokens.COLOR_DANGER_CORAL
	))
	vbox.add_child(_build_wallet_row())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

	var res: Dictionary = GameState.api.shop_catalog()
	var skus: Array = res.get("skus", [])
	for sku in skus:
		if typeof(sku) != TYPE_DICTIONARY:
			continue
		list.add_child(_sku_card(sku))

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	vbox.add_child(footer)
	var vip := DesignTokens.make_button("VIP", false)
	vip.pressed.connect(func() -> void: SceneNav.to_vip(get_tree()))
	footer.add_child(vip)
	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	footer.add_child(back)


func _build_header() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var icon := TextureRect.new()
	icon.texture = AssetPaths.tex(AssetPaths.ICON_SHOP)
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(titles)
	titles.add_child(DesignTokens.make_display_label("Донат-магазин", 36))
	titles.add_child(DesignTokens.make_label("Алмазы · наборы · VIP · косметика", 18, DesignTokens.COLOR_TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	return row


func _build_banner() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_DEEP, 0.35), 18)
	)
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel")
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	var banner := TextureRect.new()
	banner.texture = AssetPaths.tex(AssetPaths.SHOP_BANNER)
	banner.custom_minimum_size = Vector2(0, 220)
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(banner)
	return panel


func _build_wallet_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for pair in [
		[AssetPaths.ICON_SOFT, str(GameState.soft_currency)],
		[AssetPaths.ICON_HARD, str(GameState.hard_currency)],
		[AssetPaths.ICON_TICKET, str(GameState.summon_tickets)],
		[AssetPaths.ICON_VIP, "VIP %d" % GameState.vip_level],
	]:
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override(
			"panel",
			DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_DEEP, 0.88), 12)
		)
		var s: StyleBoxFlat = chip.get_theme_stylebox("panel")
		s.content_margin_left = 10
		s.content_margin_right = 12
		s.content_margin_top = 8
		s.content_margin_bottom = 8
		var inner := HBoxContainer.new()
		inner.add_theme_constant_override("separation", 6)
		chip.add_child(inner)
		var ic := TextureRect.new()
		ic.texture = AssetPaths.tex(str(pair[0]))
		ic.custom_minimum_size = Vector2(32, 32)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		inner.add_child(ic)
		inner.add_child(DesignTokens.make_label(str(pair[1]), 18, DesignTokens.COLOR_ACCENT_CYAN))
		row.add_child(chip)
	return row


func _sku_card(sku: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_DEEP, 0.9), 16)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var icon := TextureRect.new()
	icon.texture = AssetPaths.tex(AssetPaths.shop_icon_for_category(str(sku.get("category", ""))))
	icon.custom_minimum_size = Vector2(112, 112)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	row.add_child(body)
	body.add_child(DesignTokens.make_label(
		str(sku.get("title", sku.get("sku", ""))),
		24,
		DesignTokens.COLOR_TEXT_IVORY,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	var price := str(sku.get("price_display", "0 ₽"))
	var label := str(sku.get("price_label", "Тестовый режим"))
	body.add_child(DesignTokens.make_label(
		"%s · %s" % [price, label],
		18,
		DesignTokens.COLOR_ACCENT_GOLD,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	body.add_child(DesignTokens.make_label(
		_grants_hint(sku),
		15,
		DesignTokens.COLOR_TEXT_MUTED,
		HORIZONTAL_ALIGNMENT_LEFT
	))

	var buy := DesignTokens.make_button("Купить", true)
	buy.custom_minimum_size = Vector2(180, 88)
	buy.size_flags_horizontal = Control.SIZE_SHRINK_END
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var id := str(sku.get("sku", ""))
	buy.pressed.connect(func() -> void: _purchase(id))
	row.add_child(buy)
	return panel


func _grants_hint(sku: Dictionary) -> String:
	var g = sku.get("grants", {})
	if typeof(g) != TYPE_DICTIONARY:
		return str(sku.get("category", ""))
	var parts: PackedStringArray = []
	if int(g.get("hard", 0)) > 0:
		parts.append("Алмазы %d" % int(g.get("hard", 0)))
	if int(g.get("soft", 0)) > 0:
		parts.append("Золото %d" % int(g.get("soft", 0)))
	if int(g.get("tickets", 0)) > 0:
		parts.append("Билеты %d" % int(g.get("tickets", 0)))
	if int(g.get("vip_points", 0)) > 0:
		parts.append("VIP +%d" % int(g.get("vip_points", 0)))
	if parts.is_empty():
		return str(sku.get("category", ""))
	return " · ".join(parts)


func _purchase(id: String) -> void:
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
