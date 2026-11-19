extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_VIP)

	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_theme_constant_override("separation", 14)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	vbox.add_child(header)
	var badge := TextureRect.new()
	badge.texture = AssetPaths.tex(AssetPaths.VIP_BADGE_GOLD)
	badge.custom_minimum_size = Vector2(96, 96)
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(badge)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	titles.add_child(DesignTokens.make_label("VIP 0–10", 38, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	titles.add_child(DesignTokens.make_label(
		"Предварительный баланс · PvP-бонус мощи ≤5%",
		16,
		DesignTokens.COLOR_DANGER_CORAL,
		HORIZONTAL_ALIGNMENT_LEFT
	))

	var res: Dictionary = GameState.api.vip_status()
	var lvl := int(res.get("vip_level", GameState.vip_level))
	var pts := int(res.get("vip_points", GameState.vip_points))

	var status := PanelContainer.new()
	status.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_DEEP, 0.88), 16)
	)
	vbox.add_child(status)
	var status_box := HBoxContainer.new()
	status_box.add_theme_constant_override("separation", 16)
	status.add_child(status_box)
	var frame := TextureRect.new()
	frame.texture = AssetPaths.tex(AssetPaths.VIP_BADGE_FRAME)
	frame.custom_minimum_size = Vector2(80, 80)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	status_box.add_child(frame)
	var status_text := VBoxContainer.new()
	status_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_box.add_child(status_text)
	status_text.add_child(DesignTokens.make_label(
		"Уровень %d" % lvl,
		28,
		DesignTokens.COLOR_TEXT_IVORY,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	status_text.add_child(DesignTokens.make_label(
		"Очки %d" % pts,
		20,
		DesignTokens.COLOR_ACCENT_CYAN,
		HORIZONTAL_ALIGNMENT_LEFT
	))

	var claim := DesignTokens.make_button("Забрать ежедневную VIP-награду", true)
	claim.pressed.connect(func() -> void:
		var r: Dictionary = GameState.api.vip_claim_daily()
		if bool(r.get("ok", false)) and not bool(r.get("already", false)):
			GameState.soft_currency += int(r.get("granted_soft", 0))
			GameState.summon_tickets += int(r.get("granted_tickets", 0))
			GameState.save_game()
		SceneNav.to_vip(get_tree())
	)
	vbox.add_child(claim)

	var data := {}
	var f := FileAccess.open("res://data/vip/vip_draft.json", FileAccess.READ)
	if f:
		data = JSON.parse_string(f.get_as_text())
		f.close()
	var levels: Array = []
	if typeof(data) == TYPE_DICTIONARY:
		levels = data.get("levels", [])

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	for lv in levels:
		if typeof(lv) != TYPE_DICTIONARY:
			continue
		list.add_child(_level_row(lv, lvl))

	var back := DesignTokens.make_button("Назад в магазин", false)
	back.pressed.connect(func() -> void: SceneNav.to_shop(get_tree()))
	vbox.add_child(back)


func _level_row(lv: Dictionary, current: int) -> PanelContainer:
	var level := int(lv.get("level", 0))
	var active := level == current
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(
			Color(DesignTokens.COLOR_ACCENT_GOLD, 0.18) if active else Color(DesignTokens.COLOR_BG_DEEP, 0.85),
			12
		)
	)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(DesignTokens.make_label(
		"VIP%d · %d очков" % [level, int(lv.get("points_required", 0))],
		20,
		DesignTokens.COLOR_ACCENT_GOLD if active else DesignTokens.COLOR_TEXT_IVORY,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	box.add_child(DesignTokens.make_label(
		"daily soft %d · AFK +%d%% · tickets/day %d" % [
			int(lv.get("daily_soft", 0)),
			int(lv.get("afk_bonus_pct", 0)),
			int(lv.get("summon_ticket_daily", 0)),
		],
		15,
		DesignTokens.COLOR_TEXT_MUTED,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	return panel
