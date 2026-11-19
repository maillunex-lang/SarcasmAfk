extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	var vbox := _make_root_vbox(DesignTokens.COLOR_BG_NAVY)
	vbox.add_child(DesignTokens.make_label("Арена", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("Асинхронный матч UI (мок соперника)", 22, DesignTokens.COLOR_TEXT_MUTED))
	vbox.add_child(DesignTokens.make_label("Ранг: Бронзовый талон · Очки: 1000", 24, DesignTokens.COLOR_ACCENT_CYAN))

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 16))
	vbox.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(DesignTokens.make_label("Соперник: Инспектор Нейросеть", 28, DesignTokens.COLOR_TEXT_IVORY))
	box.add_child(DesignTokens.make_label("Защитный отряд: 5 мок-героев", 22, DesignTokens.COLOR_TEXT_MUTED))

	var fight := DesignTokens.make_button("Сыграть защиту B01 (мок)", true)
	fight.pressed.connect(func() -> void:
		GameState.active_battle_id = "B01"
		SceneNav.to_battle(get_tree())
	)
	vbox.add_child(fight)

	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	vbox.add_child(back)
