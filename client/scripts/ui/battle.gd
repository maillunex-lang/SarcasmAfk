extends "res://scripts/ui/screen_base.gd"
## AFK Arena-style portrait battle field (full-bleed arena + standing units).

var _engine: BattleEngine
var _battle_def: Dictionary = {}
var _toast: Label
var _status: Label
var _unit_widgets: Dictionary = {} # id -> widget dict
var _speed_btn: Button
var _ended_panel: VBoxContainer
var _reward_panel: VBoxContainer
var _ult_banner: Label
var _ult_bar: HBoxContainer
var _field: Control
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
		seed_val = int(abs(int(start_res.get("client_seed"))) % 2147483647)
	_engine.setup(GameState.get_party(), _battle_def.get("enemies", []), seed_val)
	_started_msec = Time.get_ticks_msec()
	_sim_tick = 0
	_populate_field()
	for u in _engine.all_units():
		_refresh_unit(u)
	_on_log("Бой начался")


func _player_title() -> String:
	# Player-facing title — no internal arena/battle ids.
	var title := str(_battle_def.get("title", "")).strip_edges()
	if title == "" or title.begins_with("B0") or title.begins_with("B1"):
		title = "Автобой"
	var loc := str(_battle_def.get("location_name", "")).strip_edges()
	if loc == "":
		loc = "Площадь талонов"
	return "%s · %s" % [loc, title]


func _build_ui() -> void:
	# Soft vignette so sprites read on busy arena art.
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.28)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	# Top chrome
	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 36
	top.offset_bottom = 120
	top.z_index = 30
	top.add_theme_constant_override("separation", 12)
	add_child(top)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_box)
	title_box.add_child(DesignTokens.make_label(_player_title(), 28, DesignTokens.COLOR_ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	_status = DesignTokens.make_label("Автобой ×1", 20, DesignTokens.COLOR_ACCENT_CYAN, HORIZONTAL_ALIGNMENT_LEFT)
	title_box.add_child(_status)

	_speed_btn = DesignTokens.make_button("×1", false)
	_speed_btn.custom_minimum_size = Vector2(96, 72)
	_speed_btn.pressed.connect(_toggle_speed)
	top.add_child(_speed_btn)

	# Battlefield occupies middle of screen
	_field = Control.new()
	_field.name = "BattleField"
	_field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_field.offset_top = 130
	_field.offset_bottom = -280
	_field.offset_left = 16
	_field.offset_right = -16
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_field.z_index = 5
	add_child(_field)

	_ult_banner = DesignTokens.make_label("", 26, DesignTokens.COLOR_ACCENT_GOLD)
	_ult_banner.visible = false
	_ult_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_ult_banner.offset_top = 140
	_ult_banner.offset_bottom = 190
	_ult_banner.z_index = 40
	add_child(_ult_banner)

	# Bottom ULT skill bar (AFK-style)
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 12
	bottom.offset_right = -12
	bottom.offset_top = -260
	bottom.offset_bottom = -16
	bottom.z_index = 30
	bottom.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_NAVY, 0.88), 18)
	)
	add_child(bottom)

	var bottom_box := VBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 8)
	bottom.add_child(bottom_box)

	_toast = DesignTokens.make_label(" ", 18, DesignTokens.COLOR_TEXT_MUTED)
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_box.add_child(_toast)

	_ult_bar = HBoxContainer.new()
	_ult_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_ult_bar.add_theme_constant_override("separation", 10)
	_ult_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_box.add_child(_ult_bar)

	_reward_panel = VBoxContainer.new()
	_reward_panel.visible = false
	_reward_panel.add_theme_constant_override("separation", 8)
	bottom_box.add_child(_reward_panel)

	_ended_panel = VBoxContainer.new()
	_ended_panel.visible = false
	_ended_panel.add_theme_constant_override("separation", 10)
	bottom_box.add_child(_ended_panel)


func _populate_field() -> void:
	if _engine == null or _field == null:
		return
	for c in _field.get_children():
		c.queue_free()
	_unit_widgets.clear()
	for c2 in _ult_bar.get_children():
		c2.queue_free()

	var enemies: Array = _engine.enemies
	var backs: Array = []
	var fronts: Array = []
	for h in _engine.heroes:
		if h.row == "back":
			backs.append(h)
		else:
			fronts.append(h)

	# Relative layout slots inside the field (portrait AFK: enemies top, allies bottom).
	_place_row(enemies, 0.12, 0.38, false)
	_place_row(backs, 0.42, 0.62, true)
	_place_row(fronts, 0.64, 0.88, true)


func _place_row(units: Array, y0: float, y1: float, with_ult: bool) -> void:
	var n := units.size()
	if n <= 0:
		return
	for i in range(n):
		var u: BattleUnit = units[i]
		var slot := Control.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.anchor_left = (float(i) + 0.08) / float(n)
		slot.anchor_right = (float(i) + 0.92) / float(n)
		slot.anchor_top = y0
		slot.anchor_bottom = y1
		slot.offset_left = 4
		slot.offset_right = -4
		_field.add_child(slot)
		slot.add_child(_make_unit_pawn(u, with_ult))


func _make_unit_pawn(unit: BattleUnit, with_ult: bool) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# HP bar above sprite
	var hp := ProgressBar.new()
	hp.max_value = 1.0
	hp.value = 1.0
	hp.show_percentage = false
	hp.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hp.offset_left = 18
	hp.offset_right = -18
	hp.offset_top = 4
	hp.offset_bottom = 18
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(DesignTokens.COLOR_BG_NAVY, 0.75)
	hp_bg.set_corner_radius_all(5)
	hp.add_theme_stylebox_override("background", hp_bg)
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = DesignTokens.COLOR_DANGER_CORAL if unit.team == "enemy" else DesignTokens.COLOR_SUCCESS_MINT
	hp_fill.set_corner_radius_all(5)
	hp.add_theme_stylebox_override("fill", hp_fill)
	root.add_child(hp)

	var energy: ProgressBar = null
	if with_ult:
		energy = ProgressBar.new()
		energy.max_value = 1.0
		energy.value = 0.0
		energy.show_percentage = false
		energy.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		energy.offset_left = 18
		energy.offset_right = -18
		energy.offset_top = 20
		energy.offset_bottom = 30
		var en_bg := StyleBoxFlat.new()
		en_bg.bg_color = Color(DesignTokens.COLOR_BG_DEEP, 0.7)
		en_bg.set_corner_radius_all(4)
		energy.add_theme_stylebox_override("background", en_bg)
		var en_fill := StyleBoxFlat.new()
		en_fill.bg_color = DesignTokens.COLOR_ACCENT_CYAN
		en_fill.set_corner_radius_all(4)
		energy.add_theme_stylebox_override("fill", en_fill)
		root.add_child(energy)

	# Standing sprite (not a card)
	var sprite_host := Control.new()
	sprite_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sprite_host.offset_top = 34
	sprite_host.offset_bottom = -36
	sprite_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sprite_host)

	var sprite: TextureRect
	if unit.team == "enemy" and unit.unit_type != "":
		var anim_sprite := CombatSpriteRect.new()
		anim_sprite.setup(unit.unit_type, unit.sprite_path)
		sprite = anim_sprite
	else:
		sprite = TextureRect.new()
		var combat_path := AssetPaths.combat_idle(unit.unit_type) if unit.unit_type != "" else unit.sprite_path
		if ResourceLoader.exists(combat_path):
			sprite.texture = AssetPaths.tex(combat_path)
		else:
			sprite.texture = AssetPaths.tex(unit.sprite_path)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite_host.add_child(sprite)

	var fx := CombatFxOverlay.new()
	sprite_host.add_child(fx)

	var name_lbl := DesignTokens.make_label(unit.display_name, 18, DesignTokens.COLOR_TEXT_IVORY)
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top = -34
	name_lbl.offset_bottom = -4
	root.add_child(name_lbl)

	var float_dmg := Label.new()
	float_dmg.visible = false
	float_dmg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_dmg.add_theme_font_size_override("font_size", 28)
	float_dmg.add_theme_color_override("font_color", DesignTokens.COLOR_ACCENT_GOLD)
	float_dmg.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	float_dmg.z_index = 20
	root.add_child(float_dmg)

	var ult_btn: Button = null
	if with_ult:
		ult_btn = _make_ult_chip(unit)
		_ult_bar.add_child(ult_btn)

	_unit_widgets[unit.id] = {
		"root": root,
		"hp": hp,
		"energy": energy,
		"ult": ult_btn,
		"sprite": sprite,
		"fx": fx,
		"float": float_dmg,
		"unit_type": unit.unit_type,
		"team": unit.team,
	}
	return root


func _make_ult_chip(unit: BattleUnit) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 100)
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = true
	var normal := StyleBoxFlat.new()
	normal.bg_color = DesignTokens.COLOR_BG_DEEP
	normal.border_color = DesignTokens.COLOR_ACCENT_GOLD
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(16)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(DesignTokens.COLOR_BG_DEEP, 0.55)
	disabled.border_color = Color(DesignTokens.COLOR_TEXT_MUTED, 0.45)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = DesignTokens.COLOR_ACCENT_CYAN
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.text = ""

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(box)

	var ic := TextureRect.new()
	var portrait := AssetPaths.hero_portrait(unit.unit_type)
	if ResourceLoader.exists(portrait):
		ic.texture = AssetPaths.tex(portrait)
	ic.custom_minimum_size = Vector2(48, 48)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(ic)
	var lbl := DesignTokens.make_label("ULT", 16, DesignTokens.COLOR_ACCENT_GOLD)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(lbl)
	var uid := unit.id
	btn.pressed.connect(func() -> void: _cast_ultimate(uid))
	return btn


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
		spr.modulate = Color(0.4, 0.4, 0.4, 0.55)
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
	_play_combat_fx(actor, target)
	_pulse_actor(actor)
	_float_hit(target)


func _pulse_actor(actor: BattleUnit) -> void:
	var w: Dictionary = _unit_widgets.get(actor.id, {}) as Dictionary
	if not w.has("root"):
		return
	var root: Control = w["root"]
	var tw := create_tween()
	tw.tween_property(root, "scale", Vector2(1.06, 1.06), 0.08)
	tw.tween_property(root, "scale", Vector2.ONE, 0.12)


func _float_hit(target: BattleUnit) -> void:
	var w: Dictionary = _unit_widgets.get(target.id, {}) as Dictionary
	if not w.has("float"):
		return
	var lbl: Label = w["float"]
	lbl.text = "!"
	lbl.visible = true
	lbl.modulate = Color(1, 1, 1, 1)
	lbl.position = Vector2(-20, -10)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", -48.0, 0.45).as_relative()
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func() -> void: lbl.visible = false)


func _play_combat_fx(actor: BattleUnit, target: BattleUnit) -> void:
	var aw: Dictionary = _unit_widgets.get(actor.id, {}) as Dictionary
	var tw: Dictionary = _unit_widgets.get(target.id, {}) as Dictionary
	var actor_fx: CombatFxOverlay = aw.get("fx", null) as CombatFxOverlay
	var target_fx: CombatFxOverlay = tw.get("fx", null) as CombatFxOverlay
	var entry: Dictionary = {}
	if actor.team == "enemy" and actor.unit_type != "":
		entry = AssetPaths.enemy_fx_entry(actor.unit_type)
	elif target.team == "enemy" and target.unit_type != "":
		entry = AssetPaths.enemy_fx_entry(target.unit_type)
	var attack_sfx := str(entry.get("attack_sfx", AssetPaths.shared_sfx("attack")))
	var hit_vfx := str(entry.get("hit_vfx", AssetPaths.shared_vfx("hit")))
	var hit_sfx := str(entry.get("hit_sfx", AssetPaths.shared_sfx("hit")))
	var death_vfx := str(entry.get("death_vfx", AssetPaths.shared_vfx("death_burst")))
	var death_sfx := str(entry.get("death_sfx", AssetPaths.shared_sfx("death")))
	var special_vfx := str(entry.get("special_vfx", AssetPaths.shared_vfx("special_burst")))
	var special_sfx := str(entry.get("special_sfx", AssetPaths.shared_sfx("special")))
	if actor_fx != null:
		actor_fx.play_sfx(attack_sfx)
		if actor.team == "enemy":
			actor_fx.play_vfx(special_vfx)
			actor_fx.play_sfx(special_sfx)
	if target_fx != null:
		if target.alive:
			target_fx.play_pair(hit_vfx, hit_sfx)
		else:
			target_fx.play_pair(death_vfx, death_sfx)


func _on_log(text: String) -> void:
	# Compact toast instead of a wall of log text (AFK-style).
	if _toast:
		_toast.text = text


func _on_ult_ready(unit: BattleUnit) -> void:
	_on_log("Ульт готов: %s" % unit.display_name)
	_refresh_unit(unit)
	_begin_ult_window(unit)


func _begin_ult_window(unit: BattleUnit) -> void:
	if _ult_pause_left > 0.0:
		_ult_pause_left = maxf(_ult_pause_left, 3.5)
	else:
		_saved_speed = _engine.speed_scale
		_ult_pause_left = 3.5
	if _ult_banner:
		_ult_banner.visible = true
		_ult_banner.text = "Ульт: %s — жмите портрет" % unit.display_name
	_status.text = "Пауза — ульт"


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
		_speed_btn.text = "×2"
		_status.text = "Автобой ×2"
	else:
		_engine.speed_scale = 1.0
		_speed_btn.text = "×1"
		_status.text = "Автобой ×1"


func _cast_ultimate(unit_id: String) -> void:
	if _engine == null:
		return
	if _engine.try_cast_ultimate(unit_id):
		_manual_ult_used = true
		var battle_id := str(_battle_def.get("battle_id", GameState.active_battle_id))
		GameState.api.send_battle_command(battle_id, "ultimate", unit_id, _sim_tick)
		_resume_after_ult_window()
		_on_log("Ульт применён")


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
		win = bool(server_fin.get("victory", false)) and bool(server_fin.get("ok", false))
	_status.text = "Победа!" if win else "Поражение"
	_on_log("Бой завершён")

	var progress: Dictionary = {}
	var reward: Dictionary = {}
	if win:
		progress = GameState.complete_battle(battle_id, server_fin)
		reward = progress.get("reward", {})

	if _ult_banner:
		_ult_banner.visible = false
	_ult_pause_left = 0.0

	_ended_panel.visible = true
	for c in _ended_panel.get_children():
		c.queue_free()
	_reward_panel.visible = win
	for c2 in _reward_panel.get_children():
		c2.queue_free()

	var msg_text := "Победа!" if win else "Поражение"
	if win and bool(progress.get("quest_completed", false)):
		msg_text = "Квест закрыт"
	elif win and str(progress.get("next_battle_id", "")) != "":
		msg_text = "Победа"
	var msg := DesignTokens.make_display_label(msg_text, 36)
	if not win:
		msg.add_theme_color_override("font_color", DesignTokens.COLOR_DANGER_CORAL)
	_ended_panel.add_child(msg)

	if win:
		var soft_gained := int(reward.get("soft", reward.get("soft_delta", 0)))
		var xp_gained := int(reward.get("commander_xp", reward.get("xp_delta", 0)))
		if bool(progress.get("newly_completed", false)):
			_reward_panel.add_child(DesignTokens.make_label(
				"+%d soft · +%d XP" % [soft_gained, xp_gained],
				28,
				DesignTokens.COLOR_ACCENT_GOLD
			))
		else:
			_reward_panel.add_child(DesignTokens.make_label(
				"Награда уже получена",
				22,
				DesignTokens.COLOR_TEXT_MUTED
			))

	_ended_panel.modulate = Color(1, 1, 1, 0)
	var end_tw := create_tween()
	end_tw.tween_property(_ended_panel, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)

	if win:
		var next_id := str(progress.get("next_battle_id", ""))
		if next_id != "":
			var nxt := DesignTokens.make_button("Следующий бой", true)
			nxt.pressed.connect(func() -> void: SceneNav.to_battle(get_tree()))
			_ended_panel.add_child(nxt)
		var loc_btn := DesignTokens.make_button("К локации", next_id == "")
		loc_btn.pressed.connect(func() -> void: SceneNav.to_location(get_tree()))
		_ended_panel.add_child(loc_btn)
		var home := DesignTokens.make_button("В город", false)
		home.pressed.connect(func() -> void: SceneNav.to_home(get_tree()))
		_ended_panel.add_child(home)
	else:
		var retry := DesignTokens.make_button("Ещё раз", true)
		retry.pressed.connect(func() -> void: SceneNav.to_battle(get_tree()))
		_ended_panel.add_child(retry)
		var home2 := DesignTokens.make_button("В город", false)
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
