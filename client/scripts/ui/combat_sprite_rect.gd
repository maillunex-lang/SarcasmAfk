class_name CombatSpriteRect
extends TextureRect
## Plays TEMP horizontal atlas sheets (8×256) for CH01 enemies.
## Falls back to a static texture when atlas meta is missing.

const FRAME_DEFAULT := 256
const FPS_IDLE := 8.0
const FPS_ACTION := 12.0

var unit_type: String = ""
var _atlases: Dictionary = {} # anim -> {tex, frames, fw, fh}
var _anim: String = "idle"
var _frame: int = 0
var _accum: float = 0.0
var _loop: bool = true
var _pending_return: String = "idle"
var _atlas_tex: AtlasTexture


func setup(type_id: String, fallback_path: String = "") -> void:
	unit_type = type_id
	_atlas_tex = AtlasTexture.new()
	texture = _atlas_tex
	expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(0, 140)
	_load_anims()
	if _atlases.has("idle"):
		play("idle", true)
	elif fallback_path != "":
		texture = AssetPaths.tex(fallback_path)
		_atlas_tex = null
	elif unit_type != "":
		texture = AssetPaths.tex(AssetPaths.enemy_sprite_for_type(unit_type))
		_atlas_tex = null


func _load_anims() -> void:
	_atlases.clear()
	if unit_type == "":
		return
	for anim in ["idle", "attack", "hit", "death", "special", "telegraph"]:
		var meta_path := AssetPaths.enemy_atlas_meta(unit_type, anim)
		var png_path := AssetPaths.enemy_atlas(unit_type, anim)
		if meta_path == "" or png_path == "":
			continue
		if not ResourceLoader.exists(meta_path) or not ResourceLoader.exists(png_path):
			continue
		var file := FileAccess.open(meta_path, FileAccess.READ)
		if file == null:
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var meta: Dictionary = parsed
		var sheet: Texture2D = AssetPaths.tex(png_path)
		if sheet == null:
			continue
		_atlases[anim] = {
			"tex": sheet,
			"frames": int(meta.get("frame_count", 8)),
			"fw": int(meta.get("frame_w", FRAME_DEFAULT)),
			"fh": int(meta.get("frame_h", FRAME_DEFAULT)),
		}


func play(anim: String, loop: bool = false) -> void:
	if not _atlases.has(anim):
		if anim != "idle" and _atlases.has("idle"):
			anim = "idle"
			loop = true
		else:
			return
	_anim = anim
	_loop = loop
	_frame = 0
	_accum = 0.0
	_apply_frame()


func play_once(anim: String, return_to: String = "idle") -> void:
	_pending_return = return_to
	play(anim, false)


func _process(delta: float) -> void:
	if _atlas_tex == null or not _atlases.has(_anim):
		return
	var fps := FPS_IDLE if _anim == "idle" else FPS_ACTION
	_accum += delta
	var step := 1.0 / fps
	while _accum >= step:
		_accum -= step
		_advance()


func _advance() -> void:
	var info: Dictionary = _atlases[_anim]
	var count: int = int(info["frames"])
	_frame += 1
	if _frame >= count:
		if _loop:
			_frame = 0
		else:
			_frame = count - 1
			if _pending_return != "" and _atlases.has(_pending_return) and _anim != "death":
				play(_pending_return, true)
			return
	_apply_frame()


func _apply_frame() -> void:
	if _atlas_tex == null or not _atlases.has(_anim):
		return
	var info: Dictionary = _atlases[_anim]
	var fw: int = int(info["fw"])
	var fh: int = int(info["fh"])
	_atlas_tex.atlas = info["tex"]
	_atlas_tex.region = Rect2(_frame * fw, 0, fw, fh)
	texture = _atlas_tex
