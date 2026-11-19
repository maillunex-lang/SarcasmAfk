package store

import (
	"crypto/rand"
	"encoding/binary"
	"sort"
)

// Owner-preliminary rates (editable via admin config later).
var StandardRates = map[string]float64{"N": 0.50, "R": 0.35, "SR": 0.12, "SSR": 0.03}
var AdvancedRates = map[string]float64{"R": 0.70, "SR": 0.24, "SSR": 0.05, "UR": 0.01}

const (
	PitySoftSREvery  = 10
	PityHardSSREvery = 80
	BannerStandard   = "BANNER_STANDARD"
	BannerAdvanced   = "BANNER_ADVANCED"
)

type GachaPullResult struct {
	HeroID     string `json:"hero_id"`
	Rarity     string `json:"rarity"`
	NewlyOwned bool   `json:"newly_owned"`
	PityForced string `json:"pity_forced,omitempty"` // "sr" | "ssr" | ""
}

type GachaHistoryEntry struct {
	BannerID   string `json:"banner_id"`
	HeroID     string `json:"hero_id"`
	Rarity     string `json:"rarity"`
	NewlyOwned bool   `json:"newly_owned"`
	At         string `json:"at"`
}

func cryptoFloat() float64 {
	var b [8]byte
	_, _ = rand.Read(b[:])
	// 53-bit mantissa style
	u := binary.LittleEndian.Uint64(b[:]) >> 11
	return float64(u) / (1 << 53)
}

func RollRarity(rates map[string]float64) string {
	type kv struct {
		k string
		v float64
	}
	var list []kv
	for k, v := range rates {
		list = append(list, kv{k, v})
	}
	sort.Slice(list, func(i, j int) bool { return list[i].k < list[j].k })
	r := cryptoFloat()
	acc := 0.0
	for _, e := range list {
		acc += e.v
		if r <= acc {
			return e.k
		}
	}
	return list[len(list)-1].k
}

func RarityRank(r string) int {
	switch r {
	case "N":
		return 1
	case "R":
		return 2
	case "SR":
		return 3
	case "SSR":
		return 4
	case "UR":
		return 5
	case "Mythic":
		return 6
	default:
		return 0
	}
}

func ApplyPity(rarity string, soft, hard int, softEvery, hardEvery int) (out string, forced string, newSoft, newHard int) {
	out = rarity
	newSoft, newHard = soft+1, hard+1
	forced = ""
	// Hard pity: guarantee SSR+ replaces result
	if hardEvery > 0 && newHard >= hardEvery {
		if RarityRank(out) < RarityRank("SSR") {
			out = "SSR"
			forced = "ssr"
		}
		newHard = 0
	} else if RarityRank(out) >= RarityRank("SSR") {
		newHard = 0
	}
	// Soft pity: guarantee SR+ replaces result
	if softEvery > 0 && newSoft >= softEvery {
		if RarityRank(out) < RarityRank("SR") {
			out = "SR"
			if forced == "" {
				forced = "sr"
			}
		}
		newSoft = 0
	} else if RarityRank(out) >= RarityRank("SR") {
		newSoft = 0
	}
	return out, forced, newSoft, newHard
}

func PickHeroByRarity(poolByRarity map[string][]string, rarity string) string {
	pool := poolByRarity[rarity]
	if len(pool) == 0 {
		// fallback down
		for _, r := range []string{"SSR", "SR", "R", "N", "UR"} {
			if len(poolByRarity[r]) > 0 {
				pool = poolByRarity[r]
				break
			}
		}
	}
	if len(pool) == 0 {
		return ""
	}
	return pool[CryptoPick(len(pool))]
}
