package store

import (
	"crypto/rand"
	"encoding/binary"
	"math"
)

// Draft progression knobs (mirror client/data/progression/progression_draft.json).
// Owner must approve before treating as live balance.
const (
	MaxStarsDraft          = 6
	MaxAwakenDraft         = 4
	LevelSoftCostBase      = 100
	LevelSoftCostPerLevel  = 25
	MaxLevelBaseDraft      = 60
	StarStatBonusDraft     = 0.08
	AwakenStatBonusDraft   = 0.05
	LevelStatBonusDraft    = 0.02
	PowerHPDraft           = 0.15
	PowerAtkDraft          = 1.2
	PowerDefDraft          = 0.9
	PowerSpdDraft          = 0.5
	DuplicateSoftRefund    = 50
	StartingSoftDraft      = 5000
)

var FragmentsPerStarDraft = []int{10, 20, 40, 80, 120, 200}
var MaxLevelPerAwakenDraft = []int{60, 70, 80, 90, 100}

func EnsureHeroInstances(acc *AccountProgress) {
	if acc.HeroInstances == nil {
		acc.HeroInstances = map[string]*HeroInstance{}
	}
	if acc.Inventory == nil {
		acc.Inventory = map[string]int{}
	}
	if acc.PityCounters == nil {
		acc.PityCounters = map[string]int{}
	}
	if acc.OwnedHeroes == nil {
		acc.OwnedHeroes = map[string]bool{}
	}
	for id, owned := range acc.OwnedHeroes {
		if !owned {
			continue
		}
		if _, ok := acc.HeroInstances[id]; !ok {
			acc.HeroInstances[id] = NewHeroInstance(id)
		}
	}
}

func NewHeroInstance(catalogID string) *HeroInstance {
	return &HeroInstance{
		CatalogID:   catalogID,
		Level:       1,
		Stars:       0,
		AwakenRank:  0,
		Fragments:   0,
		SkillLevels: map[string]int{"basic": 1, "ultimate": 1, "passive": 1},
		Equipment:   map[string]string{"weapon": "", "armor": "", "accessory": "", "relic": ""},
		Power:       0,
	}
}

func LevelCap(awaken int) int {
	if awaken < 0 {
		awaken = 0
	}
	if awaken >= len(MaxLevelPerAwakenDraft) {
		return MaxLevelPerAwakenDraft[len(MaxLevelPerAwakenDraft)-1]
	}
	return MaxLevelPerAwakenDraft[awaken]
}

func SoftCostForLevel(currentLevel int) int {
	return LevelSoftCostBase + currentLevel*LevelSoftCostPerLevel
}

func ComputePower(baseHP, baseAtk, baseDef, baseSpd, level, stars, awaken int) int {
	lvlMul := 1.0 + LevelStatBonusDraft*float64(max(0, level-1))
	starMul := 1.0 + StarStatBonusDraft*float64(stars)
	awkMul := 1.0 + AwakenStatBonusDraft*float64(awaken)
	raw := (float64(baseHP)*PowerHPDraft + float64(baseAtk)*PowerAtkDraft +
		float64(baseDef)*PowerDefDraft + float64(baseSpd)*PowerSpdDraft) * lvlMul * starMul * awkMul
	return int(math.Floor(raw))
}

func CryptoPick(n int) int {
	if n <= 0 {
		return 0
	}
	var b [8]byte
	_, _ = rand.Read(b[:])
	v := binary.LittleEndian.Uint64(b[:])
	return int(v % uint64(n))
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
