package store

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"time"
)

var (
	ErrUnauthorized   = errors.New("UNAUTHENTICATED")
	ErrAlreadyClaimed = errors.New("ALREADY_CLAIMED")
	ErrNotFound       = errors.New("NOT_FOUND")
	ErrInvalidParty   = errors.New("INVALID_PARTY")
	ErrValidation     = errors.New("VALIDATION_FAILED")
	ErrNoTickets      = errors.New("NO_TICKETS")
	ErrNoActiveBattle = errors.New("NO_ACTIVE_BATTLE")
	ErrNotOwned       = errors.New("HERO_NOT_OWNED")
	ErrInsufficient   = errors.New("INSUFFICIENT_RESOURCES")
	ErrLevelCap       = errors.New("LEVEL_CAP")
	ErrStarCap        = errors.New("STAR_CAP")
)

const AFKMaxHours = 24

type Memory struct {
	mu       sync.RWMutex
	accounts map[string]*AccountProgress
	sessions map[string]*Session
	persist  string
}

func NewMemory(persistPath string) *Memory {
	m := &Memory{
		accounts: map[string]*AccountProgress{},
		sessions: map[string]*Session{},
		persist:  persistPath,
	}
	_ = m.load()
	return m
}

type persistDump struct {
	Accounts map[string]*AccountProgress `json:"accounts"`
	Sessions map[string]*Session         `json:"sessions"`
}

func (m *Memory) load() error {
	if m.persist == "" {
		return nil
	}
	b, err := os.ReadFile(m.persist)
	if err != nil {
		return err
	}
	var dump persistDump
	if err := json.Unmarshal(b, &dump); err != nil {
		return err
	}
	if dump.Accounts != nil {
		m.accounts = dump.Accounts
	}
	if dump.Sessions != nil {
		m.sessions = dump.Sessions
	}
	return nil
}

func (m *Memory) save() {
	if m.persist == "" {
		return
	}
	_ = os.MkdirAll(filepath.Dir(m.persist), 0o755)
	dump := persistDump{Accounts: m.accounts, Sessions: m.sessions}
	b, err := json.MarshalIndent(dump, "", "  ")
	if err != nil {
		return
	}
	_ = os.WriteFile(m.persist, b, 0o644)
}

func newID(prefix string) string {
	var b [8]byte
	_, _ = rand.Read(b[:])
	return prefix + hex.EncodeToString(b[:])
}

func (m *Memory) CreateAnonymous() (token string, progress AccountProgress) {
	m.mu.Lock()
	defer m.mu.Unlock()
	acc := &AccountProgress{
		AccountID:     newID("acc_"),
		CommanderXP:   0,
		SoftCurrency:  StartingSoftDraft,
		HardCurrency:  0,
		SummonTickets: 10,
		PartyIDs:      []string{"H01", "H04", "H02", "H03", "H07"},
		QuestFlags:    map[string]bool{},
		ClaimedRewards: map[string]bool{},
		OwnedHeroes: map[string]bool{
			"H01": true, "H02": true, "H03": true, "H04": true, "H07": true,
		},
		HeroInstances:  map[string]*HeroInstance{},
		Inventory:      map[string]int{"mat_hero_exp": 500},
		PityCounters:   map[string]int{},
		Sidequests:     map[string]*SidequestState{},
		POIProgress:    map[string]*POIProgress{},
		JournalFlags:   map[string]bool{},
		AFKClaimedUnix: time.Now().Unix(),
		UpdatedAt:      time.Now().UTC().Format(time.RFC3339),
	}
	EnsureHeroInstances(acc)
	EnsureExpansion(acc)
	tok := newID("tok_")
	m.accounts[acc.AccountID] = acc
	m.sessions[tok] = &Session{Token: tok, AccountID: acc.AccountID, CreatedAt: time.Now()}
	m.save()
	return tok, *acc
}

func (m *Memory) AccountByToken(token string) (*AccountProgress, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	s, ok := m.sessions[token]
	if !ok {
		return nil, ErrUnauthorized
	}
	acc, ok := m.accounts[s.AccountID]
	if !ok {
		return nil, ErrUnauthorized
	}
	EnsureHeroInstances(acc)
	cp := *acc
	return &cp, nil
}

func (m *Memory) mutate(token string, fn func(*AccountProgress) error) (*AccountProgress, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	s, ok := m.sessions[token]
	if !ok {
		return nil, ErrUnauthorized
	}
	acc, ok := m.accounts[s.AccountID]
	if !ok {
		return nil, ErrUnauthorized
	}
	if err := fn(acc); err != nil {
		return nil, err
	}
	acc.UpdatedAt = time.Now().UTC().Format(time.RFC3339)
	m.save()
	cp := *acc
	return &cp, nil
}

func (m *Memory) SetParty(token string, party []string) (*AccountProgress, error) {
	if len(party) == 0 || len(party) > 5 {
		return nil, ErrInvalidParty
	}
	seen := map[string]bool{}
	for _, id := range party {
		if id == "" || seen[id] {
			return nil, ErrInvalidParty
		}
		seen[id] = true
	}
	return m.mutate(token, func(acc *AccountProgress) error {
		for _, id := range party {
			if !acc.OwnedHeroes[id] {
				return ErrInvalidParty
			}
		}
		acc.PartyIDs = append([]string{}, party...)
		return nil
	})
}

func (m *Memory) ClaimReward(token, bundleID string, soft, xp int) (softDelta, xpDelta int, already bool, err error) {
	_, err = m.mutate(token, func(acc *AccountProgress) error {
		if bundleID == "" {
			return ErrValidation
		}
		if acc.ClaimedRewards[bundleID] {
			already = true
			softDelta, xpDelta = 0, 0
			return nil
		}
		acc.ClaimedRewards[bundleID] = true
		acc.SoftCurrency += soft
		acc.CommanderXP += xp
		softDelta, xpDelta = soft, xp
		already = false
		return nil
	})
	return
}

func (m *Memory) ClaimAFK(token string, softPerHour, xpPerHour int) (hours float64, soft, xp int, err error) {
	_, err = m.mutate(token, func(acc *AccountProgress) error {
		now := time.Now().Unix()
		elapsed := float64(now - acc.AFKClaimedUnix)
		if elapsed < 0 {
			elapsed = 0
		}
		hours = elapsed / 3600.0
		if hours > AFKMaxHours {
			hours = AFKMaxHours
		}
		soft = int(float64(softPerHour) * hours)
		xp = int(float64(xpPerHour) * hours)
		if soft <= 0 && xp <= 0 {
			return ErrValidation
		}
		acc.SoftCurrency += soft
		acc.CommanderXP += xp
		acc.AFKClaimedUnix = now
		return nil
	})
	return
}

func (m *Memory) Summon(token string, heroPool []string) (heroID string, newly bool, err error) {
	if len(heroPool) == 0 {
		return "", false, ErrValidation
	}
	_, err = m.mutate(token, func(acc *AccountProgress) error {
		if acc.SummonTickets <= 0 {
			return ErrNoTickets
		}
		acc.SummonTickets--
		idx := CryptoPick(len(heroPool))
		heroID = heroPool[idx]
		EnsureHeroInstances(acc)
		newly = !acc.OwnedHeroes[heroID]
		acc.OwnedHeroes[heroID] = true
		if newly {
			acc.HeroInstances[heroID] = NewHeroInstance(heroID)
		} else {
			inst := acc.HeroInstances[heroID]
			if inst == nil {
				inst = NewHeroInstance(heroID)
				acc.HeroInstances[heroID] = inst
			}
			inst.Fragments++
			acc.SoftCurrency += DuplicateSoftRefund
		}
		return nil
	})
	return
}

func (m *Memory) StartBattle(token, battleID string, party []string) (seed int64, err error) {
	_, err = m.mutate(token, func(acc *AccountProgress) error {
		if battleID == "" {
			return ErrValidation
		}
		if len(party) > 0 {
			for _, id := range party {
				if !acc.OwnedHeroes[id] {
					return ErrInvalidParty
				}
			}
			acc.PartyIDs = append([]string{}, party...)
		}
		seed = time.Now().UnixNano()
		acc.ActiveBattleID = battleID
		acc.BattleSeed = seed
		acc.BalanceVersion = "2026.11.19-atb1"
		acc.BattleCommands = nil
		acc.BattleTickApprox = 0
		return nil
	})
	return
}

func (m *Memory) AppendBattleCommand(token, battleID string, cmd BattleCommand) (*AccountProgress, error) {
	if cmd.Op != "ultimate" || cmd.UnitID == "" {
		return nil, ErrValidation
	}
	return m.mutate(token, func(acc *AccountProgress) error {
		if acc.ActiveBattleID == "" || acc.ActiveBattleID != battleID {
			return ErrNoActiveBattle
		}
		owned := false
		for _, id := range acc.PartyIDs {
			if id == cmd.UnitID {
				owned = true
				break
			}
		}
		if !owned {
			return ErrInvalidParty
		}
		if cmd.AtTick <= 0 {
			acc.BattleTickApprox++
			cmd.AtTick = acc.BattleTickApprox * 20 // coarse client tick estimate
		} else if cmd.AtTick > acc.BattleTickApprox {
			acc.BattleTickApprox = cmd.AtTick
		}
		acc.BattleCommands = append(acc.BattleCommands, cmd)
		return nil
	})
}

func (m *Memory) FinishBattle(token, battleID string, victory bool) (*AccountProgress, error) {
	return m.mutate(token, func(acc *AccountProgress) error {
		if battleID == "" {
			return ErrValidation
		}
		// Must have started this battle; blind finish rejected (T-088).
		if acc.ActiveBattleID == "" || acc.ActiveBattleID != battleID {
			return ErrNoActiveBattle
		}
		if victory {
			acc.QuestFlags["battle:"+battleID] = true
		}
		acc.ActiveBattleID = ""
		acc.BattleSeed = 0
		acc.BalanceVersion = ""
		acc.BattleCommands = nil
		acc.BattleTickApprox = 0
		return nil
	})
}

func (m *Memory) LevelUpHero(token, heroID string, levels int, base HeroBaseStats) (*AccountProgress, *HeroInstance, error) {
	if heroID == "" || levels < 1 || levels > 10 {
		return nil, nil, ErrValidation
	}
	var out *HeroInstance
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		EnsureHeroInstances(acc)
		if !acc.OwnedHeroes[heroID] {
			return ErrNotOwned
		}
		inst := acc.HeroInstances[heroID]
		if inst == nil {
			inst = NewHeroInstance(heroID)
			acc.HeroInstances[heroID] = inst
		}
		cap := LevelCap(inst.AwakenRank)
		for i := 0; i < levels; i++ {
			if inst.Level >= cap {
				return ErrLevelCap
			}
			cost := SoftCostForLevel(inst.Level)
			if acc.SoftCurrency < cost {
				return ErrInsufficient
			}
			acc.SoftCurrency -= cost
			inst.Level++
		}
		inst.Power = ComputePower(base.HP, base.Atk, base.Defense, base.Speed, inst.Level, inst.Stars, inst.AwakenRank)
		cp := *inst
		out = &cp
		return nil
	})
	return prog, out, err
}

func (m *Memory) StarUpHero(token, heroID string, base HeroBaseStats) (*AccountProgress, *HeroInstance, error) {
	if heroID == "" {
		return nil, nil, ErrValidation
	}
	var out *HeroInstance
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		EnsureHeroInstances(acc)
		if !acc.OwnedHeroes[heroID] {
			return ErrNotOwned
		}
		inst := acc.HeroInstances[heroID]
		if inst == nil {
			return ErrNotOwned
		}
		if inst.Stars >= MaxStarsDraft {
			return ErrStarCap
		}
		need := FragmentsPerStarDraft[inst.Stars]
		if inst.Fragments < need {
			return ErrInsufficient
		}
		inst.Fragments -= need
		inst.Stars++
		inst.Power = ComputePower(base.HP, base.Atk, base.Defense, base.Speed, inst.Level, inst.Stars, inst.AwakenRank)
		cp := *inst
		out = &cp
		return nil
	})
	return prog, out, err
}

func (m *Memory) EquipHero(token, heroID, slot, itemID string, base HeroBaseStats) (*AccountProgress, *HeroInstance, error) {
	valid := map[string]bool{"weapon": true, "armor": true, "accessory": true, "relic": true}
	if heroID == "" || !valid[slot] {
		return nil, nil, ErrValidation
	}
	var out *HeroInstance
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		EnsureHeroInstances(acc)
		if !acc.OwnedHeroes[heroID] {
			return ErrNotOwned
		}
		inst := acc.HeroInstances[heroID]
		if inst == nil {
			inst = NewHeroInstance(heroID)
			acc.HeroInstances[heroID] = inst
		}
		if inst.Equipment == nil {
			inst.Equipment = map[string]string{}
		}
		if itemID != "" {
			if acc.Inventory[itemID] <= 0 && itemID != "starter_blade" && itemID != "starter_mail" && itemID != "starter_charm" {
				return ErrInsufficient
			}
		}
		inst.Equipment[slot] = itemID
		inst.Power = ComputePower(base.HP, base.Atk, base.Defense, base.Speed, inst.Level, inst.Stars, inst.AwakenRank)
		cp := *inst
		out = &cp
		return nil
	})
	return prog, out, err
}

func (m *Memory) SpendSoft(token string, amount int) (*AccountProgress, error) {
	if amount < 0 {
		return nil, ErrValidation
	}
	return m.mutate(token, func(acc *AccountProgress) error {
		if acc.SoftCurrency < amount {
			return ErrInsufficient
		}
		acc.SoftCurrency -= amount
		return nil
	})
}

func (m *Memory) ApplySimulatedPurchase(token, sku string, soft, hard, tickets int, inventory map[string]int) (*AccountProgress, bool, error) {
	if sku == "" {
		return nil, false, ErrValidation
	}
	already := false
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		key := "shop_sim:" + sku
		if acc.ClaimedRewards[key] {
			already = true
			return nil
		}
		acc.ClaimedRewards[key] = true
		acc.SoftCurrency += soft
		acc.HardCurrency += hard
		acc.SummonTickets += tickets
		EnsureHeroInstances(acc)
		for k, v := range inventory {
			acc.Inventory[k] += v
		}
		return nil
	})
	return prog, already, err
}

func (m *Memory) SummonBanner(token, bannerID string, count int, poolByRarity map[string][]string) (*AccountProgress, []GachaPullResult, error) {
	if count != 1 && count != 10 {
		return nil, nil, ErrValidation
	}
	rates := StandardRates
	softEvery, hardEvery := 0, 0
	pityKey := ""
	switch bannerID {
	case BannerStandard:
		rates = StandardRates
	case BannerAdvanced:
		rates = AdvancedRates
		softEvery, hardEvery = PitySoftSREvery, PityHardSSREvery
		pityKey = "advanced"
	default:
		return nil, nil, ErrValidation
	}
	var results []GachaPullResult
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		need := count
		if acc.SummonTickets < need {
			return ErrNoTickets
		}
		acc.SummonTickets -= need
		EnsureHeroInstances(acc)
		if acc.PityCounters == nil {
			acc.PityCounters = map[string]int{}
		}
		soft := acc.PityCounters[pityKey+"_soft"]
		hard := acc.PityCounters[pityKey+"_hard"]
		for i := 0; i < count; i++ {
			rarity := RollRarity(rates)
			forced := ""
			if pityKey != "" {
				rarity, forced, soft, hard = ApplyPity(rarity, soft, hard, softEvery, hardEvery)
			}
			heroID := PickHeroByRarity(poolByRarity, rarity)
			if heroID == "" {
				return ErrValidation
			}
			newly := !acc.OwnedHeroes[heroID]
			acc.OwnedHeroes[heroID] = true
			if newly {
				acc.HeroInstances[heroID] = NewHeroInstance(heroID)
			} else {
				inst := acc.HeroInstances[heroID]
				if inst == nil {
					inst = NewHeroInstance(heroID)
					acc.HeroInstances[heroID] = inst
				}
				inst.Fragments++
				acc.SoftCurrency += DuplicateSoftRefund
			}
			results = append(results, GachaPullResult{HeroID: heroID, Rarity: rarity, NewlyOwned: newly, PityForced: forced})
			acc.GachaHistory = append(acc.GachaHistory, GachaHistoryEntry{
				BannerID: bannerID, HeroID: heroID, Rarity: rarity, NewlyOwned: newly, At: time.Now().UTC().Format(time.RFC3339),
			})
			if len(acc.GachaHistory) > 100 {
				acc.GachaHistory = acc.GachaHistory[len(acc.GachaHistory)-100:]
			}
		}
		if pityKey != "" {
			acc.PityCounters[pityKey+"_soft"] = soft
			acc.PityCounters[pityKey+"_hard"] = hard
		}
		return nil
	})
	return prog, results, err
}

const (
	TestMaxPurchasesPerDay = 10
	TestMaxHardPerDay      = 500
	TestMaxVipPerDay       = 200
)

func (m *Memory) TestPurchase(token, sku string, soft, hard, tickets, vipPoints int, inventory map[string]int) (*AccountProgress, map[string]any, error) {
	if sku == "" {
		return nil, nil, ErrValidation
	}
	meta := map[string]any{}
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		day := time.Now().UTC().Format("2006-01-02")
		if acc.TestPurchaseDay != day {
			acc.TestPurchaseDay = day
			acc.TestPurchasesDay = 0
			acc.TestHardDay = 0
			acc.TestVipDay = 0
		}
		if acc.TestPurchasesDay >= TestMaxPurchasesPerDay {
			return ErrInsufficient
		}
		if acc.TestHardDay+hard > TestMaxHardPerDay {
			return ErrInsufficient
		}
		if acc.TestVipDay+vipPoints > TestMaxVipPerDay {
			return ErrInsufficient
		}
		acc.TestPurchasesDay++
		acc.TestHardDay += hard
		acc.TestVipDay += vipPoints
		acc.SoftCurrency += soft
		acc.HardCurrency += hard
		acc.SummonTickets += tickets
		acc.VipPoints += vipPoints
		acc.VipLevel = ComputeVIPLevel(acc.VipPoints)
		EnsureHeroInstances(acc)
		for k, v := range inventory {
			acc.Inventory[k] += v
		}
		key := "TEST_PURCHASE:" + sku + ":" + day + ":" + strconv.Itoa(acc.TestPurchasesDay)
		acc.ClaimedRewards[key] = true
		meta["transaction_type"] = "TEST_PURCHASE"
		meta["sku"] = sku
		meta["test_purchases_today"] = acc.TestPurchasesDay
		meta["not_real_revenue"] = true
		return nil
	})
	return prog, meta, err
}

func ComputeVIPLevel(points int) int {
	thresholds := []int{0, 100, 300, 600, 1000, 1600, 2400, 3500, 5000, 7000, 10000}
	lvl := 0
	for i, t := range thresholds {
		if points >= t {
			lvl = i
		}
	}
	return lvl
}

func (m *Memory) ClaimVIPDaily(token string, soft, tickets int) (*AccountProgress, bool, error) {
	already := false
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		day := time.Now().UTC().Format("2006-01-02")
		if acc.VipDailyClaimed == day {
			already = true
			return nil
		}
		acc.VipDailyClaimed = day
		acc.SoftCurrency += soft
		acc.SummonTickets += tickets
		return nil
	})
	return prog, already, err
}

func (m *Memory) SkillUpHero(token, heroID, skillID string, base HeroBaseStats, defs map[string]EquipmentDef) (*AccountProgress, *HeroInstance, error) {
	var out *HeroInstance
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		bonus := map[string]int{}
		if inst := acc.HeroInstances[heroID]; inst != nil {
			bonus = GearBonusForHero(inst, defs)
		}
		inst, e := ApplySkillUp(acc, heroID, skillID, base, bonus)
		out = inst
		return e
	})
	return prog, out, err
}

func (m *Memory) EquipHeroUnique(token, heroID, slot, itemID string, base HeroBaseStats, defs map[string]EquipmentDef) (*AccountProgress, *HeroInstance, error) {
	var out *HeroInstance
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		inst, e := ApplyEquipUnique(acc, heroID, slot, itemID, base, defs)
		out = inst
		return e
	})
	return prog, out, err
}

func (m *Memory) StartSidequest(token, questID, requiredMain string) (*AccountProgress, error) {
	return m.mutate(token, func(acc *AccountProgress) error {
		return ApplySidequestStart(acc, questID, requiredMain, func(q string) bool {
			return acc.QuestFlags[q]
		})
	})
}

func (m *Memory) InteractPOI(token, poiID, actionID, stepID, sidequestID string, sequence []string, completionFlag string, oneTime bool) (*AccountProgress, bool, error) {
	reset := false
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		r, e := ApplyPOIInteract(acc, poiID, actionID, stepID, sidequestID, sequence, completionFlag, oneTime)
		reset = r
		return e
	})
	return prog, reset, err
}

func (m *Memory) ClaimSidequest(token, questID string, requiredSteps []string, bundle ExpansionRewardBundle, defs map[string]EquipmentDef, templates map[string]EquipmentTemplate, bal EquipmentBalance) (*AccountProgress, bool, map[string]any, error) {
	already := false
	var granted map[string]any
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		a, g, e := ApplySidequestClaim(acc, questID, requiredSteps, bundle, defs, templates, bal)
		already = a
		granted = g
		return e
	})
	return prog, already, granted, err
}

func (m *Memory) idempotent(acc *AccountProgress, requestID string, action func() (map[string]any, error)) (map[string]any, error) {
	EnsureEquipment(acc)
	if requestID == "" {
		return action()
	}
	if prev, ok := acc.Idempotency[requestID]; ok {
		return prev, nil
	}
	out, err := action()
	if err != nil {
		return nil, err
	}
	acc.Idempotency[requestID] = out
	return out, nil
}

func (m *Memory) EquipInstance(token, instanceID, heroID, slot string, confirmTransfer bool, expectedVersion int, requestID string, base HeroBaseStats, heroClass string, templates map[string]EquipmentTemplate, sets map[string]EquipmentSetDef, bal EquipmentBalance) (*AccountProgress, *EquipmentInstance, map[string]any, error) {
	var outInst *EquipmentInstance
	var extras map[string]any
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		EnsureEquipment(acc)
		MigrateLegacyEquipment(acc, templates, bal.Aliases, bal.InventoryCapacity)
		payload, e := m.idempotent(acc, requestID, func() (map[string]any, error) {
			lvl := 1
			if hi := acc.HeroInstances[heroID]; hi != nil {
				lvl = hi.Level
			}
			eq, err2 := EquipInstance(acc, instanceID, heroID, slot, confirmTransfer, expectedVersion, lvl, heroClass, templates)
			if err2 != nil {
				return nil, err2
			}
			flat, pct, counts := ComputeHeroGearFlat(acc, heroID, templates, sets, bal.UpgradeGrowth)
			if hi := acc.HeroInstances[heroID]; hi != nil {
				hi.Power = ComputePowerWithGear(base, hi, flat)
			}
			outInst = eq
			return map[string]any{"instance": eq, "flat": flat, "set_pct": pct, "set_counts": counts}, nil
		})
		extras = payload
		if payload != nil {
			if inst, ok := payload["instance"].(*EquipmentInstance); ok {
				outInst = inst
			}
		}
		return e
	})
	return prog, outInst, extras, err
}

func (m *Memory) UnequipInstance(token, instanceID string, expectedVersion int, requestID string) (*AccountProgress, *EquipmentInstance, error) {
	var out *EquipmentInstance
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		_, e := m.idempotent(acc, requestID, func() (map[string]any, error) {
			eq, err2 := UnequipInstance(acc, instanceID, expectedVersion)
			if err2 != nil {
				return nil, err2
			}
			out = eq
			return map[string]any{"instance": eq}, nil
		})
		return e
	})
	return prog, out, err
}

func (m *Memory) UpgradeInstance(token, instanceID string, expectedVersion int, requestID string, base HeroBaseStats, templates map[string]EquipmentTemplate, sets map[string]EquipmentSetDef, bal EquipmentBalance) (*AccountProgress, *EquipmentInstance, map[string]any, error) {
	var out *EquipmentInstance
	var extras map[string]any
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		payload, e := m.idempotent(acc, requestID, func() (map[string]any, error) {
			eq, cost, err2 := UpgradeInstance(acc, instanceID, expectedVersion, bal, templates)
			if err2 != nil {
				return nil, err2
			}
			if eq.EquippedHeroID != "" {
				if hi := acc.HeroInstances[eq.EquippedHeroID]; hi != nil {
					flat, _, _ := ComputeHeroGearFlat(acc, eq.EquippedHeroID, templates, sets, bal.UpgradeGrowth)
					hi.Power = ComputePowerWithGear(base, hi, flat)
				}
			}
			out = eq
			return map[string]any{"instance": eq, "cost": cost}, nil
		})
		extras = payload
		return e
	})
	return prog, out, extras, err
}

func (m *Memory) LockInstance(token, instanceID string, locked bool, expectedVersion int, requestID string) (*AccountProgress, *EquipmentInstance, error) {
	var out *EquipmentInstance
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		_, e := m.idempotent(acc, requestID, func() (map[string]any, error) {
			eq, err2 := LockInstance(acc, instanceID, locked, expectedVersion)
			if err2 != nil {
				return nil, err2
			}
			out = eq
			return map[string]any{"instance": eq}, nil
		})
		return e
	})
	return prog, out, err
}

func (m *Memory) SalvageInstance(token, instanceID string, expectedVersion int, requestID string, confirm bool, templates map[string]EquipmentTemplate, bal EquipmentBalance) (*AccountProgress, map[string]any, error) {
	if !confirm {
		return nil, nil, ErrValidation
	}
	var reward map[string]any
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		payload, e := m.idempotent(acc, requestID, func() (map[string]any, error) {
			r, err2 := SalvageInstance(acc, instanceID, expectedVersion, bal, templates)
			if err2 != nil {
				return nil, err2
			}
			return map[string]any{"reward": r}, nil
		})
		if payload != nil {
			if r, ok := payload["reward"].(map[string]any); ok {
				reward = r
			}
		}
		return e
	})
	return prog, reward, err
}

func (m *Memory) GrantEquipmentReward(token, rewardKey, templateID, source string, templates map[string]EquipmentTemplate, bal EquipmentBalance) (*AccountProgress, *EquipmentInstance, error) {
	var out *EquipmentInstance
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		inst, e := GrantEquipmentOnce(acc, rewardKey, templateID, source, templates, bal)
		out = inst
		return e
	})
	return prog, out, err
}

func (m *Memory) MigrateLegacyEquipment(token string, templates map[string]EquipmentTemplate, bal EquipmentBalance) (*AccountProgress, int, error) {
	created := 0
	prog, err := m.mutate(token, func(acc *AccountProgress) error {
		created = MigrateLegacyEquipment(acc, templates, bal.Aliases, bal.InventoryCapacity)
		return nil
	})
	return prog, created, err
}
