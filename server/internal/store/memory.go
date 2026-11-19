package store

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
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
		AFKClaimedUnix: time.Now().Unix(),
		UpdatedAt:      time.Now().UTC().Format(time.RFC3339),
	}
	EnsureHeroInstances(acc)
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
