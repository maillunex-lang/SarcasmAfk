extends "res://scripts/ui/screen_base.gd"

var _log: Label


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_GACHA)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("Призыв", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label(
		"Тикеты: %d · платные баннеры OFF · Mythic только события" % GameState.summon_tickets,
		18,
		DesignTokens.COLOR_TEXT_MUTED
	))
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
		GameState.save_game()
		GameState.progress_changed.emit()
		return
	# mock fallback: sequential summon_once
	var names: PackedStringArray = []
	for i in count:
		var one := GameState.summon_once()
		if not bool(one.get("ok", false)):
			_log.text = "Нет тикетов"
			return
		names.append("%s/%s" % [str(one.get("hero_id", "")), str(one.get("rarity", ""))])
	_log.text = "Mock: " + ", ".join(names)
