extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_ARENA)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("Арена", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("НЕДОСТУПНО · PvP отложено до CH01 (D-SCOPE-01)", 22, DesignTokens.COLOR_DANGER_CORAL))
	vbox.add_child(DesignTokens.make_label("Ранг: — · контракт API сохранён", 24, DesignTokens.COLOR_ACCENT_CYAN))

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 16))
	vbox.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(DesignTokens.make_label("Live арена и matchmaking — P3", 28, DesignTokens.COLOR_TEXT_IVORY))
	box.add_child(DesignTokens.make_label("Кнопка матча отключена до открытия этапа.", 22, DesignTokens.COLOR_TEXT_MUTED))

	var fight := DesignTokens.make_button("Матч недоступен", true)
	fight.disabled = true
	vbox.add_child(fight)

	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	vbox.add_child(back)
