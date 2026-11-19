extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	var vbox := _make_root_vbox(DesignTokens.COLOR_BG_NAVY)
	vbox.add_child(DesignTokens.make_label("События", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("Юмор + региональный календарь (мок)", 22, DesignTokens.COLOR_TEXT_MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	for ev in GameState.events:
		list.add_child(_ev_row(ev))
	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	vbox.add_child(back)


func _ev_row(ev: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 16))
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(DesignTokens.make_label(str(ev.get("title", "")), 28, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(DesignTokens.make_label(
		"%s · %s · %s" % [str(ev.get("id", "")), str(ev.get("city", "")), str(ev.get("status", ""))],
		20,
		DesignTokens.COLOR_TEXT_MUTED,
		HORIZONTAL_ALIGNMENT_LEFT
	))
	box.add_child(DesignTokens.make_label("Тон: %s" % str(ev.get("tone", "")), 20, DesignTokens.COLOR_ACCENT_CYAN, HORIZONTAL_ALIGNMENT_LEFT))
	return panel
