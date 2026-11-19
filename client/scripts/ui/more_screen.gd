extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_HOME)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("Ещё", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("MVP хаб · дополнительные экраны", 22, DesignTokens.COLOR_TEXT_MUTED))
	vbox.add_child(DesignTokens.make_label(GameState.currency_line(), 20, DesignTokens.COLOR_ACCENT_CYAN))

	var links := [
		["Отряд (5)", AssetPaths.ICON_BATTLE, func() -> void: SceneNav.to_party(get_tree())],
		["Инвентарь", AssetPaths.ICON_INVENTORY, func() -> void: SceneNav.to_inventory(get_tree())],
		["Призыв", AssetPaths.ICON_SUMMON, func() -> void: SceneNav.to_gacha(get_tree())],
		["События", AssetPaths.ICON_EVENTS, func() -> void: SceneNav.to_events(get_tree())],
		["Гильдия", AssetPaths.ICON_GUILD, func() -> void: SceneNav.to_guild(get_tree())],
		["Арена", AssetPaths.ICON_ARENA, func() -> void: SceneNav.to_arena(get_tree())],
		["Экспедиции", AssetPaths.ICON_EXPEDITION, func() -> void: SceneNav.to_expedition(get_tree())],
		["Кампания", AssetPaths.ICON_QUEST, func() -> void: SceneNav.to_campaign(get_tree())],
	]
	for item in links:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		vbox.add_child(row)
		var icon := TextureRect.new()
		icon.texture = AssetPaths.tex(str(item[1]))
		icon.custom_minimum_size = Vector2(72, 72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var btn := DesignTokens.make_button(str(item[0]), false)
		btn.pressed.connect(item[2])
		row.add_child(btn)

	vbox.add_child(DesignTokens.make_label("Сеть", 28, DesignTokens.COLOR_ACCENT_GOLD))
	var mode_lbl := DesignTokens.make_label(_api_mode_text(), 20, DesignTokens.COLOR_TEXT_MUTED)
	vbox.add_child(mode_lbl)
	if GameState.allows_mock_toggle():
		var toggle := DesignTokens.make_button(
			"Включить Live API" if GameState.api.is_mock() else "Вернуть моки",
			true
		)
		toggle.pressed.connect(func() -> void:
			var want_live := GameState.api.is_mock()
			var res: Dictionary = GameState.set_live_api(want_live)
			mode_lbl.text = _api_mode_text()
			if not bool(res.get("ok", false)):
				mode_lbl.text = "Live недоступен: %s (режим не сменён · без silent mock)" % str(res.get("error", "?"))
			toggle.text = "Включить Live API" if GameState.api.is_mock() else "Вернуть моки"
			print("[More] api mode live=%s ok=%s err=%s" % [res.get("live"), res.get("ok"), res.get("error", "")])
		)
		vbox.add_child(toggle)
	else:
		vbox.add_child(DesignTokens.make_label(
			"Release: live-only (D-NET-05). Mock-переключатель отключён.",
			18,
			DesignTokens.COLOR_TEXT_MUTED
		))

	var pad := Control.new()
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(pad)
	var bottom := Control.new()
	bottom.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(bottom)
	HubChrome.attach(self, get_tree(), "more")


func _api_mode_text() -> String:
	var st := str(GameState.last_session_status)
	if GameState.api.is_mock():
		return "Режим: локальные моки (офлайн) · session=%s" % st
	return "Режим: Live → %s · session=%s" % [GameState.live_api_url, st]
