extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_add_layer(AssetPaths.L01_SKY, 0)
	_add_layer(AssetPaths.L01_FAR, 1)
	_add_layer(AssetPaths.L01_MID, 2)

	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("L01 · Площадь талонов", 42, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("Уфа · слои sky / far / mid", 24, DesignTokens.COLOR_TEXT_MUTED))

	var prop := TextureRect.new()
	prop.texture = AssetPaths.tex(AssetPaths.L01_TERMINAL)
	prop.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	prop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prop.custom_minimum_size = Vector2(0, 420)
	prop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(prop)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var dialog_btn := DesignTokens.make_button("Открыть диалог CH01-Q01", true)
	dialog_btn.pressed.connect(func() -> void: SceneNav.to_dialog(get_tree()))
	vbox.add_child(dialog_btn)

	var back := DesignTokens.make_button("На главную", false)
	back.pressed.connect(func() -> void: SceneNav.to_home(get_tree()))
	vbox.add_child(back)


func _add_layer(path: String, z: int) -> void:
	var layer := TextureRect.new()
	layer.texture = AssetPaths.tex(path)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = z
	add_child(layer)
