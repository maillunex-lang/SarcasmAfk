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
	vbox.add_child(DesignTokens.make_label("VIP", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("Draft уровни — без финальной монетизации", 18, DesignTokens.COLOR_DANGER_CORAL))

	var res: Dictionary = GameState.api.vip_status()
	vbox.add_child(DesignTokens.make_label(
		"Уровень %d · Очки %d" % [int(res.get("vip_level", GameState.vip_level)), int(res.get("vip_points", GameState.vip_points))],
		24,
		DesignTokens.COLOR_TEXT_IVORY
	))
	vbox.add_child(DesignTokens.make_label(
		"Lunex: %s" % str(res.get("lunex_visual_id", "lunex://vip/0")),
		16,
		DesignTokens.COLOR_ACCENT_CYAN
	))

	var data := {}
	var f := FileAccess.open("res://data/vip/vip_draft.json", FileAccess.READ)
	if f:
		data = JSON.parse_string(f.get_as_text())
		f.close()
	var levels: Array = []
	if typeof(data) == TYPE_DICTIONARY:
		levels = data.get("levels", [])
	for lv in levels:
		if typeof(lv) != TYPE_DICTIONARY:
			continue
		vbox.add_child(DesignTokens.make_label(
			"VIP%d · %d очков · daily soft %d · AFK +%d%%" % [
				int(lv.get("level", 0)),
				int(lv.get("points_required", 0)),
				int(lv.get("daily_soft", 0)),
				int(lv.get("afk_bonus_pct", 0)),
			],
			18,
			DesignTokens.COLOR_TEXT_MUTED
		))
	vbox.add_child(DesignTokens.make_label(
		"VIP не даёт безлимитного преимущества в PvP.",
		18,
		DesignTokens.COLOR_TEXT_MUTED
	))
	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_shop(get_tree()))
	vbox.add_child(back)
