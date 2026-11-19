package battleverify

import "math/rand"

// EnemySkillSpec is loaded from enemy maps (optional fields).
type EnemySkillSpec struct {
	BasicKind   string
	BasicMul    float64
	SpecialKind string
	SpecialVal  float64
	SpecialCD   int
	ProcChance  float64
	Archetype   string
}

func skillFromMap(m map[string]any) EnemySkillSpec {
	s := EnemySkillSpec{
		BasicKind: "atk", BasicMul: 1.0,
		SpecialKind: "", SpecialVal: 0.25, SpecialCD: 3, ProcChance: 0.25,
	}
	if v, ok := m["basic"].(map[string]any); ok {
		if k, _ := v["kind"].(string); k != "" {
			s.BasicKind = k
		}
		if mul := asFloat(v["multiplier"]); mul > 0 {
			s.BasicMul = mul
		}
	}
	if v, ok := m["special"].(map[string]any); ok {
		if k, _ := v["kind"].(string); k != "" {
			s.SpecialKind = k
		}
		if val := asFloat(v["value"]); val > 0 {
			s.SpecialVal = val
		}
		if cd := asInt(v["cooldown_actions"]); cd > 0 {
			s.SpecialCD = cd
		}
		if p := asFloat(v["proc_chance"]); p > 0 {
			s.ProcChance = p
		}
	}
	if a, _ := m["archetype"].(string); a != "" {
		s.Archetype = a
	}
	return s
}

func asFloat(v any) float64 {
	switch n := v.(type) {
	case float64:
		return n
	case int:
		return float64(n)
	default:
		return 0
	}
}

func enemyAct(actor *unit, heroes, enemies []*unit, rng *rand.Rand, bal EnemyBalance) {
	applyBurnTicks(heroes, bal)
	applyBurnTicks(enemies, bal)

	// Boss phase one-shots
	if actor.skill.SpecialKind == "BOSS_E20" {
		bossE20(actor, heroes, enemies, rng, bal)
		actor.tickStatusesAfterAction()
		return
	}
	if actor.skill.SpecialKind == "BOSS_E30" {
		bossE30(actor, heroes, enemies, rng, bal)
		actor.tickStatusesAfterAction()
		return
	}

	useSpecial := false
	if actor.skill.SpecialKind != "" && actor.specialCD <= 0 {
		if rng.Float64() < actor.skill.ProcChance {
			useSpecial = true
		}
	}
	if useSpecial {
		castEnemySpecial(actor, heroes, enemies, rng, bal)
		actor.specialCD = actor.skill.SpecialCD
		if actor.specialCD <= 0 {
			actor.specialCD = bal.SpecialCooldown
		}
	} else {
		castEnemyBasic(actor, heroes, enemies, rng, bal)
		if actor.specialCD > 0 {
			actor.specialCD--
		}
	}
	actor.nextStrikeBonus = 0
	actor.tickStatusesAfterAction()
}

func castEnemyBasic(actor *unit, heroes, enemies []*unit, rng *rand.Rand, bal EnemyBalance) {
	mul := actor.skill.BasicMul
	if mul <= 0 {
		mul = 1.0
	}
	kind := actor.skill.BasicKind
	switch kind {
	case "GUARD_SELF":
		actor.addStatus(stGuard, 2, 0, actor.id)
		return
	case "atk_back":
		if t := pickBack(heroes, rng); t != nil {
			strike(actor, t, mul, rng, bal)
		}
	default: // atk / atk_front
		if t := pickTarget(heroes, rng); t != nil {
			strike(actor, t, mul, rng, bal)
		}
	}
}

func castEnemySpecial(actor *unit, heroes, enemies []*unit, rng *rand.Rand, bal EnemyBalance) {
	kind := actor.skill.SpecialKind
	val := actor.skill.SpecialVal
	switch kind {
	case "MARK":
		if t := pickTarget(heroes, rng); t != nil {
			t.addStatus(stMark, 2, 0, actor.id)
			strike(actor, t, 1.0, rng, bal)
		}
	case "SLOW", "SLOW_BACK":
		var t *unit
		if kind == "SLOW_BACK" {
			t = pickBack(heroes, rng)
		} else {
			t = pickTarget(heroes, rng)
		}
		if t != nil {
			t.addStatus(stSlow, 2, 0, actor.id)
			strike(actor, t, 1.0, rng, bal)
		}
	case "WEAKEN":
		if t := pickTarget(heroes, rng); t != nil {
			t.addStatus(stWeaken, 2, 0, actor.id)
			strike(actor, t, 1.0, rng, bal)
		}
	case "WEAKEN_TWO":
		for i := 0; i < 2; i++ {
			if t := pickTarget(heroes, rng); t != nil {
				t.addStatus(stWeaken, 2, 0, actor.id)
			}
		}
	case "SLOW_TWO":
		for i := 0; i < 2; i++ {
			if t := pickTarget(heroes, rng); t != nil {
				t.addStatus(stSlow, 2, 0, actor.id)
			}
		}
	case "BURN":
		if t := pickTarget(heroes, rng); t != nil {
			t.addStatus(stBurn, 2, 0, actor.id)
			strike(actor, t, 1.0, rng, bal)
		}
	case "DISRUPT", "DISRUPT_EMPOWER":
		if t := pickTarget(heroes, rng); t != nil {
			t.energy -= t.energyMax * bal.DisruptEnergyFrac
			if t.energy < 0 {
				t.energy = 0
			}
			strike(actor, t, 1.0, rng, bal)
		}
		if kind == "DISRUPT_EMPOWER" {
			actor.nextStrikeBonus = 0.15
		}
	case "SHIELD_SELF":
		hp := int(float64(actor.maxHP) * bal.ShieldMaxHPFrac)
		if val > 0 && val < 1 {
			hp = int(float64(actor.maxHP) * val)
		}
		actor.addStatus(stShield, 2, hp, actor.id)
	case "SHIELD_ALLY_LOWEST", "HEAL_ALLY_LOWEST":
		ally := lowestHP(enemies)
		if ally == nil {
			ally = actor
		}
		if kind == "HEAL_ALLY_LOWEST" {
			frac := bal.HealMaxHPFrac
			if val > 0 && val < 1 {
				frac = val
			}
			healUnit(ally, frac)
		} else {
			hp := int(float64(ally.maxHP) * bal.ShieldMaxHPFrac)
			ally.addStatus(stShield, 2, hp, actor.id)
		}
	case "SHIELD_ALLY_WEAKEN_FRONT":
		if ally := lowestHP(enemies); ally != nil {
			ally.addStatus(stShield, 2, int(float64(ally.maxHP)*bal.ShieldMaxHPFrac), actor.id)
		}
		if t := pickTarget(heroes, rng); t != nil {
			t.addStatus(stWeaken, 2, 0, actor.id)
		}
	case "ATK_WEAKEN":
		if t := pickTarget(heroes, rng); t != nil {
			strike(actor, t, 1.0, rng, bal)
			t.addStatus(stWeaken, 2, 0, actor.id)
		}
	case "MARK_THEN_STRIKE", "MARK_EMPOWER":
		if t := pickTarget(heroes, rng); t != nil {
			t.addStatus(stMark, 2, 0, actor.id)
			bonus := 0.0
			if kind == "MARK_EMPOWER" {
				bonus = 0.20
			}
			actor.nextStrikeBonus = bonus
			strike(actor, t, 1.15, rng, bal)
		}
	case "MARK_AND_SLOW_SPLIT":
		if t := pickTarget(heroes, rng); t != nil {
			t.addStatus(stMark, 2, 0, actor.id)
		}
		if t := pickBack(heroes, rng); t != nil {
			t.addStatus(stSlow, 2, 0, actor.id)
		}
	case "SHIELD_THEN_STRIKE":
		actor.addStatus(stShield, 2, int(float64(actor.maxHP)*bal.ShieldMaxHPFrac), actor.id)
		actor.nextStrikeBonus = 0.20
	case "MARK_DELAYED_STRIKE":
		if t := pickTarget(heroes, rng); t != nil {
			t.addStatus(stMark, 2, 0, actor.id)
			actor.pendingTarget = t.id
			actor.pendingMul = val
			if actor.pendingMul <= 0 {
				actor.pendingMul = 1.40
			}
			actor.pendingDelay = 1
		}
	case "SHIELD_E28_MARK":
		for _, e := range enemies {
			if e.alive && e.enemyType == "E28" {
				e.addStatus(stShield, 2, int(float64(e.maxHP)*bal.ShieldMaxHPFrac), actor.id)
			}
		}
		if t := pickTarget(heroes, rng); t != nil {
			t.addStatus(stMark, 2, 0, actor.id)
		}
	default:
		castEnemyBasic(actor, heroes, enemies, rng, bal)
	}
}

func strike(actor, target *unit, mul float64, rng *rand.Rand, bal EnemyBalance) {
	variance := 0.9 + rng.Float64()*0.2
	raw := int(float64(actor.effectiveATK(bal)) * mul * variance)
	if raw < 1 {
		raw = 1
	}
	takeDamageBalanced(target, raw, bal)
}

func resolvePending(actor *unit, heroes []*unit, rng *rand.Rand, bal EnemyBalance) {
	if actor.pendingDelay <= 0 || actor.pendingTarget == "" {
		return
	}
	actor.pendingDelay--
	if actor.pendingDelay > 0 {
		return
	}
	for _, h := range heroes {
		if h.alive && h.id == actor.pendingTarget {
			strike(actor, h, actor.pendingMul, rng, bal)
			break
		}
	}
	actor.pendingTarget = ""
	actor.pendingMul = 0
}

func bossE20(actor *unit, heroes, enemies []*unit, rng *rand.Rand, bal EnemyBalance) {
	// Phase trip once at 50%
	if !actor.phase2 && float64(actor.hp) <= float64(actor.maxHP)*0.50 {
		actor.phase2 = true
		actor.addStatus(stShield, 2, int(float64(actor.maxHP)*0.10), actor.id)
		if t := pickTarget(heroes, rng); t != nil {
			t.addStatus(stWeaken, 2, 0, actor.id)
		}
	}
	actor.actionCount++
	resolvePending(actor, heroes, rng, bal)
	// Every 3 actions: MARK then delayed 145%
	if actor.actionCount%3 == 0 {
		if t := pickTarget(heroes, rng); t != nil {
			t.addStatus(stMark, 2, 0, "telegraph")
			actor.pendingTarget = t.id
			actor.pendingMul = 1.45
			actor.pendingDelay = 1
		}
		return
	}
	if t := pickTarget(heroes, rng); t != nil {
		strike(actor, t, 1.20, rng, bal)
	}
}

func bossE30(actor *unit, heroes, enemies []*unit, rng *rand.Rand, bal EnemyBalance) {
	pct := float64(actor.hp) / float64(actor.maxHP)
	if !actor.phase2 && pct <= 0.65 {
		actor.phase2 = true
		actor.addStatus(stShield, 2, int(float64(actor.maxHP)*0.12), actor.id)
		if t := pickTarget(heroes, rng); t != nil {
			t.addStatus(stWeaken, 2, 0, actor.id)
		}
	}
	if !actor.phase3 && pct <= 0.30 {
		actor.phase3 = true
		actor.pendingMul = 1.60
		actor.pendingDelay = 1
		actor.pendingTarget = "__FRONT__"
	}
	actor.actionCount++
	if actor.pendingTarget == "__FRONT__" && actor.pendingDelay > 0 {
		actor.pendingDelay--
		if actor.pendingDelay == 0 {
			for _, h := range heroes {
				if h.alive && h.row == "front" {
					strike(actor, h, actor.pendingMul, rng, bal)
				}
			}
			// if no front, hit any
			if t := pickTarget(heroes, rng); t != nil && actor.pendingMul > 0 {
				// already hit fronts; clear
			}
			actor.pendingTarget = ""
			actor.pendingMul = 0
			return
		}
		return // telegraph wait
	}
	resolvePending(actor, heroes, rng, bal)
	if actor.actionCount%3 == 0 && pct > 0.65 {
		if t := pickTarget(heroes, rng); t != nil {
			t.addStatus(stMark, 2, 0, "telegraph")
			actor.pendingTarget = t.id
			actor.pendingMul = 1.50
			actor.pendingDelay = 1
		}
		return
	}
	if t := pickTarget(heroes, rng); t != nil {
		strike(actor, t, 1.30, rng, bal)
	}
}
