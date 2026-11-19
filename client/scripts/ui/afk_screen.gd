extends "res://scripts/ui/screen_base.gd"

var _status: Label
var _detail: Label
var _bar: ProgressBar


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

	_bar = ProgressBar.new()
	_bar.max_value = 1.0
	_bar.value = 0.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 28)
	var fill := StyleBoxFlat.new()
	fill.bg_color = DesignTokens.COLOR_ACCENT_CYAN
	fill.set_corner_radius_all(8)
	_bar.add_theme_stylebox_override("fill", fill)
	vbox.add_child(_bar)

	_status = DesignTokens.make_label("", 26, DesignTokens.COLOR_ACCENT_CYAN)
	vbox.add_child(_status)
	_detail = DesignTokens.make_label("", 20, DesignTokens.COLOR_TEXT_MUTED)
	vbox.add_child(_detail)
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
	var hours := float(p.get("hours", 0.0))
	var max_h := float(p.get("max_hours", 24))
	_bar.value = clampf(hours / maxf(max_h, 1.0), 0.0, 1.0)
	var soft := int(p.get("soft", 0))
	var xp := int(p.get("xp", 0))
	_status.text = "Накоплено ~%.1f ч / %.0f · +%d soft · +%d XP" % [hours, max_h, soft, xp]
	if soft <= 0 and xp <= 0:
		_detail.text = "Пока пусто — зайдите позже. Награды копятся в реальном времени."
	else:
		_detail.text = "Можно забрать сейчас. Лимит AFK: %.0f ч." % max_h


func _on_claim() -> void:
	var res := GameState.claim_afk()
	if bool(res.get("ok", false)):
		_status.text = "Получено: +%d soft, +%d XP" % [int(res.get("soft", 0)), int(res.get("xp", 0))]
		_detail.text = "Таймер AFK сброшен."
		_bar.value = 0.0
	else:
		_status.text = "Пока нечего забирать — зайдите позже."
		_refresh()
