package battleverify

import "math/rand"

const (
	atbThreshold  = 100.0
	energyPerHit  = 22.0
	maxSimTicks   = 20000
	simDelta      = 0.05 // seconds per tick (~client autofight)
)

type unit struct {
	id, name, team, row string
	maxHP, hp, atk, def, speed int
	energy, energyMax, atb     float64
	ultimateID                 string
	alive                      bool
}

// SimResult is the outcome of a deterministic ATB autofight.
type SimResult struct {
	Victory bool   `json:"victory"`
	Ticks   int    `json:"ticks"`
	Seed    int64  `json:"seed"`
	Note    string `json:"note"`
}

// SimulateATB runs a seeded ATB sim mirroring client/scripts/battle/battle_engine.gd.
// Hero ultimates auto-cast when energy is full (server baseline; client may delay — see PHASE2_AUDIT).
func SimulateATB(seed int64, heroes, enemies []map[string]any) SimResult {
	rng := rand.New(rand.NewSource(seed))
	hs := make([]*unit, 0, len(heroes))
	for _, h := range heroes {
		hs = append(hs, unitFromMap(h, "hero", rng))
	}
	es := make([]*unit, 0, len(enemies))
	for _, e := range enemies {
		es = append(es, unitFromMap(e, "enemy", rng))
	}
	if len(hs) == 0 {
		return SimResult{Victory: false, Ticks: 0, Seed: seed, Note: "empty_party"}
	}
	if len(es) == 0 {
		return SimResult{Victory: true, Ticks: 0, Seed: seed, Note: "empty_enemies"}
	}

	for t := 1; t <= maxSimTicks; t++ {
		for _, u := range append(hs, es...) {
			if !u.alive {
				continue
			}
			u.atb += float64(u.speed) * 1.15 * simDelta
			if u.atb < atbThreshold {
				continue
			}
			u.atb = 0
			act(u, hs, es, rng)
			if !anyAlive(es) {
				return SimResult{Victory: true, Ticks: t, Seed: seed, Note: "atb_sim"}
			}
			if !anyAlive(hs) {
				return SimResult{Victory: false, Ticks: t, Seed: seed, Note: "atb_sim"}
			}
		}
	}
	// Timeout: treat as defeat (anti-stall).
	return SimResult{Victory: false, Ticks: maxSimTicks, Seed: seed, Note: "timeout"}
}

func unitFromMap(m map[string]any, team string, rng *rand.Rand) *unit {
	u := &unit{
		id:         asString(m["id"]),
		name:       asString(m["name"]),
		team:       team,
		row:        asString(m["row"]),
		maxHP:      asInt(m["hp"]),
		atk:        asInt(m["atk"]),
		def:        asInt(m["defense"]),
		speed:      asInt(m["speed"]),
		energyMax:  float64(asInt(m["energy_max"])),
		ultimateID: asString(m["ultimate_id"]),
		alive:      true,
	}
	if u.maxHP <= 0 {
		u.maxHP = 100
	}
	if u.atk <= 0 {
		u.atk = 10
	}
	if u.speed <= 0 {
		u.speed = 100
	}
	if u.row == "" {
		u.row = "front"
	}
	if u.energyMax <= 0 {
		u.energyMax = 100
	}
	u.hp = u.maxHP
	u.atb = rng.Float64() * 40.0
	return u
}

func act(actor *unit, heroes, enemies []*unit, rng *rand.Rand) {
	var pool []*unit
	if actor.team == "hero" {
		pool = enemies
	} else {
		pool = heroes
	}
	target := pickTarget(pool, rng)
	if target == nil {
		return
	}
	variance := 0.9 + rng.Float64()*0.2
	raw := int(float64(actor.atk) * variance)
	if raw < 1 {
		raw = 1
	}
	takeDamage(target, raw)
	if actor.team == "hero" {
		actor.energy += energyPerHit
		if actor.energy > actor.energyMax {
			actor.energy = actor.energyMax
		}
		if actor.energy >= actor.energyMax && actor.ultimateID != "" {
			castUltimate(actor, heroes, enemies, rng)
		}
	}
}

func castUltimate(actor *unit, heroes, enemies []*unit, rng *rand.Rand) {
	actor.energy = 0
	switch actor.ultimateID {
	case "rulebreak":
		if t := pickTarget(enemies, rng); t != nil {
			takeDamage(t, int(float64(actor.atk)*2.2))
		}
	case "emergency_repair":
		var lowest *unit
		for _, h := range heroes {
			if !h.alive {
				continue
			}
			if lowest == nil || float64(h.hp)/float64(h.maxHP) < float64(lowest.hp)/float64(lowest.maxHP) {
				lowest = h
			}
		}
		if lowest != nil {
			heal := int(float64(lowest.maxHP) * 0.35)
			lowest.hp += heal
			if lowest.hp > lowest.maxHP {
				lowest.hp = lowest.maxHP
			}
		}
	case "paragraph_oblivion":
		for _, e := range enemies {
			if !e.alive {
				continue
			}
			takeDamage(e, int(float64(actor.atk)*0.85))
			e.atb -= 35
			if e.atb < 0 {
				e.atb = 0
			}
		}
	default:
		if t := pickTarget(enemies, rng); t != nil {
			takeDamage(t, int(float64(actor.atk)*1.8))
		}
	}
}

func takeDamage(u *unit, raw int) {
	mitigated := raw - int(float64(u.def)*0.35)
	if mitigated < 1 {
		mitigated = 1
	}
	u.hp -= mitigated
	if u.hp <= 0 {
		u.hp = 0
		u.alive = false
		u.energy = 0
	}
}

func pickTarget(pool []*unit, rng *rand.Rand) *unit {
	var front, any []*unit
	for _, u := range pool {
		if !u.alive {
			continue
		}
		any = append(any, u)
		if u.row == "front" {
			front = append(front, u)
		}
	}
	choices := front
	if len(choices) == 0 {
		choices = any
	}
	if len(choices) == 0 {
		return nil
	}
	return choices[rng.Intn(len(choices))]
}

func anyAlive(pool []*unit) bool {
	for _, u := range pool {
		if u.alive {
			return true
		}
	}
	return false
}

func asString(v any) string {
	if s, ok := v.(string); ok {
		return s
	}
	return ""
}

// CheckFinishSim validates duration then uses ATB sim as source of truth for victory.
func CheckFinishSim(seed int64, durationMS int, heroes, enemies []map[string]any, clientVictory bool) (SimResult, string) {
	if durationMS < MinDurationMS {
		return SimResult{}, "BATTLE_TOO_FAST"
	}
	res := SimulateATB(seed, heroes, enemies)
	if clientVictory && !res.Victory {
		return res, "RESULT_MISMATCH"
	}
	return res, ""
}
