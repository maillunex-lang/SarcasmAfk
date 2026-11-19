extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_set_background(AssetPaths.ARENA_FLOOR)

	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.4)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("ARENA-L01 · автобой (заглушка)", 36, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("Статичные спрайты · атласы позже (T-031)", 22, DesignTokens.COLOR_TEXT_MUTED))

	var arena := PanelContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_DEEP, 0.75), 20))
	vbox.add_child(arena)

	var arena_box := VBoxContainer.new()
	arena_box.add_theme_constant_override("separation", 16)
	arena.add_child(arena_box)

	arena_box.add_child(DesignTokens.make_label("Враги", 26, DesignTokens.COLOR_DANGER_CORAL))
	arena_box.add_child(_sprite_row([AssetPaths.E01, AssetPaths.E01, AssetPaths.E01], 160))

	arena_box.add_child(DesignTokens.make_label("Герои", 26, DesignTokens.COLOR_ACCENT_CYAN))
	arena_box.add_child(_sprite_row([AssetPaths.H01_FULL], 220))
	arena_box.add_child(_sprite_row([AssetPaths.H02_FULL, AssetPaths.H03_FULL], 200))

	var win := DesignTokens.make_button("Победа → на главную", true)
	win.pressed.connect(func() -> void: SceneNav.to_home(get_tree()))
	vbox.add_child(win)


func _set_background(path: String) -> void:
	var bg := TextureRect.new()
	bg.texture = AssetPaths.tex(path)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)


func _sprite_row(paths: Array, height: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for path in paths:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_ELEVATED, 12))
		var tr := TextureRect.new()
		tr.texture = AssetPaths.tex(str(path))
		tr.custom_minimum_size = Vector2(0, height)
		tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		panel.add_child(tr)
		row.add_child(panel)
	return row
