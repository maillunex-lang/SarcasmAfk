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
	vbox.add_child(DesignTokens.make_label("Призыв (гача)", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("Только моки · не боевой баланс", 22, DesignTokens.COLOR_TEXT_MUTED))
	vbox.add_child(DesignTokens.make_label(GameState.currency_line(), 22, DesignTokens.COLOR_ACCENT_CYAN))
	for b in GameState.gacha_banners:
		vbox.add_child(DesignTokens.make_label(
			"%s · %s · 1 тикет" % [str(b.get("id", "")), str(b.get("name", ""))],
			24,
			DesignTokens.COLOR_TEXT_IVORY
		))
	_log = DesignTokens.make_label("Ждём призыва…", 24, DesignTokens.COLOR_TEXT_MUTED)
	vbox.add_child(_log)
	var pull := DesignTokens.make_button("Призвать ×1", true)
	pull.pressed.connect(_on_pull)
	vbox.add_child(pull)
	var back := DesignTokens.make_button("Назад", false)
	back.pressed.connect(func() -> void: SceneNav.to_more(get_tree()))
	vbox.add_child(back)


func _on_pull() -> void:
	var res := GameState.summon_once()
	if not bool(res.get("ok", false)):
		_log.text = "Нет тикетов"
		return
	_log.text = "Выпало: %s · %s · %s%s" % [
		str(res.get("hero_id", "")),
		str(res.get("name", "")),
		str(res.get("rarity", "")),
		" (новый!)" if bool(res.get("newly_owned", false)) else " (дубль → soft)",
	]
