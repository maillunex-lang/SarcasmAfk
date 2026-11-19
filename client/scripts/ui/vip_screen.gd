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
	vbox.add_child(DesignTokens.make_label("VIP 0–10", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label(
		"Предварительный баланс · PvP-бонус мощи ≤5% · редактируется в админке",
		16,
		DesignTokens.COLOR_DANGER_CORAL
	))

	var res: Dictionary = GameState.api.vip_status()
	var lvl := int(res.get("vip_level", GameState.vip_level))
	var pts := int(res.get("vip_points", GameState.vip_points))
	vbox.add_child(DesignTokens.make_label("Уровень %d · Очки %d" % [lvl, pts], 24, DesignTokens.COLOR_TEXT_IVORY))

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
	scroll.add_child(list)
	for lv in levels:
		if typeof(lv) != TYPE_DICTIONARY:
			continue
		list.add_child(DesignTokens.make_label(
			"VIP%d · %d очков · daily soft %d · AFK +%d%% · tickets/day %d" % [
				int(lv.get("level", 0)),
				int(lv.get("points_required", 0)),
				int(lv.get("daily_soft", 0)),
				int(lv.get("afk_bonus_pct", 0)),
				int(lv.get("summon_ticket_daily", 0)),
			],
			16,
			DesignTokens.COLOR_TEXT_MUTED
		))
	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_shop(get_tree()))
	vbox.add_child(back)
