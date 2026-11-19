extends "res://scripts/ui/screen_base.gd"

var _log: Label
var _result_frame: TextureRect
var _result_label: Label


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_GACHA)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_display_label("Призыв", 48))
	vbox.add_child(DesignTokens.make_label(
		"Тикеты: %d · платные баннеры OFF · Mythic только события" % GameState.summon_tickets,
		18,
		DesignTokens.COLOR_TEXT_MUTED
	))

	var portal := TextureRect.new()
	portal.texture = AssetPaths.tex(AssetPaths.GACHA_PORTAL)
	portal.custom_minimum_size = Vector2(0, 320)
	portal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(portal)

	var reveal := CenterContainer.new()
	reveal.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(reveal)
	var reveal_stack := Control.new()
	reveal_stack.custom_minimum_size = Vector2(160, 200)
	reveal.add_child(reveal_stack)
	_result_frame = TextureRect.new()
	_result_frame.texture = AssetPaths.tex(AssetPaths.gacha_frame("N"))
	_result_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_result_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_result_frame.modulate = Color(1, 1, 1, 0.35)
	reveal_stack.add_child(_result_frame)
	_result_label = DesignTokens.make_label("—", 28, DesignTokens.COLOR_ACCENT_GOLD)
	_result_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reveal_stack.add_child(_result_label)

	vbox.add_child(DesignTokens.make_label(
		"Обычный: N50% R35% SR12% SSR3%",
		16,
		DesignTokens.COLOR_ACCENT_CYAN
	))
	vbox.add_child(DesignTokens.make_label(
		"Продвинутый: R70% SR24% SSR5% UR1% · pity SR/10 · SSR/80 (замена результата)",
		16,
		DesignTokens.COLOR_ACCENT_CYAN
	))

	_log = DesignTokens.make_label("Ждём призыва…", 22, DesignTokens.COLOR_TEXT_MUTED)
	vbox.add_child(_log)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vbox.add_child(row)
	var p1 := DesignTokens.make_button("Обычный ×1", true)
	p1.pressed.connect(func() -> void: _pull("BANNER_STANDARD", 1))
	row.add_child(p1)
	var p10 := DesignTokens.make_button("Обычный ×10", false)
	p10.pressed.connect(func() -> void: _pull("BANNER_STANDARD", 10))
	row.add_child(p10)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	vbox.add_child(row2)
	var a1 := DesignTokens.make_button("Продв. ×1", true)
	a1.pressed.connect(func() -> void: _pull("BANNER_ADVANCED", 1))
	row2.add_child(a1)
	var a10 := DesignTokens.make_button("Продв. ×10", false)
	a10.pressed.connect(func() -> void: _pull("BANNER_ADVANCED", 10))
	row2.add_child(a10)

	var heroes := DesignTokens.make_button("К коллекции", false)
	heroes.pressed.connect(func() -> void: SceneNav.to_heroes(get_tree()))
	vbox.add_child(heroes)
	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	vbox.add_child(back)


func _pull(banner_id: String, count: int) -> void:
	if GameState.summon_tickets < count:
		_log.text = "Недостаточно тикетов"
		return
	if not GameState.api.use_mock:
		var res: Dictionary = GameState.api.gacha_summon_banner(banner_id, count)
		if not bool(res.get("ok", false)):
			_log.text = "Ошибка: %s" % str(res.get("error", "?"))
			return
		GameState.summon_tickets = int(res.get("tickets", GameState.summon_tickets))
		var results: Array = res.get("results", [])
		var parts: PackedStringArray = []
		for r in results:
			parts.append("%s/%s" % [str(r.get("hero_id", "")), str(r.get("rarity", ""))])
			var hid := str(r.get("hero_id", ""))
			if hid != "" and bool(r.get("newly_owned", false)):
				GameState.owned_heroes[hid] = true
				GameState.hero_levels[hid] = 1
		_log.text = "Результат: " + ", ".join(parts)
		if not results.is_empty() and typeof(results[0]) == TYPE_DICTIONARY:
			_show_reveal(str(results[0].get("hero_id", "")), str(results[0].get("rarity", "N")))
		GameState.save_game()
		GameState.progress_changed.emit()
		return
	# mock fallback: sequential summon_once
	var names: PackedStringArray = []
	var last_id := ""
	var last_rarity := "N"
	for i in count:
		var one := GameState.summon_once()
		if not bool(one.get("ok", false)):
			_log.text = "Нет тикетов"
			return
		last_id = str(one.get("hero_id", ""))
		last_rarity = str(one.get("rarity", "N"))
		names.append("%s/%s" % [last_id, last_rarity])
	_log.text = "Mock: " + ", ".join(names)
	_show_reveal(last_id, last_rarity)


func _show_reveal(hero_id: String, rarity: String) -> void:
	if _result_frame == null or _result_label == null:
		return
	_result_frame.texture = AssetPaths.tex(AssetPaths.gacha_frame(rarity))
	_result_frame.modulate = Color(1, 1, 1, 1)
	_result_label.text = "%s\n%s" % [hero_id, rarity]
	_result_label.add_theme_color_override("font_color", DesignTokens.rarity_color(rarity))
	_result_frame.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_result_frame, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE)
