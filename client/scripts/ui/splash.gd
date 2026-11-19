extends "res://scripts/ui/screen_base.gd"

var _timer: Timer


func _ready() -> void:
	super._ready()
	var vbox := _make_root_vbox(DesignTokens.COLOR_BG_NAVY)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var brand := DesignTokens.make_label(DesignTokens.DISPLAY_NAME, 56, DesignTokens.COLOR_ACCENT_GOLD)
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(brand)

	var sub := DesignTokens.make_label(DesignTokens.INTERNAL_ID, 28, DesignTokens.COLOR_ACCENT_CYAN)
	vbox.add_child(sub)

	var hint := DesignTokens.make_label("V0-A · заставка", 24, DesignTokens.COLOR_TEXT_MUTED)
	vbox.add_child(hint)

	var skip := DesignTokens.make_button("Продолжить", true)
	skip.pressed.connect(func() -> void: SceneNav.to_home(get_tree()))
	vbox.add_child(skip)

	_timer = Timer.new()
	_timer.wait_time = 2.0
	_timer.one_shot = true
	_timer.timeout.connect(func() -> void: SceneNav.to_home(get_tree()))
	add_child(_timer)
	_timer.start()
