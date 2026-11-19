package store

import (
	"fmt"
	"time"
)

// SidequestState tracks one CH01 sidequest for an account.
type SidequestState struct {
	QuestID          string   `json:"quest_id"`
	State            string   `json:"state"` // locked|available|active|completed
	CompletedStepIDs []string `json:"completed_step_ids"`
	RewardClaimedAt  string   `json:"reward_claimed_at,omitempty"`
	StartedAt        string   `json:"started_at,omitempty"`
	UpdatedAt        string   `json:"updated_at,omitempty"`
	Version          int      `json:"version"`
	SequenceBuffer   []string `json:"sequence_buffer,omitempty"`
}

// POIProgress tracks interactive point state.
type POIProgress struct {
	POIID            string   `json:"poi_id"`
	State            string   `json:"state"` // locked|available|in_progress|completed
	CompletedActions []string `json:"completed_actions"`
	UpdatedAt        string   `json:"updated_at,omitempty"`
}

// ExpansionRewardBundle is the server view of ch01_expansion_rewards.json entry.
type ExpansionRewardBundle struct {
	BundleID        string
	Soft            int
	Inventory       map[string]int
	Equipment       []string
	PremiumCurrency int
}

// EquipmentDef is a catalog armor/weapon row.
type EquipmentDef struct {
	ItemID        string
	Slot          string
	Bonuses       map[string]int
	AccountUnique bool
}

func EnsureExpansion(acc *AccountProgress) {
	if acc.Sidequests == nil {
		acc.Sidequests = map[string]*SidequestState{}
	}
	if acc.POIProgress == nil {
		acc.POIProgress = map[string]*POIProgress{}
	}
	if acc.JournalFlags == nil {
		acc.JournalFlags = map[string]bool{}
	}
	if acc.ClaimedRewards == nil {
		acc.ClaimedRewards = map[string]bool{}
	}
	EnsureHeroInstances(acc)
}

func nowRFC3339() string {
	return time.Now().UTC().Format(time.RFC3339)
}

func hasStep(steps []string, id string) bool {
	for _, s := range steps {
		if s == id {
			return true
		}
	}
	return false
}

// ApplySidequestStart marks a sidequest active if prerequisites are met.
func ApplySidequestStart(acc *AccountProgress, questID string, requiredMainQuest string, hasMainFlag func(string) bool) error {
	EnsureExpansion(acc)
	if questID == "" {
		return ErrValidation
	}
	if requiredMainQuest != "" && !hasMainFlag(requiredMainQuest) && !acc.QuestFlags[requiredMainQuest] {
		return ErrValidation
	}
	st := acc.Sidequests[questID]
	if st == nil {
		st = &SidequestState{QuestID: questID, State: "available", CompletedStepIDs: []string{}, Version: 1}
		acc.Sidequests[questID] = st
	}
	if st.State == "completed" {
		return nil
	}
	st.State = "active"
	if st.StartedAt == "" {
		st.StartedAt = nowRFC3339()
	}
	st.UpdatedAt = nowRFC3339()
	st.Version++
	return nil
}

// ApplyPOIInteract records a POI action / sidequest step. For sequence puzzles, wrong order resets buffer only.
func ApplyPOIInteract(acc *AccountProgress, poiID, actionID, stepID, sidequestID string, sequence []string, completionFlag string, oneTime bool) (resetPuzzle bool, err error) {
	EnsureExpansion(acc)
	if poiID == "" || actionID == "" {
		return false, ErrValidation
	}
	poi := acc.POIProgress[poiID]
	if poi == nil {
		poi = &POIProgress{POIID: poiID, State: "available", CompletedActions: []string{}}
		acc.POIProgress[poiID] = poi
	}
	if oneTime && poi.State == "completed" {
		return false, nil
	}
	if hasStep(poi.CompletedActions, actionID) && stepID == "" {
		return false, nil
	}

	if len(sequence) > 0 && stepID != "" && sidequestID != "" {
		EnsureExpansion(acc)
		sq := acc.Sidequests[sidequestID]
		if sq == nil {
			sq = &SidequestState{QuestID: sidequestID, State: "active", CompletedStepIDs: []string{}, Version: 1, StartedAt: nowRFC3339()}
			acc.Sidequests[sidequestID] = sq
		}
		if sq.State == "completed" {
			return false, nil
		}
		expectIdx := len(sq.SequenceBuffer)
		if expectIdx >= len(sequence) {
			sq.SequenceBuffer = nil
			expectIdx = 0
		}
		if sequence[expectIdx] != stepID {
			sq.SequenceBuffer = nil
			sq.UpdatedAt = nowRFC3339()
			return true, nil
		}
		sq.SequenceBuffer = append(sq.SequenceBuffer, stepID)
		if !hasStep(sq.CompletedStepIDs, stepID) {
			sq.CompletedStepIDs = append(sq.CompletedStepIDs, stepID)
		}
		if len(sq.SequenceBuffer) == len(sequence) {
			sq.State = "completed"
			sq.SequenceBuffer = nil
		}
		sq.UpdatedAt = nowRFC3339()
		sq.Version++
	} else if stepID != "" && sidequestID != "" {
		sq := acc.Sidequests[sidequestID]
		if sq == nil {
			sq = &SidequestState{QuestID: sidequestID, State: "active", CompletedStepIDs: []string{}, Version: 1, StartedAt: nowRFC3339()}
			acc.Sidequests[sidequestID] = sq
		}
		if sq.State != "completed" && !hasStep(sq.CompletedStepIDs, stepID) {
			sq.CompletedStepIDs = append(sq.CompletedStepIDs, stepID)
			sq.State = "active"
			sq.UpdatedAt = nowRFC3339()
			sq.Version++
		}
	}

	if !hasStep(poi.CompletedActions, actionID) {
		poi.CompletedActions = append(poi.CompletedActions, actionID)
	}
	poi.State = "in_progress"
	if oneTime {
		poi.State = "completed"
	}
	poi.UpdatedAt = nowRFC3339()
	if completionFlag != "" {
		acc.JournalFlags[completionFlag] = true
		acc.QuestFlags[completionFlag] = true
	}
	return false, nil
}

// ApplySidequestClaim grants a bundle once when all required steps are done.
func ApplySidequestClaim(acc *AccountProgress, questID string, requiredSteps []string, bundle ExpansionRewardBundle, equipmentDefs map[string]EquipmentDef) (already bool, granted map[string]any, err error) {
	EnsureExpansion(acc)
	if questID == "" || bundle.BundleID == "" {
		return false, nil, ErrValidation
	}
	if acc.ClaimedRewards[bundle.BundleID] {
		return true, map[string]any{}, nil
	}
	sq := acc.Sidequests[questID]
	if sq == nil {
		return false, nil, ErrValidation
	}
	for _, step := range requiredSteps {
		if !hasStep(sq.CompletedStepIDs, step) {
			return false, nil, fmt.Errorf("%w: incomplete steps", ErrValidation)
		}
	}
	if bundle.PremiumCurrency != 0 {
		return false, nil, ErrValidation
	}
	granted = map[string]any{}
	if bundle.Soft > 0 {
		acc.SoftCurrency += bundle.Soft
		granted["soft"] = bundle.Soft
	}
	invGranted := map[string]int{}
	for k, v := range bundle.Inventory {
		if v <= 0 {
			continue
		}
		acc.Inventory[k] += v
		invGranted[k] = v
	}
	if len(invGranted) > 0 {
		granted["inventory"] = invGranted
	}
	eqGranted := []string{}
	for _, itemID := range bundle.Equipment {
		def, ok := equipmentDefs[itemID]
		if !ok {
			return false, nil, ErrNotFound
		}
		if def.AccountUnique && acc.Inventory[itemID] > 0 {
			continue
		}
		acc.Inventory[itemID]++
		eqGranted = append(eqGranted, itemID)
	}
	if len(eqGranted) > 0 {
		granted["equipment"] = eqGranted
	}
	acc.ClaimedRewards[bundle.BundleID] = true
	sq.State = "completed"
	sq.RewardClaimedAt = nowRFC3339()
	sq.UpdatedAt = nowRFC3339()
	sq.Version++
	return false, granted, nil
}

const (
	SkillSoftCostBase   = 200
	SkillSoftCostGrowth = 50
	SkillMaxLevelDraft  = 10
)

// ApplySkillUp spends soft and increments a skill level.
func ApplySkillUp(acc *AccountProgress, heroID, skillID string, base HeroBaseStats, gearBonus map[string]int) (*HeroInstance, error) {
	EnsureExpansion(acc)
	if heroID == "" || skillID == "" {
		return nil, ErrValidation
	}
	if !acc.OwnedHeroes[heroID] {
		return nil, ErrNotOwned
	}
	inst := acc.HeroInstances[heroID]
	if inst == nil {
		return nil, ErrNotOwned
	}
	if inst.SkillLevels == nil {
		inst.SkillLevels = map[string]int{"basic": 1, "ultimate": 1, "passive": 1}
	}
	cur := inst.SkillLevels[skillID]
	if cur <= 0 {
		cur = 1
		inst.SkillLevels[skillID] = cur
	}
	if cur >= SkillMaxLevelDraft {
		return nil, ErrLevelCap
	}
	cost := SkillSoftCostBase + cur*SkillSoftCostGrowth
	if acc.SoftCurrency < cost {
		return nil, ErrInsufficient
	}
	acc.SoftCurrency -= cost
	inst.SkillLevels[skillID] = cur + 1
	inst.Power = ComputePowerWithGear(base, inst, gearBonus)
	cp := *inst
	return &cp, nil
}

// ApplyEquipUnique equips an item, returns previous to inventory, enforces one instance per account across heroes.
func ApplyEquipUnique(acc *AccountProgress, heroID, slot, itemID string, base HeroBaseStats, defs map[string]EquipmentDef) (*HeroInstance, error) {
	EnsureExpansion(acc)
	valid := map[string]bool{"weapon": true, "armor": true, "accessory": true, "relic": true}
	if heroID == "" || !valid[slot] {
		return nil, ErrValidation
	}
	if !acc.OwnedHeroes[heroID] {
		return nil, ErrNotOwned
	}
	inst := acc.HeroInstances[heroID]
	if inst == nil {
		inst = NewHeroInstance(heroID)
		acc.HeroInstances[heroID] = inst
	}
	if inst.Equipment == nil {
		inst.Equipment = map[string]string{}
	}
	starters := map[string]bool{"starter_blade": true, "starter_mail": true, "starter_charm": true}
	if itemID != "" {
		def, ok := defs[itemID]
		if ok && def.Slot != "" && def.Slot != slot {
			return nil, ErrValidation
		}
		if !starters[itemID] && acc.Inventory[itemID] <= 0 {
			// allow re-equip if already on this hero in another slot? no — must be in inventory or currently equipped somewhere we'll steal
			equippedElsewhere := false
			for hid, other := range acc.HeroInstances {
				if other == nil || other.Equipment == nil {
					continue
				}
				for s, eq := range other.Equipment {
					if eq == itemID {
						other.Equipment[s] = ""
						equippedElsewhere = true
						_ = hid
					}
				}
			}
			if !equippedElsewhere {
				return nil, ErrInsufficient
			}
		} else if !starters[itemID] {
			acc.Inventory[itemID]--
		}
		if ok && def.AccountUnique {
			for hid, other := range acc.HeroInstances {
				if hid == heroID || other == nil || other.Equipment == nil {
					continue
				}
				for s, eq := range other.Equipment {
					if eq == itemID {
						other.Equipment[s] = ""
					}
				}
			}
		}
	}
	prev := inst.Equipment[slot]
	if prev != "" && prev != itemID && !starters[prev] {
		acc.Inventory[prev]++
	}
	inst.Equipment[slot] = itemID
	bonus := GearBonusForHero(inst, defs)
	inst.Power = ComputePowerWithGear(base, inst, bonus)
	cp := *inst
	return &cp, nil
}

func GearBonusForHero(inst *HeroInstance, defs map[string]EquipmentDef) map[string]int {
	out := map[string]int{}
	if inst == nil || inst.Equipment == nil {
		return out
	}
	for _, itemID := range inst.Equipment {
		if itemID == "" {
			continue
		}
		def, ok := defs[itemID]
		if !ok {
			continue
		}
		for k, v := range def.Bonuses {
			out[k] += v
		}
	}
	return out
}

func ComputePowerWithGear(base HeroBaseStats, inst *HeroInstance, gear map[string]int) int {
	hp := base.HP + gear["hp"]
	atk := base.Atk + gear["atk"]
	def := base.Defense + gear["def"] + gear["defense"]
	spd := base.Speed + gear["speed"]
	skillBonus := 0
	if inst != nil && inst.SkillLevels != nil {
		for _, lv := range inst.SkillLevels {
			if lv > 1 {
				skillBonus += (lv - 1) * 3
			}
		}
	}
	return ComputePower(hp, atk, def, spd, inst.Level, inst.Stars, inst.AwakenRank) + skillBonus
}

// EffectiveCombatStats returns stats used by battle sim seeding/checks.
func EffectiveCombatStats(base HeroBaseStats, inst *HeroInstance, defs map[string]EquipmentDef) (hp, atk, def, spd int) {
	bonus := GearBonusForHero(inst, defs)
	hp = base.HP + bonus["hp"]
	atk = base.Atk + bonus["atk"]
	def = base.Defense + bonus["def"] + bonus["defense"]
	spd = base.Speed + bonus["speed"]
	lvlMul := 1.0 + LevelStatBonusDraft*float64(max(0, inst.Level-1))
	hp = int(float64(hp) * lvlMul)
	atk = int(float64(atk) * lvlMul)
	def = int(float64(def) * lvlMul)
	spd = int(float64(spd) * lvlMul)
	if inst.SkillLevels != nil {
		ult := inst.SkillLevels["ultimate"]
		if ult > 1 {
			atk += (ult - 1) * 8
		}
		basic := inst.SkillLevels["basic"]
		if basic > 1 {
			atk += (basic - 1) * 4
		}
	}
	return
}
