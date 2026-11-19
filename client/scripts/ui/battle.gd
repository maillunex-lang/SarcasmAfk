extends "res://scripts/ui/screen_base.gd"

var _engine: BattleEngine
var _battle_def: Dictionary = {}
var _log: RichTextLabel
var _status: Label
var _unit_widgets: Dictionary = {} # id -> {panel, hp, energy, ult_btn}
var _speed_btn: Button
var _ended_panel: VBoxContainer
var _reward_panel: VBoxContainer
var _ult_banner: Label
var _running: bool = true
var _started_msec: int = 0
var _sim_tick: int = 0
var _ult_pause_left: float = 0.0
var _saved_speed: float = 1.0
var _manual_ult_used: bool = false


func _ready() -> void:
	super._ready()
	_load_battle()
	var loc_id := str(_battle_def.get("location_id", "L01"))
	_set_background(AssetPaths.arena_floor_for(loc_id))
	_build_ui()
	_start_engine()


func _process(delta: float) -> void:
	if _engine == null or not _running or _engine.finished:
		return
	if _ult_pause_left > 0.0:
		_ult_pause_left = maxf(0.0, _ult_pause_left - delta)
		if _ult_pause_left <= 0.0:
			_resume_after_ult_window()
		return
	_engine.tick(delta)
	_sim_tick += 1


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
	_engine.action_resolved.connect(_on_action_resolved)
	_engine.battle_ended.connect(_on_battle_ended)
	_engine.ultimate_ready.connect(_on_ult_ready)
	var seed_val: int = -1
	if start_res.has("client_seed"):
		# Keep within signed 32-bit for Godot RNG; server seed is int64.
		seed_val = int(abs(int(start_res.get("client_seed"))) % 2147483647)
	_engine.setup(GameState.get_party(), _battle_def.get("enemies", []), seed_val)
	_started_msec = Time.get_ticks_msec()
	_sim_tick = 0
	for u in _engine.all_units():
		_refresh_unit(u)
	var seed_txt := str(start_res.get("client_seed", "?"))
	_on_log("Бой %s начался. Автобой активен. seed=%s mock=%s bal=%s" % [
		battle_id, seed_txt, str(start_res.get("mock", GameState.api.is_mock())),
		str(start_res.get("balance_version", "-"))
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

	var hero_back := HBoxContainer.new()
	hero_back.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_back.add_theme_constant_override("separation", 12)
	vbox.add_child(hero_back)
	vbox.add_child(DesignTokens.make_label("Тыл", 18, DesignTokens.COLOR_TEXT_MUTED))

	var hero_front := HBoxContainer.new()
	hero_front.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_front.add_theme_constant_override("separation", 12)
	hero_front.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(hero_front)
	vbox.add_child(DesignTokens.make_label("Фронт", 18, DesignTokens.COLOR_TEXT_MUTED))

	call_deferred("_populate_rows", enemy_row, hero_front, hero_back)

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

	_ult_banner = DesignTokens.make_label("", 24, DesignTokens.COLOR_ACCENT_GOLD)
	_ult_banner.visible = false
	vbox.add_child(_ult_banner)

	_reward_panel = VBoxContainer.new()
	_reward_panel.visible = false
	_reward_panel.add_theme_constant_override("separation", 8)
	vbox.add_child(_reward_panel)

	_ended_panel = VBoxContainer.new()
	_ended_panel.visible = false
	_ended_panel.add_theme_constant_override("separation", 12)
	vbox.add_child(_ended_panel)


func _populate_rows(enemy_row: HBoxContainer, hero_front: HBoxContainer, hero_back: HBoxContainer) -> void:
	if _engine == null:
		return
	for e in _engine.enemies:
		enemy_row.add_child(_make_unit_card(e, false))
	for h in _engine.heroes:
		var card := _make_unit_card(h, true)
		if h.row == "back":
			hero_back.add_child(card)
		else:
			hero_front.add_child(card)


func _make_unit_card(unit: BattleUnit, with_ult: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(160, 260)
	panel.add_theme_stylebox_override("panel", DesignTokens.make_panel_style(DesignTokens.COLOR_BG_ELEVATED, 12))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var sprite: TextureRect
	if unit.team == "enemy" and unit.unit_type != "":
		var anim_sprite := CombatSpriteRect.new()
		anim_sprite.setup(unit.unit_type, unit.sprite_path)
		sprite = anim_sprite
	else:
		sprite = TextureRect.new()
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
		ult_btn.pressed.connect(func() -> void: _cast_ultimate(uid))
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
	var spr := w["sprite"] as TextureRect
	if spr == null:
		return
	if not unit.alive:
		spr.modulate = Color(0.4, 0.4, 0.4, 0.7)
		if spr is CombatSpriteRect:
			(spr as CombatSpriteRect).play("death", false)
	else:
		spr.modulate = Color.WHITE


func _on_action_resolved(actor: BattleUnit, target: BattleUnit) -> void:
	var aw: Dictionary = _unit_widgets.get(actor.id, {}) as Dictionary
	var tw: Dictionary = _unit_widgets.get(target.id, {}) as Dictionary
	if aw.has("sprite") and aw["sprite"] is CombatSpriteRect:
		(aw["sprite"] as CombatSpriteRect).play_once("attack")
	if tw.has("sprite") and tw["sprite"] is CombatSpriteRect and target.alive:
		(tw["sprite"] as CombatSpriteRect).play_once("hit")
	elif tw.has("sprite") and tw["sprite"] is CombatSpriteRect and not target.alive:
		(tw["sprite"] as CombatSpriteRect).play("death", false)


func _on_log(text: String) -> void:
	if _log:
		_log.append_text(text + "\n")


func _on_ult_ready(unit: BattleUnit) -> void:
	_on_log("Ультимейт готов: %s — нажмите ULT" % unit.display_name)
	_refresh_unit(unit)
	_begin_ult_window(unit)


func _begin_ult_window(unit: BattleUnit) -> void:
	# Give the player a short window to tap ULT before autofight continues.
	if _ult_pause_left > 0.0:
		_ult_pause_left = maxf(_ult_pause_left, 3.5)
	else:
		_saved_speed = _engine.speed_scale
		_ult_pause_left = 3.5
	if _ult_banner:
		_ult_banner.visible = true
		_ult_banner.text = "ULT готов: %s" % unit.display_name
	_status.text = "Пауза — жмите ULT"


func _resume_after_ult_window() -> void:
	_ult_pause_left = 0.0
	if _engine:
		_engine.speed_scale = _saved_speed
	if _ult_banner:
		_ult_banner.visible = false
	if _speed_btn and _engine:
		_status.text = "Автобой ×%s" % ("2" if _engine.speed_scale >= 1.5 else "1")


func _toggle_speed() -> void:
	if _engine == null:
		return
	if _ult_pause_left > 0.0:
		return
	if _engine.speed_scale < 1.5:
		_engine.speed_scale = 2.0
		_speed_btn.text = "Скорость ×2"
		_status.text = "Автобой ×2"
	else:
		_engine.speed_scale = 1.0
		_speed_btn.text = "Скорость ×1"
		_status.text = "Автобой ×1"


func _cast_ultimate(unit_id: String) -> void:
	if _engine == null:
		return
	if _engine.try_cast_ultimate(unit_id):
		_manual_ult_used = true
		var battle_id := str(_battle_def.get("battle_id", GameState.active_battle_id))
		GameState.api.send_battle_command(battle_id, "ultimate", unit_id, _sim_tick)
		_resume_after_ult_window()
		_on_log("Ульт применён вручную.")


func _on_battle_ended(result: Dictionary) -> void:
	_running = false
	var local_win := bool(result.get("victory", false))
	var battle_id := str(_battle_def.get("battle_id", GameState.active_battle_id))
	var duration_ms := maxi(0, Time.get_ticks_msec() - _started_msec)
	var server_fin: Dictionary = GameState.set_battle_result({
		"victory": local_win,
		"battle_id": battle_id,
		"duration_ms": duration_ms,
	})
	var win := local_win
	if GameState.api != null and not GameState.api.is_mock():
		# Authoritative server result
		win = bool(server_fin.get("victory", false)) and bool(server_fin.get("ok", false))
		_on_log("Сервер: victory=%s ticks=%s" % [win, str(server_fin.get("sim_ticks", "?"))])
	_status.text = "Победа!" if win else "Поражение"
	_on_log("--- Бой завершён ---")

	var progress: Dictionary = {}
	var reward: Dictionary = {}
	if win:
		progress = GameState.complete_battle(battle_id, server_fin)
		reward = progress.get("reward", {})
		if bool(progress.get("newly_completed", false)):
			_on_log("Награда: +%d soft, +%d XP" % [
				int(reward.get("soft", reward.get("soft_delta", 0))),
				int(reward.get("commander_xp", reward.get("xp_delta", 0)))
			])
		elif str(progress.get("error", "")) != "":
			_on_log("Прогресс не принят: %s" % progress.get("error"))
		else:
			_on_log("Награда уже получена ранее.")
		if bool(progress.get("quest_completed", false)):
			_on_log("Квест завершён.")

	if _ult_banner:
		_ult_banner.visible = false
	_ult_pause_left = 0.0

	_ended_panel.visible = true
	for c in _ended_panel.get_children():
		c.queue_free()
	_reward_panel.visible = win
	for c2 in _reward_panel.get_children():
		c2.queue_free()

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
		var soft_gained := int(reward.get("soft", reward.get("soft_delta", 0)))
		var xp_gained := int(reward.get("commander_xp", reward.get("xp_delta", 0)))
		if bool(progress.get("newly_completed", false)):
			_reward_panel.add_child(DesignTokens.make_label("Награда", 26, DesignTokens.COLOR_ACCENT_CYAN))
			_reward_panel.add_child(DesignTokens.make_label(
				"+%d soft · +%d XP" % [soft_gained, xp_gained],
				32,
				DesignTokens.COLOR_ACCENT_GOLD
			))
		else:
			_reward_panel.add_child(DesignTokens.make_label(
				"Награда уже получена ранее",
				24,
				DesignTokens.COLOR_TEXT_MUTED
			))
		if _manual_ult_used:
			_reward_panel.add_child(DesignTokens.make_label("Ручной ULT: да", 20, DesignTokens.COLOR_SUCCESS_MINT))

	if win:
		var next_id := str(progress.get("next_battle_id", ""))
		if next_id != "":
			var nxt := DesignTokens.make_button("Следующий бой %s" % next_id, true)
			nxt.pressed.connect(func() -> void: SceneNav.to_battle(get_tree()))
			_ended_panel.add_child(nxt)
		var loc_btn := DesignTokens.make_button("К локации", next_id == "")
		loc_btn.pressed.connect(func() -> void: SceneNav.to_location(get_tree()))
		_ended_panel.add_child(loc_btn)
		var camp := DesignTokens.make_button("В кампанию", false)
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
