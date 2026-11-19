extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	var vbox := _make_root_vbox(DesignTokens.COLOR_BG_NAVY)

	var brand := DesignTokens.make_label(DesignTokens.DISPLAY_NAME, 48, DesignTokens.COLOR_ACCENT_GOLD)
	vbox.add_child(brand)

	var slogan := DesignTokens.make_label(DesignTokens.SLOGAN, 28, DesignTokens.COLOR_TEXT_MUTED)
	vbox.add_child(slogan)

	var stage := PanelContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_DEEP, 24))
	vbox.add_child(stage)

	var stage_box := VBoxContainer.new()
	stage_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stage.add_child(stage_box)
	stage_box.add_child(DesignTokens.make_label("H01 · Каэрон", 40, DesignTokens.COLOR_TEXT_IVORY))
	stage_box.add_child(DesignTokens.make_label("Витрина героя (placeholder)", 26, DesignTokens.COLOR_ACCENT_CYAN))
	stage_box.add_child(DesignTokens.make_label("Фон: намёк на L01 Площадь талонов", 24, DesignTokens.COLOR_TEXT_MUTED))

	var campaign := DesignTokens.make_button("В кампанию", true)
	campaign.pressed.connect(func() -> void: SceneNav.to_l01(get_tree()))
	vbox.add_child(campaign)

	var afk := DesignTokens.make_button("AFK (заглушка)", false)
	afk.disabled = true
	vbox.add_child(afk)

	var nav := DesignTokens.make_label("Home · UI-HOME-V0", 22, DesignTokens.COLOR_TEXT_MUTED)
	vbox.add_child(nav)
