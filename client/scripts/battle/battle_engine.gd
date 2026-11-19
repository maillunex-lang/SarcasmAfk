class_name BattleEngine
extends RefCounted
## Simple ATB autofight for V0-C. Placeholder formulas — not final balance.

signal log_line(text: String)
signal unit_updated(unit: BattleUnit)
signal action_resolved(actor: BattleUnit, target: BattleUnit)
signal battle_ended(result: Dictionary)
signal ultimate_ready(unit: BattleUnit)

const ATB_THRESHOLD := 100.0
## ~3 hits to fill a 100 energy bar so B01 can show a manual ULT before trash dies.
const ENERGY_PER_HIT := 35.0

var heroes: Array = [] # BattleUnit
var enemies: Array = [] # BattleUnit
var speed_scale: float = 1.0
var finished: bool = false
var victory: bool = false
var _rng := RandomNumberGenerator.new()


func setup(party: Array, enemy_defs: Array, rng_seed: int = -1) -> void:
	if rng_seed >= 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	heroes.clear()
	enemies.clear()
	finished = false
	victory = false
	for h in party:
		heroes.append(BattleUnit.from_hero(h))
	for e in enemy_defs:
		enemies.append(BattleUnit.from_enemy(e))
	for u in all_units():
		u.atb = _rng.randf_range(0.0, 40.0)


func all_units() -> Array:
	return heroes + enemies


func living(team: String) -> Array:
	var out: Array = []
	for u in all_units():
		if u.alive and u.team == team:
			out.append(u)
	return out


func tick(delta: float) -> void:
	if finished:
		return
	# Tuned for ~1 action every ~0.7–1.0s at speed 100 / ×1
	var step := delta * speed_scale
	for u in all_units():
		if not u.alive:
			continue
		u.atb += float(u.speed) * 1.15 * step
		if u.atb >= ATB_THRESHOLD:
			u.atb = 0.0
			_act(u)
			if finished:
				return


func try_cast_ultimate(unit_id: String) -> bool:
	if finished:
		return false
	for u in heroes:
		if u.id == unit_id and u.can_ultimate():
			u.energy = 0.0
			_cast_ultimate(u)
			unit_updated.emit(u)
			_check_end()
			return true
	return false


func _act(actor: BattleUnit) -> void:
	if actor.team == "hero":
		var target: BattleUnit = _pick_target(enemies)
		if target == null:
			return
		var dealt: int = target.take_damage(_compute_damage(actor, target))
		actor.energy = mini(actor.energy_max, actor.energy + ENERGY_PER_HIT)
		log_line.emit("%s бьёт %s на %d" % [actor.display_name, target.display_name, dealt])
		action_resolved.emit(actor, target)
		unit_updated.emit(actor)
		unit_updated.emit(target)
		if actor.can_ultimate():
			ultimate_ready.emit(actor)
	else:
		var hero_target: BattleUnit = _pick_target(heroes)
		if hero_target == null:
			return
		var dealt_e: int = hero_target.take_damage(_compute_damage(actor, hero_target))
		log_line.emit("%s бьёт %s на %d" % [actor.display_name, hero_target.display_name, dealt_e])
		action_resolved.emit(actor, hero_target)
		unit_updated.emit(actor)
		unit_updated.emit(hero_target)
	_check_end()


func _cast_ultimate(actor: BattleUnit) -> void:
	match actor.ultimate_id:
		"rulebreak":
			var target: BattleUnit = _pick_target(enemies)
			if target:
				var dealt: int = target.take_damage(int(actor.atk * 2.2))
				log_line.emit("%s: %s → %s (%d)" % [actor.display_name, actor.ultimate_name, target.display_name, dealt])
				unit_updated.emit(target)
		"emergency_repair":
			var lowest: BattleUnit = null
			for h in living("hero"):
				var hero_unit: BattleUnit = h
				if lowest == null or hero_unit.hp_ratio() < lowest.hp_ratio():
					lowest = hero_unit
			if lowest:
				var healed: int = lowest.heal(int(lowest.max_hp * 0.35))
				log_line.emit("%s: %s → %s (+%d)" % [actor.display_name, actor.ultimate_name, lowest.display_name, healed])
				unit_updated.emit(lowest)
		"paragraph_oblivion":
			for e in living("enemy"):
				var enemy_unit: BattleUnit = e
				var dealt: int = enemy_unit.take_damage(int(actor.atk * 0.85))
				enemy_unit.atb = maxf(0.0, enemy_unit.atb - 35.0)
				log_line.emit("%s: %s задевает %s (%d)" % [actor.display_name, actor.ultimate_name, enemy_unit.display_name, dealt])
				unit_updated.emit(enemy_unit)
		_:
			var fallback_target: BattleUnit = _pick_target(enemies)
			if fallback_target:
				var dealt2: int = fallback_target.take_damage(int(actor.atk * 1.8))
				log_line.emit("%s ультимейт → %s (%d)" % [actor.display_name, fallback_target.display_name, dealt2])
				unit_updated.emit(fallback_target)


func _compute_damage(attacker: BattleUnit, _defender: BattleUnit) -> int:
	var variance := _rng.randf_range(0.9, 1.1)
	return maxi(1, int(attacker.atk * variance))


func _pick_target(pool: Array) -> BattleUnit:
	var front: Array = []
	var any_alive: Array = []
	for u in pool:
		if u.alive:
			any_alive.append(u)
			if u.row == "front":
				front.append(u)
	var choices: Array = front if not front.is_empty() else any_alive
	if choices.is_empty():
		return null
	return choices[_rng.randi_range(0, choices.size() - 1)]


func _check_end() -> void:
	if living("enemy").is_empty():
		finished = true
		victory = true
		battle_ended.emit({"victory": true})
	elif living("hero").is_empty():
		finished = true
		victory = false
		battle_ended.emit({"victory": false})
