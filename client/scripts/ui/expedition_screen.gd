extends "res://scripts/ui/screen_base.gd"

var _status: Label


func _ready() -> void:
	super._ready()
	var vbox := _make_root_vbox(DesignTokens.COLOR_BG_NAVY)
	vbox.add_child(DesignTokens.make_label("Экспедиции", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("Таймеры на моках · AFK-002 C", 22, DesignTokens.COLOR_TEXT_MUTED))
	_status = DesignTokens.make_label(_status_text(), 24, DesignTokens.COLOR_ACCENT_CYAN)
	vbox.add_child(_status)

	for e in GameState.expeditions:
		vbox.add_child(_row(e))

	var claim := DesignTokens.make_button("Забрать экспедицию", true)
	claim.pressed.connect(_on_claim)
	vbox.add_child(claim)

	var back := DesignTokens.make_button("К AFK", false)
	back.pressed.connect(func() -> void: SceneNav.to_afk(get_tree()))
	vbox.add_child(back)


func _status_text() -> String:
	if GameState.active_expedition_id == "":
		return "Нет активной экспедиции"
	var left := maxi(0, GameState.expedition_ends_unix - int(Time.get_unix_time_from_system()))
	return "Активно: %s · осталось %d с" % [GameState.active_expedition_id, left]


func _row(e: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 16))
	var box := HBoxContainer.new()
	panel.add_child(box)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(text)
	text.add_child(DesignTokens.make_label(str(e.get("name", "")), 26, DesignTokens.COLOR_TEXT_IVORY, HORIZONTAL_ALIGNMENT_LEFT))
	text.add_child(DesignTokens.make_label(
		"%s · %ds · +%d soft / +%d XP" % [str(e.get("id", "")), int(e.get("duration_sec", 0)), int(e.get("soft", 0)), int(e.get("xp", 0))],
		18,
		DesignTokens.COLOR_TEXT_MUTED,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	var btn := DesignTokens.make_button("Старт", false)
	btn.custom_minimum_size = Vector2(180, 80)
	var eid := str(e.get("id", ""))
	btn.pressed.connect(func() -> void:
		if GameState.start_expedition(eid):
			_status.text = _status_text()
	)
	box.add_child(btn)
	return panel


func _on_claim() -> void:
	var res := GameState.claim_expedition()
	if bool(res.get("ok", false)):
		_status.text = "Готово: +%d soft / +%d XP" % [int(res.get("soft", 0)), int(res.get("xp", 0))]
	else:
		_status.text = _status_text()
