package battleverify

import "math"

const MinDurationMS = 300

// Power sums crude combat power from unit maps that carry hp/atk/defense.
func PowerFromUnits(units []map[string]any) int {
	total := 0
	for _, u := range units {
		hp := asInt(u["hp"])
		atk := asInt(u["atk"])
		def := asInt(u["defense"])
		total += hp/10 + atk*2 + def
	}
	return total
}

func PowerFromHeroIDs(party []string, heroes map[string]any) int {
	units := make([]map[string]any, 0, len(party))
	for _, id := range party {
		if h, ok := heroes[id].(map[string]any); ok {
			units = append(units, h)
		} else {
			// unknown hero: modest default so empty party fails
			units = append(units, map[string]any{"hp": 800, "atk": 100, "defense": 50})
		}
	}
	return PowerFromUnits(units)
}

// EstimateVictory is a deterministic soft sim: party vs enemies with seed jitter.
// Full tick sim remains future work; this rejects obvious false claims.
func EstimateVictory(seed int64, partyPower, enemyPower int) bool {
	if enemyPower <= 0 {
		return true
	}
	if partyPower <= 0 {
		return false
	}
	jitter := float64((seed%21)-10) / 100.0 // -0.10 .. +0.10
	score := float64(partyPower) * (1.0 + jitter)
	threshold := float64(enemyPower) * 0.85
	return score >= threshold
}

// CheckFinish validates duration and optional result mismatch.
// Returns (serverVictory, errorCode). errorCode empty means OK.
func CheckFinish(seed int64, durationMS, partyPower, enemyPower int, clientVictory bool) (serverVictory bool, errCode string) {
	if durationMS < MinDurationMS {
		return false, "BATTLE_TOO_FAST"
	}
	serverVictory = EstimateVictory(seed, partyPower, enemyPower)
	// Client may claim defeat freely; claiming victory when server says lose is rejected.
	if clientVictory && !serverVictory {
		return serverVictory, "RESULT_MISMATCH"
	}
	if clientVictory {
		return true, ""
	}
	return serverVictory, ""
}

func asInt(v any) int {
	switch t := v.(type) {
	case int:
		return t
	case int64:
		return int(t)
	case float64:
		return int(math.Round(t))
	default:
		return 0
	}
}

// AsIntPublic exposes asInt for HTTP reward parsing.
func AsIntPublic(v any) int { return asInt(v) }
