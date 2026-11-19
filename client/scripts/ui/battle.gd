extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	var vbox := _make_root_vbox(DesignTokens.COLOR_BG_NAVY)

	vbox.add_child(DesignTokens.make_label("ARENA-L01 · автобой (заглушка)", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("B01 · Живой талон x3 → упрощённый stub", 24, DesignTokens.COLOR_TEXT_MUTED))

	var arena := PanelContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 20))
	vbox.add_child(arena)

	var arena_box := VBoxContainer.new()
	arena_box.add_theme_constant_override("separation", 20)
	arena.add_child(arena_box)

	arena_box.add_child(DesignTokens.make_label("Враги (тыл/фронт)", 28, DesignTokens.COLOR_DANGER_CORAL))
	arena_box.add_child(_unit_row(["E01 Талон", "E01 Талон", "E01 Талон"], DesignTokens.COLOR_DANGER_CORAL))

	arena_box.add_child(DesignTokens.make_label("Герои · фронт / тыл", 28, DesignTokens.COLOR_ACCENT_CYAN))
	arena_box.add_child(_unit_row(["H01 Каэрон (фронт)"], DesignTokens.COLOR_ACCENT_GOLD))
	arena_box.add_child(_unit_row(["H02 Вейриса (тыл)", "H03 Эльдарион (тыл)"], DesignTokens.COLOR_ACCENT_CYAN))

	var ult := DesignTokens.make_button("Ультимейт (заглушка)", false)
	ult.disabled = true
	vbox.add_child(ult)

	var win := DesignTokens.make_button("Победа → на главную", true)
	win.pressed.connect(func() -> void: SceneNav.to_home(get_tree()))
	vbox.add_child(win)


func _unit_row(names: Array, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for unit_name in names:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.custom_minimum_size = Vector2(0, 120)
		panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_ELEVATED, 12))
		var label := DesignTokens.make_label(str(unit_name), 24, color)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(label)
		row.add_child(panel)
	return row
