extends "res://scripts/ui/screen_base.gd"

var _engine: BattleEngine
var _battle_def: Dictionary = {}
var _log: RichTextLabel
var _status: Label
var _unit_widgets: Dictionary = {} # id -> {panel, hp, energy, ult_btn}
var _speed_btn: Button
var _ended_panel: VBoxContainer
var _running: bool = true


func _ready() -> void:
	super._ready()
	_set_background(AssetPaths.ARENA_FLOOR)
	_load_battle()
	_build_ui()
	_start_engine()


func _process(delta: float) -> void:
	if _engine and _running and not _engine.finished:
		_engine.tick(delta)


func _load_battle() -> void:
	var battle_id := GameState.active_battle_id
	if battle_id == "":
		battle_id = "B01"
	var res: Dictionary = GameState.api.get_battle(battle_id, GameState.catalog)
	if bool(res.get("ok", false)):
		_battle_def = res.get("battle", {})
	else:
		_battle_def = GameState.catalog.get_battle(battle_id)


func _start_engine() -> void:
	var battle_id := str(_battle_def.get("battle_id", GameState.active_battle_id))
	var start_res: Dictionary = GameState.api.start_battle(battle_id, GameState.party_ids)
	_engine = BattleEngine.new()
	_engine.log_line.connect(_on_log)
	_engine.unit_updated.connect(_refresh_unit)
	_engine.battle_ended.connect(_on_battle_ended)
	_engine.ultimate_ready.connect(_on_ult_ready)
	_engine.setup(GameState.get_party(), _battle_def.get("enemies", []))
	for u in _engine.all_units():
		_refresh_unit(u)
	var seed_txt := str(start_res.get("client_seed", "?"))
	_on_log("Бой %s начался. Автобой активен. seed=%s mock=%s" % [
		battle_id, seed_txt, str(start_res.get("mock", true))
	])


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.42)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	var arena_label := str(_battle_def.get("location_id", "L01"))
	vbox.add_child(DesignTokens.make_label(
		"ARENA-%s · %s" % [arena_label, str(_battle_def.get("title", "Бой"))],
		34,
		DesignTokens.COLOR_ACCENT_GOLD
	))
	_status = DesignTokens.make_label("Автобой ×1", 22, DesignTokens.COLOR_ACCENT_CYAN)
	vbox.add_child(_status)

	var enemy_row := HBoxContainer.new()
	enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_row.add_theme_constant_override("separation", 12)
	vbox.add_child(enemy_row)

	var hero_row := HBoxContainer.new()
	hero_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_row.add_theme_constant_override("separation", 12)
	hero_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(hero_row)

	call_deferred("_populate_rows", enemy_row, hero_row)

	_log = RichTextLabel.new()
	_log.custom_minimum_size = Vector2(0, 220)
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.fit_content = false
	vbox.add_child(_log)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	vbox.add_child(controls)

	_speed_btn = DesignTokens.make_button("Скорость ×1", false)
	_speed_btn.pressed.connect(_toggle_speed)
	controls.add_child(_speed_btn)

	_ended_panel = VBoxContainer.new()
	_ended_panel.visible = false
	_ended_panel.add_theme_constant_override("separation", 12)
	vbox.add_child(_ended_panel)


func _populate_rows(enemy_row: HBoxContainer, hero_row: HBoxContainer) -> void:
	if _engine == null:
		return
	for e in _engine.enemies:
		enemy_row.add_child(_make_unit_card(e, false))
	for h in _engine.heroes:
		hero_row.add_child(_make_unit_card(h, true))


func _make_unit_card(unit: BattleUnit, with_ult: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(200, 280)
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_ELEVATED, 12))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var sprite := TextureRect.new()
	sprite.texture = AssetPaths.tex(unit.sprite_path)
	sprite.custom_minimum_size = Vector2(0, 140)
	sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(sprite)

	box.add_child(DesignTokens.make_label(unit.display_name, 22, DesignTokens.COLOR_TEXT_IVORY))

	var hp := ProgressBar.new()
	hp.max_value = 1.0
	hp.value = 1.0
	hp.show_percentage = false
	hp.custom_minimum_size = Vector2(0, 18)
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = DesignTokens.COLOR_DANGER_CORAL if unit.team == "enemy" else DesignTokens.COLOR_SUCCESS_MINT
	hp_fill.set_corner_radius_all(6)
	hp.add_theme_stylebox_override("fill", hp_fill)
	box.add_child(hp)

	var energy: ProgressBar = null
	var ult_btn: Button = null
	if with_ult:
		energy = ProgressBar.new()
		energy.max_value = 1.0
		energy.value = 0.0
		energy.show_percentage = false
		energy.custom_minimum_size = Vector2(0, 14)
		var en_fill := StyleBoxFlat.new()
		en_fill.bg_color = DesignTokens.COLOR_ACCENT_CYAN
		en_fill.set_corner_radius_all(6)
		energy.add_theme_stylebox_override("fill", en_fill)
		box.add_child(energy)

		ult_btn = DesignTokens.make_button("ULT", true)
		ult_btn.disabled = true
		ult_btn.custom_minimum_size = Vector2(0, 72)
		var uid := unit.id
		ult_btn.pressed.connect(func() -> void: _engine.try_cast_ultimate(uid))
		box.add_child(ult_btn)

	_unit_widgets[unit.id] = {"panel": panel, "hp": hp, "energy": energy, "ult": ult_btn, "sprite": sprite}
	return panel


func _refresh_unit(unit: BattleUnit) -> void:
	if not _unit_widgets.has(unit.id):
		return
	var w: Dictionary = _unit_widgets[unit.id]
	(w["hp"] as ProgressBar).value = unit.hp_ratio()
	if w["energy"] != null:
		(w["energy"] as ProgressBar).value = unit.energy / maxf(unit.energy_max, 1.0)
	if w["ult"] != null:
		(w["ult"] as Button).disabled = not unit.can_ultimate()
	if not unit.alive:
		(w["sprite"] as TextureRect).modulate = Color(0.4, 0.4, 0.4, 0.7)


func _on_log(text: String) -> void:
	if _log:
		_log.append_text(text + "\n")


func _on_ult_ready(unit: BattleUnit) -> void:
	_on_log("Ультимейт готов: %s" % unit.display_name)
	_refresh_unit(unit)


func _toggle_speed() -> void:
	if _engine == null:
		return
	if _engine.speed_scale < 1.5:
		_engine.speed_scale = 2.0
		_speed_btn.text = "Скорость ×2"
		_status.text = "Автобой ×2"
	else:
		_engine.speed_scale = 1.0
		_speed_btn.text = "Скорость ×1"
		_status.text = "Автобой ×1"


func _on_battle_ended(result: Dictionary) -> void:
	_running = false
	var win := bool(result.get("victory", false))
	_status.text = "Победа!" if win else "Поражение"
	_on_log("--- Бой завершён ---")

	var battle_id := str(_battle_def.get("battle_id", GameState.active_battle_id))
	var progress: Dictionary = {}
	if win:
		progress = GameState.complete_battle(battle_id)
		var reward: Dictionary = progress.get("reward", {})
		if bool(progress.get("newly_completed", false)):
			_on_log("Награда: +%d soft, +%d XP" % [int(reward.get("soft", 0)), int(reward.get("commander_xp", 0))])
		else:
			_on_log("Награда уже получена ранее.")
		if bool(progress.get("quest_completed", false)):
			_on_log("Квест завершён.")
	GameState.set_battle_result({"victory": win, "battle_id": battle_id})

	_ended_panel.visible = true
	for c in _ended_panel.get_children():
		c.queue_free()

	var msg_text := "Победа!" if win else "Поражение. Попробуйте снова."
	if win and bool(progress.get("quest_completed", false)):
		msg_text = "Квест закрыт. Город ещё стоит."
	elif win and str(progress.get("next_battle_id", "")) != "":
		msg_text = "Победа! Дальше — %s" % str(progress.get("next_battle_id", ""))
	var msg := DesignTokens.make_label(
		msg_text,
		28,
		DesignTokens.COLOR_ACCENT_GOLD if win else DesignTokens.COLOR_DANGER_CORAL
	)
	_ended_panel.add_child(msg)

	if win:
		var next_id := str(progress.get("next_battle_id", ""))
		if next_id != "":
			var nxt := DesignTokens.make_button("Следующий бой %s" % next_id, true)
			nxt.pressed.connect(func() -> void: SceneNav.to_battle(get_tree()))
			_ended_panel.add_child(nxt)
		var camp := DesignTokens.make_button("В кампанию", next_id == "")
		camp.pressed.connect(func() -> void: SceneNav.to_campaign(get_tree()))
		_ended_panel.add_child(camp)
		var home := DesignTokens.make_button("На главную", false)
		home.pressed.connect(func() -> void: SceneNav.to_home(get_tree()))
		_ended_panel.add_child(home)
	else:
		var retry := DesignTokens.make_button("Ещё раз", true)
		retry.pressed.connect(func() -> void: SceneNav.to_battle(get_tree()))
		_ended_panel.add_child(retry)
		var camp2 := DesignTokens.make_button("В кампанию", false)
		camp2.pressed.connect(func() -> void: SceneNav.to_campaign(get_tree()))
		_ended_panel.add_child(camp2)
		var home2 := DesignTokens.make_button("На главную", false)
		home2.pressed.connect(func() -> void: SceneNav.to_home(get_tree()))
		_ended_panel.add_child(home2)


func _set_background(path: String) -> void:
	var bg := TextureRect.new()
	bg.texture = AssetPaths.tex(path)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)
