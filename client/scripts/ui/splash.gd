extends "res://scripts/ui/screen_base.gd"

var _timer: Timer


func _ready() -> void:
	super._ready()
	_set_background(AssetPaths.BG_SPLASH)

	var vbox := _make_root_vbox(Color(0, 0, 0, 0))
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var logo := TextureRect.new()
	logo.texture = AssetPaths.tex(AssetPaths.LOGO)
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, 420)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(logo)

	var brand := DesignTokens.make_label(DesignTokens.DISPLAY_NAME, 48, DesignTokens.COLOR_ACCENT_GOLD)
	vbox.add_child(brand)

	var sub := DesignTokens.make_label(DesignTokens.INTERNAL_ID, 26, DesignTokens.COLOR_ACCENT_CYAN)
	vbox.add_child(sub)

	var skip := DesignTokens.make_button("Продолжить", true)
	skip.pressed.connect(func() -> void: SceneNav.to_home(get_tree()))
	vbox.add_child(skip)

	_timer = Timer.new()
	_timer.wait_time = 2.2
	_timer.one_shot = true
	_timer.timeout.connect(func() -> void: SceneNav.to_home(get_tree()))
	add_child(_timer)
	_timer.start()


func _set_background(path: String) -> void:
	var bg := TextureRect.new()
	bg.texture = AssetPaths.tex(path)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)
