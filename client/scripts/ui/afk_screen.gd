extends "res://scripts/ui/screen_base.gd"

var _status: Label


func _ready() -> void:
	super._ready()
	_set_bg_texture(AssetPaths.BG_AFK)
	var dim := ColorRect.new()
	dim.color = Color(DesignTokens.COLOR_BG_NAVY, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.add_child(DesignTokens.make_label("AFK-награды", 40, DesignTokens.COLOR_ACCENT_GOLD))
	vbox.add_child(DesignTokens.make_label("Накопление ≤ 24 часа (AFK-003 C)", 22, DesignTokens.COLOR_TEXT_MUTED))
	_status = DesignTokens.make_label("", 26, DesignTokens.COLOR_ACCENT_CYAN)
	vbox.add_child(_status)
	_refresh()

	var claim := DesignTokens.make_button("Забрать AFK", true)
	claim.pressed.connect(_on_claim)
	vbox.add_child(claim)

	var exp := DesignTokens.make_button("Экспедиции", false)
	exp.pressed.connect(func() -> void: SceneNav.to_expedition(get_tree()))
	vbox.add_child(exp)

	var pad := Control.new()
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(pad)
	var bottom := Control.new()
	bottom.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(bottom)
	HubChrome.attach(self, get_tree(), "afk")


func _refresh() -> void:
	var p := GameState.afk_pending_reward()
	_status.text = "Накоплено ~%.1f ч / %s · +%d soft · +%d XP" % [
		float(p.get("hours", 0.0)), str(p.get("max_hours", 24)), int(p.get("soft", 0)), int(p.get("xp", 0))
	]


func _on_claim() -> void:
	# Simulate some AFK time if empty (for demo): rewind claim stamp
	if int(GameState.afk_pending_reward().get("soft", 0)) == 0:
		GameState.afk_claimed_unix = int(Time.get_unix_time_from_system()) - 3600
	var res := GameState.claim_afk()
	if bool(res.get("ok", false)):
		_status.text = "Получено: +%d soft, +%d XP" % [int(res.get("soft", 0)), int(res.get("xp", 0))]
	else:
		_refresh()
