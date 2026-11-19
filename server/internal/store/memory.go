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
		AccountID:      newID("acc_"),
		CommanderXP:    0,
		SoftCurrency:   0,
		HardCurrency:   0,
		SummonTickets:  10,
		PartyIDs:       []string{"H01", "H04", "H02", "H03", "H07"},
		QuestFlags:     map[string]bool{},
		ClaimedRewards: map[string]bool{},
		OwnedHeroes: map[string]bool{
			"H01": true, "H02": true, "H03": true, "H04": true, "H07": true,
		},
		AFKClaimedUnix: time.Now().Unix(),
		UpdatedAt:      time.Now().UTC().Format(time.RFC3339),
	}
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
		// deterministic-ish pick from pool using time
		idx := int(time.Now().UnixNano() % int64(len(heroPool)))
		heroID = heroPool[idx]
		newly = !acc.OwnedHeroes[heroID]
		acc.OwnedHeroes[heroID] = true
		if !newly {
			acc.SoftCurrency += 50
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
		return nil
	})
	return
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
		return nil
	})
}
