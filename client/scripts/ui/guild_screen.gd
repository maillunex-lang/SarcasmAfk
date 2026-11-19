extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_GUILD)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("Гильдия", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("Клиентская заглушка до сервера", 22, DesignTokens.COLOR_TEXT_MUTED))
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 20))
	vbox.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(DesignTokens.make_label("«Очередь №13»", 34, DesignTokens.COLOR_ACCENT_CYAN))
	box.add_child(DesignTokens.make_label("Роль: Рекрут (мок)", 24, DesignTokens.COLOR_TEXT_IVORY))
	box.add_child(DesignTokens.make_label("Участники: 1/30 · Территория: не назначена", 22, DesignTokens.COLOR_TEXT_MUTED))
	box.add_child(DesignTokens.make_label("Совместные рейды и базы — после Phase 2.", 22, DesignTokens.COLOR_TEXT_MUTED))
	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	vbox.add_child(back)
