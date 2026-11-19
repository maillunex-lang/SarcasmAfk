extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_set_background(AssetPaths.BG_HOME)

	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.38)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_theme_constant_override("separation", 14)

	vbox.add_child(_build_top_bar())
	vbox.add_child(_build_brand_block())
	vbox.add_child(_build_hero_stage())
	vbox.add_child(DesignTokens.make_label(GameState.chapter_progress_text(), 20, DesignTokens.COLOR_TEXT_MUTED))

	var mid := GameState.mid_quest_continue()
	if not mid.is_empty():
		var cont := DesignTokens.make_button(str(mid.get("label", "Продолжить")), true)
		var dest := str(mid.get("dest", "location"))
		cont.pressed.connect(func() -> void: _continue_mid_quest(dest))
		vbox.add_child(cont)
		vbox.add_child(DesignTokens.make_label(str(mid.get("hint", "")), 18, DesignTokens.COLOR_TEXT_MUTED))

	vbox.add_child(_build_quick_grid(mid.is_empty()))

	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(pad)

	HubChrome.attach(self, get_tree(), "home")


func _build_top_bar() -> PanelContainer:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_NAVY, 0.78), 18)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)

	var avatar := TextureRect.new()
	avatar.texture = AssetPaths.tex(AssetPaths.AVATAR_DEFAULT)
	avatar.custom_minimum_size = Vector2(72, 72)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	row.add_child(avatar)

	var vip_wrap := VBoxContainer.new()
	vip_wrap.add_theme_constant_override("separation", 2)
	row.add_child(vip_wrap)
	var vip_icon := TextureRect.new()
	vip_icon.texture = AssetPaths.tex(AssetPaths.VIP_BADGE_GOLD)
	vip_icon.custom_minimum_size = Vector2(48, 48)
	vip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vip_wrap.add_child(vip_icon)
	vip_wrap.add_child(DesignTokens.make_label("VIP %d" % GameState.vip_level, 16, DesignTokens.COLOR_ACCENT_GOLD))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	for pair in [
		[AssetPaths.ICON_SOFT, str(GameState.soft_currency)],
		[AssetPaths.ICON_HARD, str(GameState.hard_currency)],
		[AssetPaths.ICON_TICKET, str(GameState.summon_tickets)],
	]:
		row.add_child(_currency_chip(str(pair[0]), str(pair[1])))
	return bar


func _currency_chip(icon_path: String, value: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_DEEP, 0.92), 12)
	)
	var style: StyleBoxFlat = chip.get_theme_stylebox("panel")
	style.content_margin_left = 10
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	chip.add_child(row)
	var ic := TextureRect.new()
	ic.texture = AssetPaths.tex(icon_path)
	ic.custom_minimum_size = Vector2(36, 36)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(ic)
	row.add_child(DesignTokens.make_label(value, 20, DesignTokens.COLOR_ACCENT_CYAN))
	return chip


func _build_brand_block() -> VBoxContainer:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 6)
	block.add_child(DesignTokens.make_display_label(DesignTokens.DISPLAY_NAME, 44))
	block.add_child(DesignTokens.make_label(DesignTokens.SLOGAN, 20, DesignTokens.COLOR_TEXT_MUTED))
	return block


func _build_hero_stage() -> PanelContainer:
	var stage := PanelContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_DEEP, 0.55), 24)
	)
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(0, 520)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(stack)

	var backdrop := TextureRect.new()
	backdrop.texture = AssetPaths.tex(AssetPaths.HOME_HERO_STAGE)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(backdrop)

	var veil := ColorRect.new()
	veil.color = Color(DesignTokens.COLOR_BG_NAVY, 0.22)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(veil)

	var hero := TextureRect.new()
	hero.texture = AssetPaths.tex(AssetPaths.hero_full("H01"))
	hero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(hero)

	var caption := PanelContainer.new()
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -88
	caption.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_NAVY, 0.82), 14)
	)
	stack.add_child(caption)
	var cap_box := VBoxContainer.new()
	caption.add_child(cap_box)
	cap_box.add_child(DesignTokens.make_label("H01 · Каэрон", 26, DesignTokens.COLOR_TEXT_IVORY))
	cap_box.add_child(DesignTokens.make_label("Командир отряда · арт TEMP до Stage E", 16, DesignTokens.COLOR_TEXT_MUTED))
	# Soft entrance motion for hero stage.
	stage.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(stage, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return stage


func _build_quick_grid(map_primary: bool) -> VBoxContainer:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 10)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	wrap.add_child(row1)
	row1.add_child(_quick_tile("Карта Уфы", AssetPaths.ICON_MAP, map_primary, func() -> void: SceneNav.to_map(get_tree())))
	row1.add_child(_quick_tile("Кампания", AssetPaths.ICON_QUEST, false, func() -> void: SceneNav.to_campaign(get_tree())))
	row1.add_child(_quick_tile("AFK", AssetPaths.ICON_AFK, false, func() -> void: SceneNav.to_afk(get_tree())))

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	wrap.add_child(row2)
	row2.add_child(_quick_tile("Магазин", AssetPaths.ICON_SHOP, true, func() -> void: SceneNav.to_shop(get_tree())))
	row2.add_child(_quick_tile("Призыв", AssetPaths.ICON_SUMMON, false, func() -> void: SceneNav.to_gacha(get_tree())))
	row2.add_child(_quick_tile("VIP", AssetPaths.ICON_VIP, false, func() -> void: SceneNav.to_vip(get_tree())))
	return wrap


func _quick_tile(title: String, icon_path: String, primary: bool, on_press: Callable) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 128)
	var normal := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	if primary:
		normal.bg_color = Color(DesignTokens.COLOR_ACCENT_GOLD, 0.95)
		pressed.bg_color = DesignTokens.COLOR_ACCENT_GOLD.darkened(0.08)
		btn.add_theme_color_override("font_color", DesignTokens.COLOR_TEXT_ON_GOLD)
		btn.add_theme_color_override("font_pressed_color", DesignTokens.COLOR_TEXT_ON_GOLD)
	else:
		normal.bg_color = Color(DesignTokens.COLOR_BG_DEEP, 0.9)
		normal.border_color = Color(DesignTokens.COLOR_ACCENT_GOLD, 0.55)
		normal.set_border_width_all(2)
		pressed.bg_color = DesignTokens.COLOR_BG_ELEVATED
		pressed.border_color = DesignTokens.COLOR_ACCENT_GOLD
		pressed.set_border_width_all(2)
		btn.add_theme_color_override("font_color", DesignTokens.COLOR_TEXT_IVORY)
	normal.set_corner_radius_all(16)
	pressed.set_corner_radius_all(16)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("hover", normal)
	btn.pressed.connect(on_press)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(box)
	var icon := TextureRect.new()
	icon.texture = AssetPaths.tex(icon_path)
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var lbl := DesignTokens.make_label(title, 18, DesignTokens.COLOR_TEXT_IVORY if not primary else DesignTokens.COLOR_TEXT_ON_GOLD)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(lbl)
	btn.text = ""
	return btn


func _continue_mid_quest(dest: String) -> void:
	match dest:
		"dialog":
			SceneNav.to_dialog(get_tree())
		"party":
			SceneNav.to_party(get_tree())
		"battle":
			SceneNav.to_battle(get_tree())
		"location":
			SceneNav.to_location(get_tree())
		_:
			SceneNav.to_map(get_tree())


func _set_background(path: String) -> void:
	var bg := TextureRect.new()
	bg.texture = AssetPaths.tex(path)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)
