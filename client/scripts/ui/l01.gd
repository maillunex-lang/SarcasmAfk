extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	var vbox := _make_root_vbox(DesignTokens.COLOR_BG_DEEP)

	vbox.add_child(DesignTokens.make_label("L01 · Площадь талонов", 44, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("Уфа · день · V0 stub layers", 26, DesignTokens.COLOR_TEXT_MUTED))

	var layers := PanelContainer.new()
	layers.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layers.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_NAVY, 20))
	vbox.add_child(layers)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	layers.add_child(list)
	for layer_name in ["sky", "far", "mid", "props (терминал)", "near", "fx (талоны)"]:
		list.add_child(DesignTokens.make_label("• слой: %s" % layer_name, 28, DesignTokens.COLOR_TEXT_IVORY, HORIZONTAL_ALIGNMENT_LEFT))

	var dialog_btn := DesignTokens.make_button("Открыть диалог CH01-Q01", true)
	dialog_btn.pressed.connect(func() -> void: SceneNav.to_dialog(get_tree()))
	vbox.add_child(dialog_btn)

	var back := DesignTokens.make_button("На главную", false)
	back.pressed.connect(func() -> void: SceneNav.to_home(get_tree()))
	vbox.add_child(back)
