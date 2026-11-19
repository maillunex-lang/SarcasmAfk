extends "res://scripts/ui/screen_base.gd"
## AFK Legends-style battle: heroes LEFT, enemies RIGHT, bottom portrait tray.


var _engine: BattleEngine
var _battle_def: Dictionary = {}
var _toast: Label
var _timer_lbl: Label
var _chapter_lbl: Label
var _unit_widgets: Dictionary = {}
var _auto_btn: Button
var _speed_btn: Button
var _ended_panel: VBoxContainer
var _reward_panel: VBoxContainer
var _ult_banner: Label
var _tray: HBoxContainer
var _field: Control
var _running: bool = true
var _auto: bool = true
var _started_msec: int = 0
var _sim_tick: int = 0
var _ult_pause_left: float = 0.0
var _saved_speed: float = 1.0
var _manual_ult_used: bool = false
var _elapsed: float = 0.0


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
	_elapsed += delta
	_update_timer()
	if _ult_pause_left > 0.0:
		_ult_pause_left = maxf(0.0, _ult_pause_left - delta)
		if _ult_pause_left <= 0.0:
			_resume_after_ult_window()
		return
	if not _auto and _ult_pause_left <= 0.0:
		# Manual mode still advances ATB slowly unless paused for ULT; keep ticking.
		pass
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
	_elapsed = 0.0
	_populate_field()
	for u in _engine.all_units():
		_refresh_unit(u)


func _chapter_text() -> String:
	var loc := str(_battle_def.get("location_name", "")).strip_edges()
	if loc == "":
		loc = "Площадь талонов"
	return "Глава 1 · %s" % loc


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.22)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	# Top center: timer + chapter (AFK pattern)
	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	top.offset_top = 28
	top.offset_bottom = 110
	top.offset_left = -220
	top.offset_right = 220
	top.z_index = 30
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(top)
	_timer_lbl = DesignTokens.make_label("00:00", 34, DesignTokens.COLOR_TEXT_IVORY)
	top.add_child(_timer_lbl)
	_chapter_lbl = DesignTokens.make_label(_chapter_text(), 22, DesignTokens.COLOR_ACCENT_GOLD)
	top.add_child(_chapter_lbl)

	_ult_banner = DesignTokens.make_label("", 26, DesignTokens.COLOR_ACCENT_GOLD)
	_ult_banner.visible = false
	_ult_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_ult_banner.offset_top = 120
	_ult_banner.offset_bottom = 170
	_ult_banner.z_index = 40
	add_child(_ult_banner)

	# Field: full width between top HUD and bottom tray
	_field = Control.new()
	_field.name = "BattleField"
	_field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_field.offset_top = 130
	_field.offset_bottom = -240
	_field.offset_left = 8
	_field.offset_right = -8
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_field.z_index = 5
	add_child(_field)

	# Bottom tray
	var bottom := PanelContainer.new()
	bottom.name = "BattleTray"
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 8
	bottom.offset_right = -8
	bottom.offset_top = -220
	bottom.offset_bottom = -12
	bottom.z_index = 30
	bottom.add_theme_stylebox_override(
		"panel",
		DesignTokens.make_panel_style(Color(DesignTokens.COLOR_BG_NAVY, 0.92), 18)
	)
	add_child(bottom)

	var bottom_box := VBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 8)
	bottom.add_child(bottom_box)

	_toast = DesignTokens.make_label(" ", 18, DesignTokens.COLOR_TEXT_MUTED)
	bottom_box.add_child(_toast)

	var tray_row := HBoxContainer.new()
	tray_row.add_theme_constant_override("separation", 8)
	tray_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_box.add_child(tray_row)

	var pause_btn := DesignTokens.make_button("II", false)
	pause_btn.custom_minimum_size = Vector2(72, 96)
	pause_btn.pressed.connect(func() -> void:
		_auto = not _auto
		_auto_btn.text = "АВТО" if _auto else "РУЧН"
	)
	tray_row.add_child(pause_btn)

	_tray = HBoxContainer.new()
	_tray.name = "PortraitTray"
	_tray.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tray.add_theme_constant_override("separation", 8)
	_tray.alignment = BoxContainer.ALIGNMENT_CENTER
	tray_row.add_child(_tray)

	_auto_btn = DesignTokens.make_button("АВТО", true)
	_auto_btn.custom_minimum_size = Vector2(96, 96)
	_auto_btn.pressed.connect(func() -> void:
		_auto = true
		_auto_btn.text = "АВТО"
	)
	tray_row.add_child(_auto_btn)

	_speed_btn = DesignTokens.make_button("×1", false)
	_speed_btn.custom_minimum_size = Vector2(88, 96)
	_speed_btn.pressed.connect(_toggle_speed)
	tray_row.add_child(_speed_btn)

	_reward_panel = VBoxContainer.new()
	_reward_panel.visible = false
	bottom_box.add_child(_reward_panel)

	_ended_panel = VBoxContainer.new()
	_ended_panel.visible = false
	_ended_panel.add_theme_constant_override("separation", 10)
	bottom_box.add_child(_ended_panel)


func _update_timer() -> void:
	if _timer_lbl == null:
		return
	var sec := int(_elapsed)
	_timer_lbl.text = "%02d:%02d" % [int(sec / 60.0), sec % 60]


func _populate_field() -> void:
	if _engine == null or _field == null:
		return
	for c in _field.get_children():
		c.queue_free()
	for c2 in _tray.get_children():
		c2.queue_free()
	_unit_widgets.clear()

	var heroes: Array = []
	for h in _engine.heroes:
		heroes.append(h)
	var enemies: Array = _engine.enemies

	# LEFT heroes (front closer to center), RIGHT enemies
	_place_side(heroes, true)
	_place_side(enemies, false)


func _place_side(units: Array, is_hero: bool) -> void:
	var n := units.size()
	if n <= 0:
		return
	# 2-column formation like AFK: front/back rows mapped to x bands
	for i in range(n):
		var u: BattleUnit = units[i]
		var col := 0
		if is_hero:
			col = 0 if u.row == "front" else 1 # front nearer center → col0 toward right of left half
		else:
			col = 0 if u.row == "front" else 1
		var row_i := i
		# redistribute into visual rows
		var visual_row := i % 3
		var visual_col := int(i / 3)
		if is_hero:
			visual_col = 1 if u.row == "back" else 0
			visual_row = _count_before_same_row(units, i, u.row)
		else:
			visual_col = 0 if str(u.row) != "back" else 1
			visual_row = _count_before_same_row(units, i, u.row)

		var slot := Control.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if is_hero:
			# left half
			slot.anchor_left = 0.04 + visual_col * 0.18
			slot.anchor_right = 0.04 + visual_col * 0.18 + 0.20
		else:
			slot.anchor_left = 0.58 + visual_col * 0.18
			slot.anchor_right = 0.58 + visual_col * 0.18 + 0.20
		slot.anchor_top = 0.08 + visual_row * 0.28
		slot.anchor_bottom = 0.08 + visual_row * 0.28 + 0.30
		_field.add_child(slot)
		slot.add_child(_make_unit_pawn(u, is_hero))
		if is_hero:
			_tray.add_child(_make_portrait_chip(u))


func _count_before_same_row(units: Array, idx: int, row: String) -> int:
	var c := 0
	for j in range(idx):
		var u: BattleUnit = units[j]
		if str(u.row) == row or (row == "" and str(u.row) == "front"):
			c += 1
		elif row != "back" and str(u.row) != "back" and j < idx:
			# treat empty as front
			if row != "back" and str(u.row) != "back":
				c += 1
	# simpler: count same row among previous
	c = 0
	for j in range(idx):
		var uj: BattleUnit = units[j]
		var rj := str(uj.row)
		var r := row if row != "" else "front"
		if rj == "":
			rj = "front"
		if rj == r:
			c += 1
	return c


func _make_unit_pawn(unit: BattleUnit, with_ult: bool) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hp := ProgressBar.new()
	hp.max_value = 1.0
	hp.value = 1.0
	hp.show_percentage = false
	hp.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hp.offset_left = 10
	hp.offset_right = -10
	hp.offset_top = 0
	hp.offset_bottom = 12
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(DesignTokens.COLOR_BG_NAVY, 0.8)
	hp_bg.set_corner_radius_all(4)
	hp.add_theme_stylebox_override("background", hp_bg)
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = DesignTokens.COLOR_SUCCESS_MINT if unit.team == "hero" else DesignTokens.COLOR_DANGER_CORAL
	hp_fill.set_corner_radius_all(4)
	hp.add_theme_stylebox_override("fill", hp_fill)
	root.add_child(hp)

	var sprite_host := Control.new()
	sprite_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sprite_host.offset_top = 16
	sprite_host.offset_bottom = -8
	sprite_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sprite_host)

	var sprite: TextureRect
	if unit.team == "enemy" and unit.unit_type != "":
		var anim_sprite := CombatSpriteRect.new()
		anim_sprite.setup(unit.unit_type, unit.sprite_path)
		sprite = anim_sprite
	else:
		sprite = TextureRect.new()
		var combat_path := AssetPaths.combat_idle(unit.unit_type) if unit.unit_type != "" else ""
		if combat_path != "" and ResourceLoader.exists(combat_path):
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

	var float_dmg := Label.new()
	float_dmg.visible = false
	float_dmg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_dmg.add_theme_font_size_override("font_size", 32)
	float_dmg.add_theme_color_override("font_color", DesignTokens.COLOR_ACCENT_GOLD)
	float_dmg.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	float_dmg.z_index = 25
	root.add_child(float_dmg)

	_unit_widgets[unit.id] = {
		"root": root,
		"hp": hp,
		"energy": null,
		"ult": null,
		"sprite": sprite,
		"fx": fx,
		"float": float_dmg,
		"portrait_hp": null,
		"portrait_en": null,
		"portrait_root": null,
		"team": unit.team,
	}
	return root


func _make_portrait_chip(unit: BattleUnit) -> Control:
	var wrap := VBoxContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.custom_minimum_size = Vector2(0, 110)
	wrap.add_theme_constant_override("separation", 4)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 72)
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = true
	var normal := StyleBoxFlat.new()
	normal.bg_color = DesignTokens.COLOR_BG_DEEP
	normal.border_color = DesignTokens.COLOR_ACCENT_GOLD
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.border_color = Color(DesignTokens.COLOR_TEXT_MUTED, 0.4)
	disabled.bg_color = Color(DesignTokens.COLOR_BG_DEEP, 0.55)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("hover", normal)
	btn.add_theme_stylebox_override("pressed", normal)
	btn.text = ""
	wrap.add_child(btn)

	var ic := TextureRect.new()
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ic.offset_left = 6
	ic.offset_right = -6
	ic.offset_top = 6
	ic.offset_bottom = -6
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait := AssetPaths.hero_portrait(unit.unit_type)
	if ResourceLoader.exists(portrait):
		ic.texture = AssetPaths.tex(portrait)
	btn.add_child(ic)

	var hp := ProgressBar.new()
	hp.max_value = 1.0
	hp.value = 1.0
	hp.show_percentage = false
	hp.custom_minimum_size = Vector2(0, 10)
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = DesignTokens.COLOR_SUCCESS_MINT
	hp_fill.set_corner_radius_all(4)
	hp.add_theme_stylebox_override("fill", hp_fill)
	wrap.add_child(hp)

	var en := ProgressBar.new()
	en.max_value = 1.0
	en.value = 0.0
	en.show_percentage = false
	en.custom_minimum_size = Vector2(0, 8)
	var en_fill := StyleBoxFlat.new()
	en_fill.bg_color = DesignTokens.COLOR_ACCENT_GOLD
	en_fill.set_corner_radius_all(4)
	en.add_theme_stylebox_override("fill", en_fill)
	wrap.add_child(en)

	var uid := unit.id
	btn.pressed.connect(func() -> void: _cast_ultimate(uid))

	if _unit_widgets.has(unit.id):
		_unit_widgets[unit.id]["ult"] = btn
		_unit_widgets[unit.id]["portrait_hp"] = hp
		_unit_widgets[unit.id]["portrait_en"] = en
		_unit_widgets[unit.id]["energy"] = en
		_unit_widgets[unit.id]["portrait_root"] = wrap
	return wrap


func _refresh_unit(unit: BattleUnit) -> void:
	if not _unit_widgets.has(unit.id):
		return
	var w: Dictionary = _unit_widgets[unit.id]
	(w["hp"] as ProgressBar).value = unit.hp_ratio()
	if w.get("portrait_hp") != null:
		(w["portrait_hp"] as ProgressBar).value = unit.hp_ratio()
	if w.get("portrait_en") != null:
		(w["portrait_en"] as ProgressBar).value = unit.energy / maxf(unit.energy_max, 1.0)
	if w.get("ult") != null:
		(w["ult"] as Button).disabled = not unit.can_ultimate()
	var spr := w["sprite"] as TextureRect
	if spr == null:
		return
	if not unit.alive:
		spr.modulate = Color(0.45, 0.45, 0.45, 0.5)
		if w.get("portrait_root") != null:
			(w["portrait_root"] as Control).modulate = Color(1, 1, 1, 0.4)
		if spr is CombatSpriteRect:
			(spr as CombatSpriteRect).play("death", false)
	else:
		spr.modulate = Color.WHITE
		if w.get("portrait_root") != null:
			(w["portrait_root"] as Control).modulate = Color.WHITE


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
	_float_hit(target, actor)


func _float_hit(target: BattleUnit, actor: BattleUnit) -> void:
	var w: Dictionary = _unit_widgets.get(target.id, {}) as Dictionary
	if not w.has("float"):
		return
	var lbl: Label = w["float"]
	var dmg := maxi(1, int(actor.atk * 0.35))
	lbl.text = str(dmg)
	lbl.visible = true
	lbl.modulate = Color(1, 1, 1, 1)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", -56.0, 0.5).as_relative()
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
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
	if actor_fx != null:
		actor_fx.play_sfx(str(entry.get("attack_sfx", AssetPaths.shared_sfx("attack"))))
	if target_fx != null:
		if target.alive:
			target_fx.play_pair(str(entry.get("hit_vfx", AssetPaths.shared_vfx("hit"))), str(entry.get("hit_sfx", AssetPaths.shared_sfx("hit"))))
		else:
			target_fx.play_pair(str(entry.get("death_vfx", AssetPaths.shared_vfx("death_burst"))), str(entry.get("death_sfx", AssetPaths.shared_sfx("death"))))


func _on_log(text: String) -> void:
	if _toast:
		_toast.text = text


func _on_ult_ready(unit: BattleUnit) -> void:
	_on_log("Ульт: %s — нажмите портрет" % unit.display_name)
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
		_ult_banner.text = "Ульт готов: %s" % unit.display_name


func _resume_after_ult_window() -> void:
	_ult_pause_left = 0.0
	if _engine:
		_engine.speed_scale = _saved_speed
	if _ult_banner:
		_ult_banner.visible = false


func _toggle_speed() -> void:
	if _engine == null or _ult_pause_left > 0.0:
		return
	if _engine.speed_scale < 1.5:
		_engine.speed_scale = 2.0
		_speed_btn.text = "×2"
	else:
		_engine.speed_scale = 1.0
		_speed_btn.text = "×1"


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

	var progress: Dictionary = {}
	var reward: Dictionary = {}
	if win:
		progress = GameState.complete_battle(battle_id, server_fin)
		reward = progress.get("reward", {})

	if _ult_banner:
		_ult_banner.visible = false
	_ult_pause_left = 0.0
	_on_log("Победа!" if win else "Поражение")

	_ended_panel.visible = true
	for c in _ended_panel.get_children():
		c.queue_free()
	_reward_panel.visible = win
	for c2 in _reward_panel.get_children():
		c2.queue_free()

	_ended_panel.add_child(DesignTokens.make_display_label("Победа!" if win else "Поражение", 36))
	if win and bool(progress.get("newly_completed", false)):
		_reward_panel.add_child(DesignTokens.make_label(
			"+%d soft · +%d XP" % [
				int(reward.get("soft", reward.get("soft_delta", 0))),
				int(reward.get("commander_xp", reward.get("xp_delta", 0))),
			],
			26,
			DesignTokens.COLOR_ACCENT_GOLD
		))

	if win:
		var next_id := str(progress.get("next_battle_id", ""))
		if next_id != "":
			var nxt := DesignTokens.make_button("Следующий бой", true)
			nxt.pressed.connect(func() -> void: SceneNav.to_battle(get_tree()))
			_ended_panel.add_child(nxt)
		var home := DesignTokens.make_button("В город", next_id == "")
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
