class_name BattleUnit
extends RefCounted

var id: String = ""
var display_name: String = ""
var team: String = "hero" # hero | enemy
var row: String = "front"
var max_hp: int = 1
var hp: int = 1
var atk: int = 1
var defense: int = 0
var speed: int = 100
var energy: float = 0.0
var energy_max: float = 100.0
var atb: float = 0.0
var ultimate_id: String = ""
var ultimate_name: String = ""
var sprite_path: String = ""
var unit_type: String = "" # hero id or enemy_type (E01…)
var alive: bool = true


static func from_hero(data: Dictionary) -> BattleUnit:
	var u := BattleUnit.new()
	u.id = str(data.get("id", ""))
	u.display_name = str(data.get("name", u.id))
	u.team = "hero"
	u.row = str(data.get("row", "front"))
	u.max_hp = int(data.get("hp", 100))
	u.hp = u.max_hp
	u.atk = int(data.get("atk", 10))
	u.defense = int(data.get("defense", 0))
	u.speed = int(data.get("speed", 100))
	u.energy_max = float(data.get("energy_max", 100))
	u.ultimate_id = str(data.get("ultimate_id", ""))
	u.ultimate_name = str(data.get("ultimate_name", "Ультимейт"))
	u.unit_type = u.id
	u.sprite_path = str(data.get("sprite", ""))
	return u


static func from_enemy(data: Dictionary) -> BattleUnit:
	var u := BattleUnit.new()
	u.id = str(data.get("id", ""))
	u.display_name = str(data.get("name", u.id))
	u.team = "enemy"
	u.row = str(data.get("row", "front"))
	u.max_hp = int(data.get("hp", 100))
	u.hp = u.max_hp
	u.atk = int(data.get("atk", 10))
	u.defense = int(data.get("defense", 0))
	u.speed = int(data.get("speed", 100))
	u.unit_type = str(data.get("enemy_type", data.get("type", "")))
	var sprite := str(data.get("sprite", ""))
	if u.unit_type != "":
		# Single-frame still for fallback TextureRect; CombatSpriteRect loads atlases by unit_type.
		sprite = AssetPaths.enemy_sprite_for_type(u.unit_type)
	u.sprite_path = sprite
	return u


func hp_ratio() -> float:
	return float(hp) / float(maxi(max_hp, 1))


func can_ultimate() -> bool:
	return alive and team == "hero" and energy >= energy_max and ultimate_id != ""


func take_damage(raw: int) -> int:
	var mitigated := maxi(1, raw - int(defense * 0.35))
	hp = maxi(0, hp - mitigated)
	if hp <= 0:
		alive = false
		energy = 0.0
	return mitigated


func heal(amount: int) -> int:
	if not alive:
		return 0
	var before := hp
	hp = mini(max_hp, hp + amount)
	return hp - before
